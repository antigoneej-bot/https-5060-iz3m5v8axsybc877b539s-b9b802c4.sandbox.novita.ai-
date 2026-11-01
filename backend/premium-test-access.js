// Server-controlled temporary entitlement, never read from request/client data.
// Purchase verification/status remain real; this controls feature access only.
export async function premiumFeatureAccess(uid, {testSetting=process.env.PREMIUM_TEST_ACCESS, production=process.env.RELEASE_ENV==='production', verifiedStatus}={}) {
  if(!production && testSetting==='true')return true;
  return (await verifiedStatus(uid)).active===true;
}
