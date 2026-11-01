#!/usr/bin/env python3
"""Read-only resource/configuration checks, intended for the owner's Cloud Shell.

No deployment, purchase, refund, IAM change or API enablement is performed.
One short-lived token may be issued for the EXISTING gardenApi runtime identity,
using permissions the Cloud Shell user already has. Tokens stay in memory.
No credential file, raw command/API result or environment value is printed/saved.
Catalog GET access is not proof of receipt-validation or acknowledgement access.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass

PROJECT = "mycatapp-99bc8"
REGION = "asia-northeast3"
PACKAGE = "com.mysticcat.journal"
TOPIC = f"projects/{PROJECT}/topics/play-rtdn"
PLAY_MEMBER = "serviceAccount:google-play-developer-notifications@system.gserviceaccount.com"
PLAY_SCOPE = "https://www.googleapis.com/auth/androidpublisher"
API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" + PACKAGE
PRODUCTS = {
    "garden_plus_monthly": ("월 구독", "P1M", 4900),
    "garden_plus_yearly": ("연 구독", "P1Y", 29000),
}
MAX_BODY = 2 * 1024 * 1024


@dataclass
class Result:
    value: object = None
    error: str = ""


class Budget:
    def __init__(self, seconds=240):
        self.end = time.monotonic() + seconds

    def timeout(self, maximum):
        remaining = self.end - time.monotonic()
        if remaining <= 0:
            raise TimeoutError()
        return min(maximum, remaining)


class GCloud:
    def __init__(self, budget):
        self.budget = budget

    def raw(self, args):
        env = os.environ.copy()
        env.update({"CLOUDSDK_CORE_DISABLE_PROMPTS": "1",
                    "CLOUDSDK_CORE_DISABLE_FILE_LOGGING": "true",
                    "CLOUDSDK_CORE_LOG_HTTP": "false"})
        try:
            result = subprocess.run(
                ["gcloud", *args, "--project=" + PROJECT, "--quiet", "--verbosity=error"],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                timeout=self.budget.timeout(30), env=env, check=False,
            )
        except FileNotFoundError:
            return Result(error="NO_GCLOUD")
        except (subprocess.TimeoutExpired, TimeoutError):
            return Result(error="TIMEOUT")
        except OSError:
            return Result(error="COMMAND_FAILED")
        if result.returncode:
            # Classification only. The error can contain private identifiers.
            raw_error = result.stderr.decode("utf-8", "replace")
            if re.search(r"PERMISSION_DENIED|UNAUTHENTICATED|status=\[40[13]\]", raw_error):
                return Result(error="NO_PERMISSION")
            if re.search(r"NOT_FOUND|status=\[404\]|not found", raw_error, re.I):
                return Result(error="NOT_FOUND")
            return Result(error="COMMAND_FAILED")
        if len(result.stdout) > MAX_BODY:
            return Result(error="RESPONSE_TOO_LARGE")
        return Result(value=result.stdout.decode("utf-8", "replace").strip())

    def json(self, args, fields):
        result = self.raw([*args, "--format=json(" + fields + ")"])
        if result.error:
            return result
        try:
            return Result(value=json.loads(result.value))
        except (TypeError, ValueError):
            return Result(error="INVALID_RESPONSE")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward an authorization header to a redirect destination.
        return None


class Http:
    def __init__(self, budget):
        self.budget = budget
        self.opener = urllib.request.build_opener(NoRedirect())

    def request(self, method, url, token, body=None):
        parsed = urllib.parse.urlparse(url)
        mint = (method == "POST" and parsed.scheme == "https" and
                parsed.netloc == "iamcredentials.googleapis.com" and
                re.fullmatch(r"/v1/projects/-/serviceAccounts/[A-Za-z0-9@._%+-]+:generateAccessToken", parsed.path) and
                not parsed.query and body == {"scope": [PLAY_SCOPE], "lifetime": "600s"})
        catalog = (method == "GET" and url.startswith(API_ROOT + "/subscriptions/") and
                   re.fullmatch(r"/androidpublisher/v3/applications/com\.mysticcat\.journal/subscriptions/"
                                r"garden_plus_(monthly|yearly)(/basePlans/-/offers)?", parsed.path) and
                   set(urllib.parse.parse_qs(parsed.query)) <= {"pageSize"} and
                   parsed.netloc == "androidpublisher.googleapis.com" and body is None)
        if not (mint or catalog) or parsed.fragment or parsed.username or parsed.password:
            return Result(error="REQUEST_NOT_ALLOWED")
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = urllib.request.Request(url, data=data, method=method,
                                     headers={"Authorization": "Bearer " + token,
                                              "Accept": "application/json",
                                              "Content-Type": "application/json"})
        try:
            with self.opener.open(req, timeout=self.budget.timeout(20)) as response:
                raw = response.read(MAX_BODY + 1)
                if len(raw) > MAX_BODY:
                    return Result(error="RESPONSE_TOO_LARGE")
                value = json.loads(raw)
                if not isinstance(value, dict):
                    return Result(error="INVALID_RESPONSE")
                return Result(value=value)
        except urllib.error.HTTPError as error:
            # Deliberately do not read/print the response body or exception text.
            return Result(error="HTTP_" + str(error.code))
        except (urllib.error.URLError, TimeoutError, OSError):
            return Result(error="NETWORK_OR_TIMEOUT")
        except (ValueError, TypeError):
            return Result(error="INVALID_RESPONSE")


def report(emit, status, title, detail):
    emit(f"[{status}] {title}: {detail}")


def unknown(emit, title, result):
    # Only internal enum values/numeric HTTP statuses are shown, never raw errors.
    code = result.error
    if not re.fullmatch(r"(?:[A-Z_]{1,32}|HTTP_[0-9]{3})", code or ""):
        code = "UNKNOWN"
    report(emit, "UNKNOWN", title, f"조회하지 못했어요 ({code}). 권한·연결 확인이 필요해요.")


def function_details(cloud, name):
    return cloud.json(["functions", "describe", name, "--gen2", "--region=" + REGION],
                      "state,buildConfig.entryPoint,serviceConfig.serviceAccountEmail,eventTrigger")


def has_publisher_binding(policy):
    if not isinstance(policy, dict) or not isinstance(policy.get("bindings", []), list):
        return False
    for binding in policy.get("bindings", []):
        if not isinstance(binding, dict) or binding.get("condition"):
            continue
        if binding.get("role") in {"roles/pubsub.publisher", "roles/pubsub.admin", "roles/owner", "roles/editor"}:
            if PLAY_MEMBER in binding.get("members", []):
                return True
    return False


def check_notifications(cloud, emit):
    result = function_details(cloud, "playNotifications")
    if result.error:
        unknown(emit, "구독 변경 알림 함수", result)
    else:
        value = result.value if isinstance(result.value, dict) else {}
        trigger = value.get("eventTrigger") or {}
        good = (value.get("state") == "ACTIVE" and
                (value.get("buildConfig") or {}).get("entryPoint") == "playNotifications" and
                trigger.get("eventType") == "google.cloud.pubsub.topic.v1.messagePublished" and
                trigger.get("pubsubTopic") == TOPIC)
        report(emit, "PASS" if good else "CHECK", "구독 변경 알림 함수",
               "활성 함수가 지정된 알림 주제에 연결돼 있어요." if good else
               "함수 활성 상태·알림 주제 연결을 확인해야 해요.")
    topic = cloud.json(["pubsub", "topics", "describe", "play-rtdn"], "name")
    if topic.error:
        unknown(emit, "알림 주제", topic)
        return
    if not isinstance(topic.value, dict) or topic.value.get("name") != TOPIC:
        report(emit, "CHECK", "알림 주제", "지정된 알림 주제를 확인하지 못했어요.")
        return
    report(emit, "PASS", "알림 주제", "play-rtdn이 있어요.")
    policy = cloud.json(["pubsub", "topics", "get-iam-policy", "play-rtdn"], "bindings")
    if policy.error:
        unknown(emit, "Google Play 알림 발행 권한", policy)
        return
    if has_publisher_binding(policy.value):
        report(emit, "PASS", "Google Play 알림 발행 권한", "주제에 발행 권한이 등록돼 있어요.")
        return
    # Standard publisher roles can also be inherited from the project.
    project_policy = cloud.json(["projects", "get-iam-policy", PROJECT], "bindings")
    if project_policy.error:
        unknown(emit, "Google Play 알림 발행 권한", project_policy)
    elif has_publisher_binding(project_policy.value):
        report(emit, "PASS", "Google Play 알림 발행 권한", "프로젝트에서 발행 권한을 상속해요.")
    else:
        report(emit, "CHECK", "Google Play 알림 발행 권한",
               "주제·프로젝트에서 일반 발행 권한을 찾지 못했어요. 조건부·상위 조직·맞춤 권한은 별도 확인이 필요해요.")


def korean_region(regions):
    if not isinstance(regions, list):
        return {}
    return next((r for r in regions if isinstance(r, dict) and r.get("regionCode") == "KR"), {})


def money_matches(value, amount):
    if not isinstance(value, dict) or value.get("currencyCode") != "KRW":
        return False
    units, nanos = value.get("units", 0), value.get("nanos", 0)
    if (isinstance(units, bool) or not isinstance(units, (str, int)) or
            not re.fullmatch(r"-?[0-9]{1,16}", str(units)) or
            isinstance(nanos, bool) or not isinstance(nanos, int)):
        return False
    try:
        return int(units) == amount and nanos == 0
    except (TypeError, ValueError, OverflowError):
        return False


def positive_krw_price(value):
    if not isinstance(value, dict) or value.get("currencyCode") != "KRW":
        return False
    units, nanos = value.get("units", 0), value.get("nanos", 0)
    return (not isinstance(units, bool) and isinstance(units, (str, int)) and
            re.fullmatch(r"[0-9]{1,16}", str(units)) is not None and
            not isinstance(nanos, bool) and isinstance(nanos, int) and
            0 <= nanos < 1000000000 and (int(units) > 0 or nanos > 0))


def matching_base_plans(value, product_id):
    _, duration, amount = PRODUCTS[product_id]
    if value.get("packageName") != PACKAGE or value.get("productId") != product_id:
        return None
    plans = value.get("basePlans", [])
    if not isinstance(plans, list):
        return None
    matches = []
    for plan in plans:
        if not isinstance(plan, dict):
            continue
        region = korean_region(plan.get("regionalConfigs"))
        if (plan.get("state") == "ACTIVE" and region.get("newSubscriberAvailability") is True and
                (plan.get("autoRenewingBasePlanType") or {}).get("billingPeriodDuration") in ({"P1Y", "P12M"} if duration == "P1Y" else {duration}) and
                positive_krw_price(region.get("price")) and
                isinstance(plan.get("basePlanId"), str)):
            matches.append(plan["basePlanId"])
    return matches


def trial_descriptions(value, product_id, plan_ids):
    offers = value.get("subscriptionOffers", [])
    if not isinstance(offers, list):
        return None
    trials = set()
    for offer in offers:
        if not isinstance(offer, dict) or offer.get("state") != "ACTIVE":
            continue
        if (offer.get("packageName") != PACKAGE or offer.get("productId") != product_id or
                offer.get("basePlanId") not in plan_ids or
                korean_region(offer.get("regionalConfigs")).get("newSubscriberAvailability") is not True):
            continue
        phases = offer.get("phases", [])
        if not isinstance(phases, list):
            return None
        free_phases = []
        for phase in phases:
            if not isinstance(phase, dict):
                return None
            if "free" not in korean_region(phase.get("regionalConfigs")):
                continue
            duration, count = phase.get("duration"), phase.get("recurrenceCount")
            if (not isinstance(duration, str) or
                    not re.fullmatch(r"P[1-9][0-9]{0,3}[DWMY]", duration) or
                    not isinstance(count, int) or isinstance(count, bool) or not 1 <= count <= 1000):
                return None
            unit = {"D": "일", "W": "주", "M": "개월", "Y": "년"}[duration[-1]]
            free_phases.append(f"{int(duration[1:-1]) * count}{unit}")
        if free_phases:
            trials.add(" + ".join(free_phases))
    return sorted(trials)


def trial_compatibility(value, product_id, plan_ids):
    """The app displays eligible finite offer phases and actual recurring price."""
    compatible, other = 0, 0
    for offer in value.get("subscriptionOffers", []):
        if (not isinstance(offer, dict) or offer.get("state") != "ACTIVE" or
                offer.get("packageName") != PACKAGE or offer.get("productId") != product_id or
                offer.get("basePlanId") not in plan_ids or
                korean_region(offer.get("regionalConfigs")).get("newSubscriberAvailability") is not True):
            continue
        phases = offer.get("phases", [])
        if not any("free" in korean_region(phase.get("regionalConfigs")) for phase in phases):
            continue
        if phases and all(isinstance(p, dict) and
                re.fullmatch(r"P[1-9][0-9]*[DWMY]", str(p.get("duration", ""))) and
                isinstance(p.get("recurrenceCount"), int) and
                not isinstance(p.get("recurrenceCount"), bool) and
                p["recurrenceCount"] > 0 for p in phases):
            compatible += 1
        else:
            other += 1
    return compatible, other


def check_catalog(cloud, http, runtime_sa, emit):
    if not isinstance(runtime_sa, str) or not re.fullmatch(r"[A-Za-z0-9._+-]+@[A-Za-z0-9.-]+\.gserviceaccount\.com", runtime_sa):
        report(emit, "UNKNOWN", "구독 상품 조회", "현재 서버 실행 계정을 확인하지 못해 조회를 건너뛰었어요.")
        return
    access = cloud.raw(["auth", "print-access-token"])
    if access.error:
        unknown(emit, "구독 상품 조회 인증", access)
        return
    # Exactly one explicit impersonation attempt. No fallback identities or key files.
    url = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/" + urllib.parse.quote(runtime_sa, safe="@.") + ":generateAccessToken"
    minted = http.request("POST", url, access.value, {"scope": [PLAY_SCOPE], "lifetime": "600s"})
    access.value = None
    if minted.error:
        unknown(emit, "서버 계정으로 상품 조회", minted)
        report(emit, "UNKNOWN", "월·연 구독 상품", "기존 권한으로 확인하지 못했어요. 다른 계정으로 재시도하지 않았어요.")
        return
    token = (minted.value or {}).get("accessToken")
    minted.value = None
    if not isinstance(token, str) or not token:
        unknown(emit, "서버 계정으로 상품 조회", Result(error="INVALID_RESPONSE"))
        return
    for product_id, (label, _, amount) in PRODUCTS.items():
        result = http.request("GET", API_ROOT + "/subscriptions/" + product_id, token)
        if result.error:
            unknown(emit, label + " 상품", result)
            if result.error in {"HTTP_401", "HTTP_403"}:
                report(emit, "UNKNOWN", "나머지 구독 상품 조회", "접근이 거부돼 상품 조회를 중단했어요.")
                break
            continue
        matches = matching_base_plans(result.value, product_id)
        if matches is None:
            unknown(emit, label + " 상품", Result(error="INVALID_RESPONSE"))
            continue
        report(emit, "PASS", label + " 상품 등록", "현재 서버 계정으로 상품을 읽었어요.")
        report(emit, "PASS" if matches else "CHECK", label + " 기본 요금제",
               "한국 신규 가입·자동갱신·결제 주기 조건에 맞는 활성 요금제가 " + ("있어요." if matches else "없어요."))
        if not matches:
            continue
        for plan in result.value.get("basePlans", []):
            if plan.get("basePlanId") in matches:
                price = korean_region(plan.get("regionalConfigs")).get("price", {})
                units, nanos = int(price.get("units", 0)), price.get("nanos", 0)
                actual = f"{units:,}" + (f".{nanos:09d}".rstrip('0') if nanos else "")
                emit(f"  현재 한국 기본 가격: {actual}원 · 앱은 스토어에서 받은 실제 가격을 표시해요.")
        offers = http.request("GET", API_ROOT + "/subscriptions/" + product_id + "/basePlans/-/offers?pageSize=1000", token)
        if offers.error:
            unknown(emit, label + " 무료체험", offers)
            if offers.error in {"HTTP_401", "HTTP_403"}:
                report(emit, "UNKNOWN", "나머지 구독 상품 조회", "접근이 거부돼 상품 조회를 중단했어요.")
                break
            continue
        if offers.value.get("nextPageToken"):
            unknown(emit, label + " 무료체험", Result(error="TOO_MANY_OFFERS"))
            continue
        trials = trial_descriptions(offers.value, product_id, matches)
        if trials is None:
            unknown(emit, label + " 무료체험", Result(error="INVALID_RESPONSE"))
        elif trials:
            compatible, other = trial_compatibility(offers.value, product_id, matches)
            status = "CHECK" if other or not compatible else "PASS"
            report(emit, status, label + " 무료체험 호환",
                   "설정된 기간: " + ", ".join(trials) + f". 앱에서 표시할 수 있는 기간 구조 {compatible}개, 추가 확인 {other}개.")
            if other:
                emit("  일부 체험 단계의 기간·반복 횟수를 해석하지 못했어요. 기기에서 조회되는 최종 조건을 확인해 주세요.")
        else:
            report(emit, "PASS", label + " 무료체험 설정", "한국 신규 가입용 활성 무료체험이 없어요. 일반 자동갱신 구독에는 문제가 없어요.")
    token = None


def run(cloud, http, emit=print):
    emit("마음냥 결제 설정 확인 — 프로젝트·Play 설정을 변경하지 않습니다.")
    emit("기존 권한으로만 조회하며, 서버 계정의 10분짜리 조회용 인증을 한 번 시도합니다.")
    emit("PASS=확인됨 / CHECK=설정 검토 / UNKNOWN=조회 미확인")
    runtime = function_details(cloud, "gardenApi")
    runtime_sa = None
    if runtime.error:
        unknown(emit, "결제 서버 실행 계정", runtime)
    else:
        value = runtime.value if isinstance(runtime.value, dict) else {}
        runtime_sa = (value.get("serviceConfig") or {}).get("serviceAccountEmail")
        good = value.get("state") == "ACTIVE" and (value.get("buildConfig") or {}).get("entryPoint") == "gardenApi" and bool(runtime_sa)
        report(emit, "PASS" if good else "CHECK", "결제 서버 실행 계정",
               "활성 서버의 실행 계정을 확인했어요." if good else "서버 활성 상태와 실행 계정을 확인해야 해요.")
        if not good:
            runtime_sa = None
    enabled = cloud.json(["services", "list", "--enabled", "--filter=config.name:androidpublisher.googleapis.com"], "config.name")
    api_enabled = None
    if enabled.error:
        unknown(emit, "Google Play API", enabled)
    elif not isinstance(enabled.value, list):
        unknown(emit, "Google Play API", Result(error="INVALID_RESPONSE"))
    else:
        api_enabled = any(isinstance(row, dict) and (row.get("config") or {}).get("name") == "androidpublisher.googleapis.com" for row in enabled.value)
        report(emit, "PASS" if api_enabled else "CHECK", "Google Play API", "사용 설정돼 있어요." if api_enabled else "현재 프로젝트에서 사용 설정을 찾지 못했어요.")
    check_notifications(cloud, emit)
    if api_enabled is False:
        report(emit, "UNKNOWN", "월·연 구독 상품", "Play API가 꺼져 있어 상품 조회를 건너뛰었어요.")
    else:
        check_catalog(cloud, http, runtime_sa, emit)
    report(emit, "UNKNOWN", "실제 결제·영수증 검증·구매 승인", "상품 조회와는 다른 권한·동작이므로 Play 테스트 결제로 확인해야 해요.")
    report(emit, "UNKNOWN", "Play Console 알림 전송 설정", "콘솔의 알림 연결과 테스트 메시지 수신은 별도 확인이 필요해요.")
    emit("BILLING_CHECK_DONE — 위 PASS/CHECK/UNKNOWN 결과만 보내주세요. 결제 준비 완료 표시는 아닙니다.")


def main():
    budget = Budget()
    try:
        run(GCloud(budget), Http(budget))
    except KeyboardInterrupt:
        print("[UNKNOWN] 확인 중단: 설정은 변경하지 않았어요.")
        return 130
    except Exception:
        # No exception text or traceback: third-party errors can contain secrets.
        print("[UNKNOWN] 확인 중단: 응답을 안전하게 해석하지 못했어요. 설정은 변경하지 않았어요.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
