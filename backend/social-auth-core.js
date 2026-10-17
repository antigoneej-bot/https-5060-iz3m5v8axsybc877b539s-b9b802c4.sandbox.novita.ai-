import { createHash, createHmac, randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';
import { accountHash, nextAccountLease } from './policy.js';

export const SOCIAL_RETURN_URI = 'com.mysticcat.journal.auth://callback';
export const SOCIAL_SESSION_MS = 10 * 60 * 1000;
const providers = Object.freeze({
  kakao: {authorize:'https://kauth.kakao.com/oauth/authorize', token:'https://kauth.kakao.com/oauth/token', profile:'https://kapi.kakao.com/v2/user/me'},
  naver: {authorize:'https://nid.naver.com/oauth2.0/authorize', token:'https://nid.naver.com/oauth2.0/token', profile:'https://openapi.naver.com/v1/nid/me'},
  facebook: {}, // Versioned endpoints are resolved from server configuration.
});
const hash = value => createHash('sha256').update(value).digest('hex');
export const socialSessionHash = hash;
const opaque = () => randomBytes(32).toString('base64url');
const isOpaque = value => typeof value === 'string' && /^[A-Za-z0-9_-]{43}$/.test(value);
function fail(code) { throw new Error(code); }
export function pkceChallenge(verifier) {
  if (typeof verifier !== 'string' || !/^[A-Za-z0-9._~-]{43,128}$/.test(verifier)) fail('invalid-proof');
  return createHash('sha256').update(verifier).digest('base64url');
}
export function socialIdentityKey(provider, subject) {
  if (!Object.hasOwn(providers, provider) || typeof subject !== 'string' || !subject || subject.length > 256) fail('invalid-provider-identity');
  return hash(JSON.stringify(['maeumnyang-social-v1', provider, subject]));
}
export function socialUid(provider, key, generation = 0) {
  return `social_${provider}_${hash(`${key}:${generation}`)}`;
}
function checkedConfig(config, provider) {
  if (!Object.hasOwn(providers, provider)) fail('invalid-provider');
  let callback;
  try {callback = new URL(config?.callbackUrl);} catch {fail('provider-disabled');}
  if (!config.clientId || !config.clientSecret || callback.protocol !== 'https:' ||
      callback.username || callback.password || callback.search || callback.hash ||
      ['localhost', '127.0.0.1', '[::1]'].includes(callback.hostname)) fail('provider-disabled');
  if (provider === 'facebook' && !/^v[1-9][0-9]*\.[0-9]+$/.test(config.graphVersion ?? '')) fail('provider-disabled');
  return {...config, callbackUrl:callback.toString()};
}
function providerEndpoints(provider, config) {
  if (provider !== 'facebook') return providers[provider];
  return {
    authorize:`https://www.facebook.com/${config.graphVersion}/dialog/oauth`,
    token:`https://graph.facebook.com/${config.graphVersion}/oauth/access_token`,
    profile:`https://graph.facebook.com/${config.graphVersion}/me`,
    debug:`https://graph.facebook.com/${config.graphVersion}/debug_token`,
  };
}
function liveSession(value, now) {
  if (!value || !Number.isFinite(value.expiresAt) || value.expiresAt <= now) fail('session-expired');
  return value;
}
function returnUrl(session, error) {
  const url = new URL(SOCIAL_RETURN_URI);
  url.searchParams.set('session', session);
  if (error) url.searchParams.set('error', error);
  return url.toString();
}

// Provider responses never leave this server. Email is deliberately neither read
// nor used for linking: provider + validated immutable subject is the identity.
export async function fetchSocialProfile({provider, code, state, config, fetchImpl = fetch, now = Date.now}) {
  config = checkedConfig(config, provider);
  const endpoints = providerEndpoints(provider, config);
  const params = new URLSearchParams({grant_type:'authorization_code', client_id:config.clientId,
    client_secret:config.clientSecret, redirect_uri:config.callbackUrl, code});
  if (provider === 'naver') params.set('state', state);
  async function json(url, init) {
    const response = await fetchImpl(url, {...init, redirect:'error', signal:AbortSignal.timeout(12000)});
    if (!response.ok) fail('provider-error');
    const text = await response.text();
    if (text.length > 256 * 1024) fail('provider-error');
    try {return JSON.parse(text);} catch {fail('provider-error');}
  }
  // Meta's documented manual flow exchanges code via HTTPS GET. Never log
  // provider request URLs: the token endpoint query contains the app secret.
  const token = provider === 'facebook'
    ? await json(`${endpoints.token}?${params}`, {method:'GET'})
    : await json(endpoints.token, {method:'POST',
      headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:params.toString()});
  if (typeof token.access_token !== 'string' || !token.access_token || token.access_token.length > 16384 || token.error) fail('provider-error');
  let debug;
  let profileUrl = endpoints.profile;
  if (provider === 'facebook') {
    const debugUrl = new URL(endpoints.debug);
    debugUrl.searchParams.set('input_token', token.access_token);
    const verification = await json(debugUrl.toString(), {method:'GET',
      headers:{Authorization:`Bearer ${config.clientId}|${config.clientSecret}`}});
    debug = verification.data;
    const validExpiry = value => value === undefined || value === 0 ||
      (Number.isSafeInteger(value) && value > now() / 1000);
    if (verification.error || debug?.is_valid !== true || debug.type !== 'USER' ||
        String(debug.app_id) !== config.clientId || typeof debug.user_id !== 'string' ||
        !/^[0-9]{1,32}$/.test(debug.user_id) || !validExpiry(debug.expires_at) ||
        !validExpiry(debug.data_access_expires_at)) fail('invalid-provider-identity');
    const url = new URL(endpoints.profile);
    url.searchParams.set('fields', 'id');
    url.searchParams.set('appsecret_proof', createHmac('sha256', config.clientSecret).update(token.access_token).digest('hex'));
    profileUrl = url.toString();
  }
  const result = await json(profileUrl, {method:'GET', headers:{Authorization:`Bearer ${token.access_token}`}});
  let subject;
  if (provider === 'kakao') {
    if (Number.isSafeInteger(result.id) && result.id > 0) subject = String(result.id);
    else if (typeof result.id === 'string' && /^[0-9]{1,24}$/.test(result.id)) subject = result.id;
  } else if (provider === 'facebook') {
    if (!result.error && typeof result.id === 'string' && result.id === debug.user_id) subject = result.id;
  } else if (result.resultcode === '00' && typeof result.response?.id === 'string') {
    subject = result.response.id;
  }
  socialIdentityKey(provider, subject); // Reject missing/unsafe subject before issuing any credential.
  return {subject};
}

// All state transitions and identity generation changes are Firestore
// transactions. Injection allows exercising real transitions without live keys.
export function createSocialAuthFlow({db, auth, getConfig, now = Date.now, token = opaque,
  fetchProfile = fetchSocialProfile, ownerToken = randomUUID}) {
  async function start({provider, codeChallenge, appId, rateKey}) {
    const config = checkedConfig(getConfig(provider), provider);
    if (!isOpaque(codeChallenge)) fail('invalid-proof');
    if (typeof appId !== 'string' || !appId) fail('app-check-required');
    const session = token(), state = token(), at = now(), expiresAt = at + SOCIAL_SESSION_MS;
    if (!isOpaque(session) || !isOpaque(state)) fail('temporarily-unavailable');
    const sessionRef = db.doc(`socialAuthSessions/${hash(session)}`);
    const stateRef = db.doc(`socialAuthStates/${hash(state)}`);
    const limitRef = db.doc(`socialAuthLimits/${hash(`${appId}:${rateKey ?? 'unknown'}`)}`);
    await db.runTransaction(async tx => {
      const [limit, previousSession, previousState] = await Promise.all([tx.get(limitRef), tx.get(sessionRef), tx.get(stateRef)]);
      if (previousSession.exists || previousState.exists) fail('temporarily-unavailable');
      const old = limit.data() ?? {}, active = at - (old.start ?? 0) < SOCIAL_SESSION_MS;
      const count = active ? (old.count ?? 0) + 1 : 1;
      if (count > 20) fail('rate-limit');
      tx.set(limitRef, {start:active ? old.start : at, count, expireAt:new Date(expiresAt)});
      tx.set(sessionRef, {provider, appId, codeChallenge, status:'pending', expiresAt,
        expireAt:new Date(expiresAt), createdAt:at});
      tx.set(stateRef, {session, status:'pending', expiresAt, expireAt:new Date(expiresAt)});
    });
    const url = new URL(providerEndpoints(provider, config).authorize);
    url.search = new URLSearchParams({response_type:'code', client_id:config.clientId,
      redirect_uri:config.callbackUrl, state}).toString();
    if (provider === 'facebook') url.searchParams.set('scope', 'public_profile');
    return {session, authorizationUrl:url.toString(), expiresAt:new Date(expiresAt).toISOString()};
  }

  async function callback({state, code, error}) {
    if (!isOpaque(state)) fail('invalid-state');
    const stateRef = db.doc(`socialAuthStates/${hash(state)}`);
    // Claim the state BEFORE any provider request. Replays never exchange twice.
    const {session, value} = await db.runTransaction(async tx => {
      const stateDoc = await tx.get(stateRef), stateValue = liveSession(stateDoc.data(), now());
      if (stateValue.status !== 'pending') fail('session-used');
      const sessionRef = db.doc(`socialAuthSessions/${hash(stateValue.session)}`);
      const doc = await tx.get(sessionRef), value = liveSession(doc.data(), now());
      if (value.status !== 'pending') fail('session-used');
      tx.set(stateRef, {...stateValue, status:'used'});
      tx.set(sessionRef, {...value, status:'authorizing'});
      return {session:stateValue.session, value};
    });
    const ref = db.doc(`socialAuthSessions/${hash(session)}`);
    async function finish(update) {
      await db.runTransaction(async tx => {
        const value = liveSession((await tx.get(ref)).data(), now());
        if (value.status !== 'authorizing') fail('session-used');
        tx.set(ref, {...value, ...update});
      });
    }
    if (error) {
      await finish({status:'failed', error:'login-cancelled'});
      return {redirectUrl:returnUrl(session, 'login-cancelled')};
    }
    if (typeof code !== 'string' || code.length < 1 || code.length > 4096) {
      await finish({status:'failed', error:'provider-error'});
      return {redirectUrl:returnUrl(session, 'provider-error')};
    }
    try {
      const config = checkedConfig(getConfig(value.provider), value.provider);
      const profile = await fetchProfile({provider:value.provider, code, state, config});
      const identityKey = socialIdentityKey(value.provider, profile.subject);
      await finish({status:'ready', identityKey});
      return {redirectUrl:returnUrl(session)};
    } catch {
      // Never return provider tokens, codes, email, or raw provider errors.
      try {await finish({status:'failed', error:'provider-error'});} catch { /* expired state remains unusable */ }
      return {redirectUrl:returnUrl(session, 'provider-error')};
    }
  }

  async function recoverCompletedDeletion(provider, identityKey) {
    const identityRef = db.doc(`socialAuthIdentities/${identityKey}`);
    const pending = await db.runTransaction(async tx => {
      const identity = (await tx.get(identityRef)).data();
      if (identity && identity.provider !== provider) fail('invalid-provider-identity');
      const generation = identity?.generation ?? 0;
      if (!Number.isSafeInteger(generation) || generation < 0) fail('invalid-provider-identity');
      const uid = socialUid(provider, identityKey, generation);
      const ref = db.doc(`accountLocks/${accountHash(uid)}`);
      const lock = (await tx.get(ref)).data();
      // deleted is written only AFTER all server data cleanup. A plain
      // deleting flag is never sufficient evidence that deletion completed.
      return lock?.deleted === true && lock.deletionCompleted !== true
        ? {generation, uid, ref} : null;
    });
    if (!pending) return;
    try {
      await auth.getUser(pending.uid);
      fail('account-deleting'); // Existing and disabled accounts stay locked.
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
    }
    // Auth and Firestore cannot commit atomically. Recover the lost final
    // marker only from an authoritative not-found result, then re-read both
    // records transactionally so parallel sign-ins cannot advance twice.
    await db.runTransaction(async tx => {
      const identity = (await tx.get(identityRef)).data();
      if (identity && identity.provider !== provider) fail('invalid-provider-identity');
      const generation = identity?.generation ?? 0;
      if (!Number.isSafeInteger(generation) || generation < 0) fail('invalid-provider-identity');
      const currentUid = socialUid(provider, identityKey, generation);
      const lock = (await tx.get(pending.ref)).data();
      if (generation !== pending.generation || currentUid !== pending.uid) return;
      if (lock?.deleted !== true) fail('account-deleting');
      if (lock.deletionCompleted !== true) tx.set(pending.ref, {...lock, deletionCompleted:true});
    });
  }

  async function resolveAndLease(provider, identityKey) {
    await recoverCompletedDeletion(provider, identityKey);
    const identityRef = db.doc(`socialAuthIdentities/${identityKey}`), owner = ownerToken();
    return db.runTransaction(async tx => {
      const identity = (await tx.get(identityRef)).data();
      if (identity && identity.provider !== provider) fail('invalid-provider-identity');
      let generation = identity?.generation ?? 0;
      if (!Number.isSafeInteger(generation) || generation < 0) fail('invalid-provider-identity');
      let uid = socialUid(provider, identityKey, generation);
      let ref = db.doc(`accountLocks/${accountHash(uid)}`);
      let previous = (await tx.get(ref)).data() ?? {};
      if (previous.deleted && previous.deletionCompleted === true) {
        // A returning person gets a NEW account. Old purchase tombstones and
        // records remain isolated and are never migrated by social login.
        generation += 1;
        uid = socialUid(provider, identityKey, generation);
        ref = db.doc(`accountLocks/${accountHash(uid)}`);
        previous = (await tx.get(ref)).data() ?? {};
      }
      const lease = nextAccountLease(previous, 'socialLogin', owner, now());
      tx.set(identityRef, {provider, generation, uid, updatedAt:now()});
      tx.set(ref, lease);
      return {uid, owner, ref};
    });
  }

  async function exchange({session, codeVerifier, appId}) {
    if (!isOpaque(session)) fail('session-expired');
    const challenge = pkceChallenge(codeVerifier), ref = db.doc(`socialAuthSessions/${hash(session)}`);
    const value = await db.runTransaction(async tx => {
      const value = liveSession((await tx.get(ref)).data(), now());
      if (value.appId !== appId) fail('app-check-required');
      if (value.codeChallenge.length !== challenge.length ||
          !timingSafeEqual(Buffer.from(value.codeChallenge), Buffer.from(challenge))) fail('invalid-proof');
      if (value.status === 'failed') fail(value.error || 'provider-error');
      if (value.status === 'pending' || value.status === 'authorizing') fail('session-not-ready');
      if (value.status !== 'ready') fail('session-used');
      tx.set(ref, {...value, status:'exchanging'});
      return value;
    });
    let lease;
    try {
      lease = await resolveAndLease(value.provider, value.identityKey);
      let user;
      try {user = await auth.getUser(lease.uid);} catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
        user = await auth.createUser({uid:lease.uid});
      }
      if (user.disabled) fail('account-disabled');
      const claims = {...user.customClaims, garden_social_verified:true, garden_social_provider:value.provider};
      await auth.setCustomUserClaims(lease.uid, claims);
      const customToken = await auth.createCustomToken(lease.uid, {
        garden_social_verified:true, garden_social_provider:value.provider});
      // Record consumption BEFORE exposing token. A lost response starts a new
      // sign-in; tokens are never retained in Firestore to support replay.
      await ref.set({status:'consumed', provider:value.provider, appId:value.appId, codeChallenge:value.codeChallenge, expiresAt:value.expiresAt,
        expireAt:new Date(value.expiresAt)});
      return {customToken, provider:value.provider};
    } catch (error) {
      await ref.set({status:'failed', provider:value.provider, appId:value.appId, codeChallenge:value.codeChallenge, error:'login-restart-required',
        expiresAt:value.expiresAt, expireAt:new Date(value.expiresAt)});
      throw error;
    } finally {
      if (lease) await db.runTransaction(async tx => {
        const current = (await tx.get(lease.ref)).data();
        if (current?.owner === lease.owner) {
          const {owner, until, ...remaining} = current;
          tx.set(lease.ref, remaining);
        }
      });
    }
  }
  return {start, callback, exchange};
}

