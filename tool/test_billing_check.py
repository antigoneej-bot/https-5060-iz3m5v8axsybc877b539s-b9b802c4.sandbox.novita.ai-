import copy
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock
import urllib.error

SCRIPT = Path(__file__).with_name("Mindnyang-Billing-Check.py")
spec = importlib.util.spec_from_file_location("billing_check", SCRIPT)
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

SA = "private-runtime-identity@example.iam.gserviceaccount.com"
SECRET = "private-access-token-never-print-123456789"


def subscription(product_id):
    _, duration, amount = mod.PRODUCTS[product_id]
    return {"packageName": mod.PACKAGE, "productId": product_id, "basePlans": [{
        "basePlanId": "private-plan-id", "state": "ACTIVE",
        "autoRenewingBasePlanType": {"billingPeriodDuration": duration},
        "regionalConfigs": [{"regionCode": "KR", "newSubscriberAvailability": True,
                             "price": {"currencyCode": "KRW", "units": str(amount)}}],
    }]}


def offers(product_id):
    return {"subscriptionOffers": [{
        "packageName": mod.PACKAGE, "productId": product_id, "basePlanId": "private-plan-id",
        "offerId": "private-offer-id", "state": "ACTIVE",
        "regionalConfigs": [{"regionCode": "KR", "newSubscriberAvailability": True}],
        "phases": [{"duration": "P7D", "recurrenceCount": 1,
                    "regionalConfigs": [{"regionCode": "KR", "free": {}}]}],
    }]}


class FakeCloud:
    def __init__(self):
        self.calls = []
        self.overrides = {}

    def json(self, args, fields):
        self.calls.append((tuple(args), fields))
        key = tuple(args[:3])
        if key in self.overrides:
            return self.overrides[key]
        if args[:2] == ["functions", "describe"]:
            name = args[2]
            return mod.Result({"state": "ACTIVE", "buildConfig": {"entryPoint": name},
                               "serviceConfig": {"serviceAccountEmail": SA},
                               "eventTrigger": {"eventType": "google.cloud.pubsub.topic.v1.messagePublished",
                                                "pubsubTopic": mod.TOPIC}})
        if args[:2] == ["services", "list"]:
            return mod.Result([{"config": {"name": "androidpublisher.googleapis.com"}}])
        if args[:3] == ["pubsub", "topics", "describe"]:
            return mod.Result({"name": mod.TOPIC})
        if args[:3] == ["pubsub", "topics", "get-iam-policy"]:
            return mod.Result({"bindings": [{"role": "roles/pubsub.publisher", "members": [mod.PLAY_MEMBER]}]})
        if args[:2] == ["projects", "get-iam-policy"]:
            return mod.Result({"bindings": []})
        raise AssertionError("Unexpected gcloud operation")

    def raw(self, args):
        self.calls.append((tuple(args), None))
        if args != ["auth", "print-access-token"]:
            raise AssertionError("Unexpected token command")
        return self.overrides.get(tuple(args), mod.Result(SECRET))


class FakeHttp:
    def __init__(self):
        self.calls = []
        self.overrides = {}

    def request(self, method, url, token, body=None):
        self.calls.append((method, url, token, body))
        if method == "POST":
            assert url.endswith("/" + SA + ":generateAccessToken")
            assert body == {"scope": [mod.PLAY_SCOPE], "lifetime": "600s"}
            return self.overrides.get("mint", mod.Result({"accessToken": SECRET + "-scoped"}))
        assert method == "GET"
        for product_id in mod.PRODUCTS:
            if "/" + product_id in url:
                suffix = "offers" if "/offers?" in url else "product"
                return self.overrides.get((product_id, suffix), mod.Result(offers(product_id) if suffix == "offers" else subscription(product_id)))
        raise AssertionError("Unexpected HTTP operation")


