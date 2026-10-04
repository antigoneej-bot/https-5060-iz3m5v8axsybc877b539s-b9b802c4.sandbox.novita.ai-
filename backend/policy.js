import { createHash } from 'node:crypto';
export const PACKAGE = 'com.mysticcat.journal';
export const PRODUCTS = new Set(['garden_plus_monthly', 'garden_plus_yearly']);
export const accountHash = uid => createHash('sha256').update(uid).digest('hex');
export const tokenHash = token => createHash('sha256').update(token).digest('hex');

// ── 3단계: 공개정원 / 응원 (opt-in, read-only visits, no ranking) ──────
// 이 id 목록은 Flutter 쪽 모델과 반드시 동기화되어야 한다:
//   lib/mongi/models/seed.dart (SeedType.all의 id)
//   lib/mongi/models/garden_decoration.dart (GardenDecoration.all의 id)
// 클라이언트가 보내는 공개 스냅샷이 여기 없는 id를 포함하면 거부한다 -
// 임의의 문자열(욕설/스팸 등)이 공개 화면에 그대로 노출되는 것을 막는다.
export const KNOWN_SEED_IDS = new Set(['pine', 'cherry', 'maple', 'forgiveness', 'love', 'peace']);
export const KNOWN_DECORATION_IDS = new Set([
  'bench', 'path', 'fountain', 'lantern', 'rainbow_fence', 'star_light',
  'wind_chime', 'butterfly_garden', 'gazebo', 'lotus_pond', 'jangdokdae',
  'ginkgo_path', 'hanok_lantern',
]);

// 응원을 보낼 때 고를 수 있는 큐레이션된 문구 개수. 실제 문구는 Flutter
// 쪽 app_localizations*.dart의 publicCheerOption0~5 키로 다국어 관리된다 -
// 서버는 인덱스 범위만 검증하고 문구 내용 자체는 모른다(신뢰 최소화).
export const PUBLIC_CHEER_MESSAGE_COUNT = 6;

// 응원에 함께 보낼 수 있는 "빛의 정수" 선물의 최대치. 낮게 고정해 답례를
// 유도하거나 포인트를 불리는 수단이 되지 않도록 한다.
export const MAX_CHEER_GIFT_LIGHT_ESSENCE = 5;

// 공개정원 닉네임: 과도하게 길거나 제어문자가 섞인 입력을 정리한다.
// 비어있으면 null을 돌려주고, 클라이언트/화면에서 "이름 없는 정원사" 같은
// 기본 표시 문구를 쓰도록 맡긴다(서버가 가짜 이름을 만들어주지 않는다).
export function sanitizeNickname(raw) {
  if (typeof raw !== 'string') return null;
  // eslint-disable-next-line no-control-regex
  const cleaned = raw.replace(/[\u0000-\u001f\u007f]/g, '').trim();
  if (!cleaned) return null;
  return cleaned.slice(0, 20);
}

// 공개정원 스냅샷 검증: 알려진 씨앗/장식 id만 허용하고, 값 범위를 제한해
// 비정상적으로 큰 숫자나 미지의 id가 공개 화면에 노출되지 않게 막는다.
// "지금 심어진 정원 모습"만 보여줄 뿐 일기/기록 내용은 애초에 이 함수가
// 다루는 필드에 포함되지 않는다(스키마 자체에 그런 필드가 없음).
export function validatePublicSnapshot(value) {
  if (!value || typeof value !== 'object') return false;
  const { seedCounts, equippedDecorationIds, treeStageIndex } = value;
  if (!seedCounts || typeof seedCounts !== 'object' || Array.isArray(seedCounts)) return false;
  for (const [id, count] of Object.entries(seedCounts)) {
    if (!KNOWN_SEED_IDS.has(id)) return false;
    if (!Number.isInteger(count) || count < 0 || count > 9999) return false;
  }
  if (!Array.isArray(equippedDecorationIds) || equippedDecorationIds.length > 20) return false;
  if (!equippedDecorationIds.every(id => typeof id === 'string' && KNOWN_DECORATION_IDS.has(id))) return false;
  if (!Number.isInteger(treeStageIndex) || treeStageIndex < -1 || treeStageIndex > 3) return false;
  return true;
}
export function entitlement(purchase, now = Date.now()) {
  const allowed = new Set(['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'SUBSCRIPTION_STATE_CANCELED']);
  const items = (purchase.lineItems ?? []).filter(item => PRODUCTS.has(item.productId) && Number.isFinite(Date.parse(item.expiryTime)));
  items.sort((a,b) => Date.parse(b.expiryTime) - Date.parse(a.expiryTime));
  const item = items.find(item => Date.parse(item.expiryTime) > now);
  const active = allowed.has(purchase.subscriptionState) && !!item;
  const trial = !!item?.offerPhase && Object.hasOwn(item.offerPhase, 'freeTrial');
  const canceled = purchase.subscriptionState === 'SUBSCRIPTION_STATE_CANCELED' || item?.autoRenewingPlan?.autoRenewEnabled === false;
  const state = !active ? (items.length ? 'expired' : 'free')
    : canceled ? 'cancelScheduled' : trial ? 'trial' : 'active';
  return {active, state, isTrial: active && trial,
    autoRenewEnabled: item?.autoRenewingPlan?.autoRenewEnabled ?? null,
    productId: item?.productId ?? null, expiresAt: item?.expiryTime ?? null,
    checkedAt: new Date(now).toISOString()};
}
export function assertOwner(purchase, uid, existingOwner) {
  if (existingOwner && existingOwner !== uid) throw new Error('purchase-owner-mismatch');
  const obfuscated = purchase.externalAccountIdentifiers?.obfuscatedExternalAccountId;
  // Legacy purchases lacking an account binding require a verified migration.
  if (!existingOwner && obfuscated !== accountHash(uid)) throw new Error('purchase-migration-required');
  if (obfuscated && obfuscated !== accountHash(uid)) throw new Error('purchase-owner-mismatch');
}
export function validEnvelope(value) {
  if (!value || typeof value !== 'object' || value.format !== 'maeumnyang-backup' || value.version !== 1) return false;
  if (Object.keys(value).sort().join(',') !== 'ciphertext,format,mac,nonce,salt,version') return false;
  const valid = (key, size) => typeof value[key] === 'string' && /^[A-Za-z0-9+/]*={0,2}$/.test(value[key]) &&
    Buffer.from(value[key], 'base64').length === size;
  return valid('salt',16) && valid('nonce',12) && valid('mac',16) &&
    typeof value.ciphertext === 'string' && value.ciphertext.length > 0 &&
    value.ciphertext.length <= 6 * 1024 * 1024 && /^[A-Za-z0-9+/]*={0,2}$/.test(value.ciphertext);
}

// Shared by API and RTDN. Function timeout is 60s; lease outlives it.
export function nextAccountLease(previous = {}, action, owner, now = Date.now()) {
  if ((previous.deleting || previous.deleted) && action !== 'deleteCloudAccount') {
    throw new Error('account-deleting');
  }
  if (previous.owner && previous.until > now) throw new Error('account-busy');
  return {...previous, owner, until: now + 120000};
}
