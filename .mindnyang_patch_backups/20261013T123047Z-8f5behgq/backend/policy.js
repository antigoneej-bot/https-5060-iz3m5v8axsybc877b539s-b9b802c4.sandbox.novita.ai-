import { FLOWERS } from './garden-gifts.js';
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

// 제어문자를 지우고 앞뒤 공백을 trim한 뒤 maxLen으로 자른다. 결과가
// 비어있으면 null(= "값 없음")을 돌려준다. 공개정원 닉네임, 정원소식의
// 제목/본문 등 "운영자/사용자가 직접 입력한 짧은 텍스트"를 다루는 모든
// 곳에서 공유하는 기본 정리 함수다.
function sanitizeText(raw, maxLen) {
  if (typeof raw !== 'string') return null;
  // eslint-disable-next-line no-control-regex
  const cleaned = raw.replace(/[\u0000-\u001f\u007f]/g, '').trim();
  if (!cleaned) return null;
  return cleaned.slice(0, maxLen);
}

// 공개정원 닉네임: 과도하게 길거나 제어문자가 섞인 입력을 정리한다.
// 비어있으면 null을 돌려주고, 클라이언트/화면에서 "이름 없는 정원사" 같은
// 기본 표시 문구를 쓰도록 맡긴다(서버가 가짜 이름을 만들어주지 않는다).
export function sanitizeNickname(raw) {
  return sanitizeText(raw, 20);
}

// 공개정원 스냅샷 검증: 알려진 씨앗/장식 id만 허용하고, 값 범위를 제한해
// 비정상적으로 큰 숫자나 미지의 id가 공개 화면에 노출되지 않게 막는다.
// "지금 심어진 정원 모습"만 보여줄 뿐 일기/기록 내용은 애초에 이 함수가
// 다루는 필드에 포함되지 않는다(스키마 자체에 그런 필드가 없음).
export function validatePublicSnapshot(value) {
  if (!value || typeof value !== 'object') return false;
  if (Array.isArray(value) || Object.keys(value).some(k => !['seedCounts','equippedDecorationIds','treeStageIndex','layout','memoryTreeStage','hasCheerFlowers','flowerKinds'].includes(k))) return false;
  const { seedCounts, equippedDecorationIds, treeStageIndex } = value;
  if (!seedCounts || typeof seedCounts !== 'object' || Array.isArray(seedCounts)) return false;
  for (const [id, count] of Object.entries(seedCounts)) {
    if (!KNOWN_SEED_IDS.has(id)) return false;
    if (!Number.isInteger(count) || count < 0 || count > 9999) return false;
  }
  if (!Array.isArray(equippedDecorationIds) || equippedDecorationIds.length > 20) return false;
  if (!equippedDecorationIds.every(id => typeof id === 'string' && KNOWN_DECORATION_IDS.has(id))) return false;
  if (!Number.isInteger(treeStageIndex) || treeStageIndex < -1 || treeStageIndex > 3) return false;
  if (value.memoryTreeStage !== undefined && (!Number.isInteger(value.memoryTreeStage) || value.memoryTreeStage < 0 || value.memoryTreeStage > 4)) return false;
  if (value.flowerKinds !== undefined && (!Array.isArray(value.flowerKinds) || value.flowerKinds.length > 5 || !value.flowerKinds.every(f => FLOWERS.includes(f)))) return false;
  if (value.hasCheerFlowers !== undefined && typeof value.hasCheerFlowers !== 'boolean') return false;
  if (value.layout != null && !validatePublicLayout(value.layout)) return false;
  return true;
}
export function validatePublicLayout(layout) {
  if (!layout || typeof layout !== 'object' || Array.isArray(layout) ||
      Object.keys(layout).some(k => !['version','spaces','positions'].includes(k)) ||
      layout.version !== 1 || !Number.isInteger(layout.spaces) || layout.spaces < 1 || layout.spaces > 3) return false;
  const positions = layout.positions;
  if (!positions || typeof positions !== 'object' || Array.isArray(positions)) return false;
  const ids = new Set([...KNOWN_SEED_IDS].map(id => `seed:${id}`).concat([...KNOWN_DECORATION_IDS].map(id => `decor:${id}`)));
  if (Object.keys(positions).length > ids.size) return false;
  return Object.entries(positions).every(([id, point]) => {
    if (!ids.has(id) || !Array.isArray(point) || point.length !== 2 || !point.every(Number.isFinite)) return false;
    const [x,y] = point;
    const zone = x < 1/3 ? 0 : x > 2/3 ? 2 : 1;
    return x >= .035 && x <= .965 && y >= .52 && y <= .91 &&
      (zone === 1 || (zone === 0 && layout.spaces >= 2) || layout.spaces >= 3);
  });
}
// ── 정원소식(= 기존 "공지") 관리자 CRUD + 경량 예약 ────────────────────
// 작성/수정/삭제는 이 이메일 목록에 있는, 이메일 인증을 마친 계정만 할 수
// 있다. 반드시 lib/services/subscription_service.dart의 adminEmails와
// 동일한 목록을 유지해야 한다(한쪽만 바꾸면 "앱에서는 관리자 메뉴가 보이는데
// 서버가 거부" 또는 그 반대 상황이 생긴다).
export const ADMIN_EMAILS = new Set(['antigone.ej@gmail.com']);
export function isAdminEmail(email) {
  return typeof email === 'string' && ADMIN_EMAILS.has(email.toLowerCase());
}