class BillingCheckTests(unittest.TestCase):
    def run_check(self, cloud=None, http=None):
        cloud, http = cloud or FakeCloud(), http or FakeHttp()
        lines = []
        mod.run(cloud, http, lines.append)
        output = "\n".join(lines)
        for private in [SA, SECRET, "private-plan-id", "private-offer-id"]:
            self.assertNotIn(private, output)
        return output, cloud, http

    def test_success_is_scoped_read_only_and_does_not_claim_payment_success(self):
        output, cloud, http = self.run_check()
        self.assertIn("[PASS] 월 구독 기본 요금제", output)
        self.assertIn("4,900원", output)
        self.assertIn("29,000원", output)
        self.assertIn("7일", output)
        self.assertIn("[UNKNOWN] 실제 결제·영수증 검증·구매 승인", output)
        self.assertIn("[UNKNOWN] Play Console 알림 전송 설정", output)
        self.assertIn("BILLING_CHECK_DONE", output)
        self.assertEqual([x[0] for x in http.calls], ["POST", "GET", "GET", "GET", "GET"])
        self.assertEqual(len([x for x in cloud.calls if x[0] == ("auth", "print-access-token")]), 1)
        self.assertFalse(any(word in call[0] for call in cloud.calls for word in ["deploy", "enable", "set-iam-policy", "add-iam-policy-binding", "create"]))

    def test_iam_denial_never_tries_other_identity_or_publisher(self):
        http = FakeHttp()
        http.overrides["mint"] = mod.Result(error="HTTP_403")
        output, cloud, http = self.run_check(http=http)
        self.assertIn("[UNKNOWN] 서버 계정으로 상품 조회", output)
        self.assertEqual(len(http.calls), 1)
        self.assertEqual(len([c for c in cloud.calls if c[0][0] == "auth"]), 1)

    def test_publisher_denial_stops_remaining_requests(self):
        http = FakeHttp()
        http.overrides[("garden_plus_monthly", "product")] = mod.Result(error="HTTP_403")
        output, _, http = self.run_check(http=http)
        self.assertIn("접근이 거부돼 상품 조회를 중단", output)
        self.assertEqual(len(http.calls), 2)

    def test_disabled_api_does_not_request_credentials(self):
        cloud = FakeCloud()
        cloud.overrides[("services", "list", "--enabled")] = mod.Result([])
        output, cloud, http = self.run_check(cloud=cloud)
        self.assertIn("[CHECK] Google Play API", output)
        self.assertFalse(http.calls)
        self.assertFalse(any(c[0][0] == "auth" for c in cloud.calls))

    def test_missing_or_unknown_runtime_does_not_impersonate(self):
        cloud = FakeCloud()
        cloud.overrides[("functions", "describe", "gardenApi")] = mod.Result(error="NOT_FOUND")
        output, _, http = self.run_check(cloud=cloud)
        self.assertIn("[UNKNOWN] 결제 서버 실행 계정", output)
        self.assertFalse(http.calls)

    def test_notifications_wrong_topic_and_inherited_publisher(self):
        cloud = FakeCloud()
        cloud.overrides[("functions", "describe", "playNotifications")] = mod.Result({
            "state": "ACTIVE", "buildConfig": {"entryPoint": "playNotifications"},
            "eventTrigger": {"pubsubTopic": "projects/private/topics/wrong"}})
        cloud.overrides[("pubsub", "topics", "get-iam-policy")] = mod.Result({"bindings": []})
        cloud.overrides[("projects", "get-iam-policy", mod.PROJECT)] = mod.Result({
            "bindings": [{"role": "roles/pubsub.publisher", "members": [mod.PLAY_MEMBER]}]})
        output, _, _ = self.run_check(cloud=cloud)
        self.assertIn("[CHECK] 구독 변경 알림 함수", output)
        self.assertIn("프로젝트에서 발행 권한을 상속", output)
        self.assertNotIn("projects/private", output)

    def test_conditional_iam_binding_is_not_reported_as_proven(self):
        policy = {"bindings": [{"role": "roles/pubsub.publisher", "members": [mod.PLAY_MEMBER],
                                "condition": {"expression": "request.time < secret"}}]}
        self.assertFalse(mod.has_publisher_binding(policy))

    def test_inactive_zero_price_and_unavailable_kr_fail_matching(self):
        product = subscription("garden_plus_monthly")
        variants = []
        inactive = copy.deepcopy(product); inactive["basePlans"][0]["state"] = "INACTIVE"; variants.append(inactive)
        price = copy.deepcopy(product); price["basePlans"][0]["regionalConfigs"][0]["price"]["units"] = "0"; variants.append(price)
        hidden = copy.deepcopy(product); hidden["basePlans"][0]["regionalConfigs"][0]["newSubscriberAvailability"] = False; variants.append(hidden)
        period = copy.deepcopy(product); period["basePlans"][0]["autoRenewingBasePlanType"]["billingPeriodDuration"] = "P1Y"; variants.append(period)
        for variant in variants:
            self.assertEqual(mod.matching_base_plans(variant, "garden_plus_monthly"), [])
        self.assertIsNone(mod.matching_base_plans({**product, "packageName": "wrong"}, "garden_plus_monthly"))
        self.assertFalse(mod.money_matches({"currencyCode": "KRW", "units": 4900.5}, 4900))
        self.assertFalse(mod.money_matches({"currencyCode": "KRW", "units": "4900", "nanos": 1}, 4900))

    def test_trial_counts_and_ineligible_regions_are_distinguished(self):
        value = offers("garden_plus_monthly")
        value["subscriptionOffers"][0]["phases"][0]["duration"] = "P1W"
        value["subscriptionOffers"][0]["phases"][0]["recurrenceCount"] = 2
        self.assertEqual(mod.trial_descriptions(value, "garden_plus_monthly", ["private-plan-id"]), ["2주"])
        value["subscriptionOffers"][0]["regionalConfigs"][0]["newSubscriberAvailability"] = False
        self.assertEqual(mod.trial_descriptions(value, "garden_plus_monthly", ["private-plan-id"]), [])

    def test_more_offers_do_not_create_false_complete_result(self):
        http = FakeHttp()
        http.overrides[("garden_plus_monthly", "offers")] = mod.Result({**offers("garden_plus_monthly"), "nextPageToken": "private-page-token"})
        output, _, _ = self.run_check(http=http)
        self.assertIn("TOO_MANY_OFFERS", output)
        self.assertNotIn("private-page-token", output)

    def test_different_trial_lengths_and_intro_steps_are_supported(self):
        seven = offers("garden_plus_monthly")
        fifteen = copy.deepcopy(seven)
        fifteen["subscriptionOffers"][0]["phases"][0]["duration"] = "P15D"
        multiple = copy.deepcopy(fifteen)
        multiple["subscriptionOffers"][0]["phases"].append({
            "duration": "P1M", "recurrenceCount": 1,
            "regionalConfigs": [{"regionCode": "KR", "relativeDiscount": 0.5}]})
        for value, expected in [(seven, "PASS"), (fifteen, "PASS"), (multiple, "PASS")]:
            http = FakeHttp()
            http.overrides[("garden_plus_monthly", "offers")] = mod.Result(value)
            output, _, _ = self.run_check(http=http)
            self.assertIn(f"[{expected}] 월 구독 무료체험 호환", output)
        http = FakeHttp()
        http.overrides[("garden_plus_monthly", "offers")] = mod.Result({"subscriptionOffers": []})
        output, _, _ = self.run_check(http=http)
        self.assertIn("[PASS] 월 구독 무료체험 설정: 한국 신규 가입용 활성 무료체험이 없어요", output)

    def test_annual_actual_price_and_twelve_month_period(self):
        product = subscription("garden_plus_yearly")
        product["basePlans"][0]["autoRenewingBasePlanType"]["billingPeriodDuration"] = "P12M"
        product["basePlans"][0]["regionalConfigs"][0]["price"]["units"] = "55000"
        self.assertEqual(mod.matching_base_plans(product, "garden_plus_yearly"), ["private-plan-id"])
        http = FakeHttp()
        http.overrides[("garden_plus_yearly", "product")] = mod.Result(product)
        output, _, _ = self.run_check(http=http)
        self.assertIn("55,000원", output)
        self.assertIn("[PASS] 연 구독 기본 요금제", output)

    def test_raw_error_details_are_not_printed(self):
        cloud = FakeCloud()
        cloud.overrides[("functions", "describe", "gardenApi")] = mod.Result(error="permission " + SECRET + " " + SA)
        output, _, _ = self.run_check(cloud=cloud)
        self.assertIn("(UNKNOWN)", output)

    def test_gcloud_timeout_and_stderr_are_sanitized(self):
        cloud = mod.GCloud(mod.Budget())
        with mock.patch.object(subprocess, "run", return_value=subprocess.CompletedProcess([], 1, b"", ("PERMISSION_DENIED " + SECRET).encode())) as runner:
            self.assertEqual(cloud.raw(["auth", "print-access-token"]).error, "NO_PERMISSION")
            kwargs = runner.call_args.kwargs
            self.assertLessEqual(kwargs["timeout"], 30)
            self.assertEqual(kwargs["env"]["CLOUDSDK_CORE_DISABLE_FILE_LOGGING"], "true")
            self.assertIs(kwargs["stdin"], subprocess.DEVNULL)
        with mock.patch.object(subprocess, "run", side_effect=subprocess.TimeoutExpired("secret", 30)):
            self.assertEqual(cloud.raw(["auth", "print-access-token"]).error, "TIMEOUT")

    def test_http_allowlist_blocks_settings_writes_and_foreign_hosts(self):
        http = mod.Http(mod.Budget())
        with mock.patch.object(http.opener, "open") as opener:
            invalid = [
                ("DELETE", mod.API_ROOT + "/subscriptions/garden_plus_monthly", None),
                ("POST", mod.API_ROOT + "/purchases/subscriptions/token:refund", {}),
                ("GET", "https://example.invalid/secret", None),
                ("GET", mod.API_ROOT + "/subscriptions/garden_plus_monthly?token=secret", None),
                ("POST", "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/" + SA + ":generateAccessToken", {"scope": [mod.PLAY_SCOPE], "lifetime": "3600s"}),
            ]
            for method, url, body in invalid:
                self.assertEqual(http.request(method, url, SECRET, body).error, "REQUEST_NOT_ALLOWED")
            opener.assert_not_called()

    def test_http_success_and_error_never_surface_token(self):
        http = mod.Http(mod.Budget())
        response = io.BytesIO(json.dumps(subscription("garden_plus_monthly")).encode())
        with mock.patch.object(http.opener, "open", return_value=response) as opener:
            result = http.request("GET", mod.API_ROOT + "/subscriptions/garden_plus_monthly", SECRET)
            self.assertFalse(result.error)
            req = opener.call_args.args[0]
            self.assertEqual(req.get_method(), "GET")
            self.assertIsNone(req.data)
            self.assertEqual(req.get_header("Authorization"), "Bearer " + SECRET)
        error = urllib.error.HTTPError("private-url", 403, SECRET, {}, io.BytesIO(SECRET.encode()))
        with mock.patch.object(http.opener, "open", side_effect=error):
            self.assertEqual(http.request("GET", mod.API_ROOT + "/subscriptions/garden_plus_monthly", SECRET).error, "HTTP_403")

    def test_redirect_refuses_to_forward_credentials(self):
        self.assertIsNone(mod.NoRedirect().redirect_request(None, None, 302, "", {}, "https://example.invalid"))

    def test_budget_expired_fails_without_subprocess(self):
        cloud = mod.GCloud(mod.Budget(seconds=-1))
        with mock.patch.object(subprocess, "run") as runner:
            self.assertEqual(cloud.raw(["auth", "print-access-token"]).error, "TIMEOUT")
            runner.assert_not_called()


if __name__ == "__main__":
    unittest.main()
