import { isAdminEmail } from './policy.js';

// Only pass the identity returned by Firebase Admin verifyIdToken. This helper
// never reads request fields, provider profile data, or Firestore user documents.
// The claim is scoped to news management; it does not grant paid entitlements.
export function isGardenNewsAdmin(identity) {
  const provider = identity?.firebase?.sign_in_provider;
  if (typeof identity?.uid !== 'string' || !identity.uid ||
      typeof provider !== 'string' || !provider || provider === 'anonymous') {
    return false;
  }
  return identity.garden_news_admin === true ||
    (identity.email_verified === true && isAdminEmail(identity.email));
}