const errors = new Map([
  ['invalid-provider',400], ['invalid-proof',400], ['invalid-state',400],
  ['provider-disabled',503], ['app-check-required',401], ['session-expired',410],
  ['session-not-ready',409], ['session-used',409], ['provider-error',502],
  ['login-cancelled',409], ['login-restart-required',409], ['account-disabled',403],
  ['account-deleting',409], ['account-busy',409], ['rate-limit',429],
]);
export function createSocialAuthHandler({flow, verifyAppCheck, expectedAppId}) {
  return async (req, res) => {
    res.set('Cache-Control','no-store');
    res.set('Referrer-Policy','no-referrer');
    res.set('X-Content-Type-Options','nosniff');
    const https = req.secure || req.get('X-Forwarded-Proto')?.split(',')[0].trim() === 'https';
    if (!https) {res.status(400).json({error:'https-required'}); return;}
    try {
      if (req.method === 'GET') {
        const result = await flow.callback({state:req.query?.state, code:req.query?.code, error:req.query?.error});
        res.redirect(302, result.redirectUrl); return;
      }
      if (req.method !== 'POST') {res.status(405).json({error:'method-not-allowed'}); return;}
      if ((req.rawBody?.length ?? 0) > 8192) {res.status(413).json({error:'too-large'}); return;}
      let attestation;
      try {attestation = await verifyAppCheck(req.get('X-Firebase-AppCheck') ?? '');}
      catch {fail('app-check-required');}
      if (!expectedAppId || attestation?.appId !== expectedAppId) fail('app-check-required');
      if (req.body?.action === 'start') {
        res.json(await flow.start({provider:req.body.provider, codeChallenge:req.body.codeChallenge,
          appId:attestation.appId, rateKey:req.ip})); return;
      }
      if (req.body?.action === 'exchange') {
        res.json(await flow.exchange({session:req.body.session, codeVerifier:req.body.codeVerifier,
          appId:attestation.appId})); return;
      }
      res.status(400).json({error:'unknown-action'});
    } catch (error) {
      const status = errors.get(error.message) ?? 503;
      res.status(status).json({error:errors.has(error.message) ? error.message : 'temporarily-unavailable'});
    }
  };
}
