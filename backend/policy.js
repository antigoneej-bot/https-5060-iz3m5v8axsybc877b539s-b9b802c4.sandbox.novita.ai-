import { createHash } from 'node:crypto';
export const PACKAGE = 'com.mysticcat.journal';
export const PRODUCTS = new Set(['garden_plus_monthly', 'garden_plus_yearly']);
export const accountHash = uid => createHash('sha256').update(uid).digest('hex');
export const tokenHash = token => createHash('sha256').update(token).digest('hex');
export function entitlement(purchase, now = Date.now()) {
  const allowed = new Set(['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'SUBSCRIPTION_STATE_CANCELED']);
  const items = (purchase.lineItems ?? []).filter(item => PRODUCTS.has(item.productId) && Number.isFinite(Date.parse(item.expiryTime)));
  items.sort((a,b) => Date.parse(b.expiryTime) - Date.parse(a.expiryTime));
  const item = items.find(item => Date.parse(item.expiryTime) > now);
  return {active: allowed.has(purchase.subscriptionState) && !!item,
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
