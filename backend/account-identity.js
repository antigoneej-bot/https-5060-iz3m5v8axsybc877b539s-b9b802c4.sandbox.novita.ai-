// Only claims in a verified Firebase ID token reach this policy. A provider
// display name, profile email, or client-submitted flag is never authentication.
export function hasTrustedAccount(identity) {
  if (!identity || typeof identity.uid !== 'string' || !identity.uid) return false;
  const provider = identity.firebase?.sign_in_provider;
  if (provider === 'anonymous') return false;
  if (identity.email_verified === true || provider === 'google.com') return true;
  return provider === 'custom' && identity.garden_social_verified === true &&
    ['kakao', 'naver', 'facebook'].includes(identity.garden_social_provider);
}

// Account deletion does not require email verification: otherwise someone who
// cannot receive the verification email could never remove their own account.
// Call only after Firebase verifyIdToken(..., true), never with client JSON.
export function isSignedInAccount(identity) {
  return typeof identity?.uid === 'string' && identity.uid.length > 0 &&
    typeof identity.firebase?.sign_in_provider === 'string' &&
    identity.firebase.sign_in_provider.length > 0 &&
    identity.firebase.sign_in_provider !== 'anonymous';
}

export function hasRecentAuthentication(identity, nowSeconds = Date.now() / 1000) {
  const authenticatedAt = identity?.auth_time;
  return Number.isFinite(authenticatedAt) && authenticatedAt > 0 &&
    Number.isFinite(nowSeconds) && authenticatedAt <= nowSeconds + 30 &&
    nowSeconds - authenticatedAt <= 300;
}