export const GARDEN_NEWS_TYPES = new Set(['info', 'update', 'event']);
export const GARDEN_NEWS_STATUSES = new Set(['recruiting', 'ongoing', 'closed']);

// 정원소식 작성/수정 입력값을 검증하고 정리한다. 유효하지 않으면 null을
// 돌려준다(가짜/비정상 데이터가 Firestore에 쌓이는 것을 막는다).
//
// capacity가 숫자면 "앱 안에서 선착순 예약을 받는" 소식이 되고, null이면
// 예약 기능 없이(기존 공지처럼) 안내만 하는 소식이다. applyUrl은 과거처럼
// 외부 신청폼을 함께 걸어두고 싶을 때만 쓰는 선택 필드로 남겨둔다.
export function validateGardenNewsInput(value) {
  if (!value || typeof value !== 'object') return null;
  const title = sanitizeText(value.title, 80);
  const body = sanitizeText(value.body, 4000);
  if (!title || !body) return null;
  const emoji = sanitizeText(value.emoji, 8) ?? '📌';
  const type = GARDEN_NEWS_TYPES.has(value.type) ? value.type : 'info';
  const status = value.status == null
    ? null
    : (GARDEN_NEWS_STATUSES.has(value.status) ? value.status : undefined);
  if (status === undefined) return null; // explicit invalid status string
  const period = sanitizeText(value.period, 60);
  const location = sanitizeText(value.location, 60);
  const cost = sanitizeText(value.cost, 60);
  const applyUrlRaw = sanitizeText(value.applyUrl, 300);
  if (applyUrlRaw && !/^https:\/\//.test(applyUrlRaw)) return null;
  let capacity = null;
  if (value.capacity !== null && value.capacity !== undefined) {
    if (!Number.isInteger(value.capacity) || value.capacity < 0 || value.capacity > 100000) return null;
    capacity = value.capacity;
  }
  return {title, body, emoji, type, status, period, location, cost, applyUrl: applyUrlRaw, capacity};
}

// 예약 신청 시 함께 남기는 한줄 메모. 이름/연락처 등 민감정보는 처음부터
// 받지 않는다 - 신원 확인은 로그인 계정의 인증된 이메일로 충분하다.
export function sanitizeReservationNote(raw) {
  return sanitizeText(raw, 200);
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
