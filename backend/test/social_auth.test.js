import test from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { memoryDb } from '../testing/memory-db.js';
import { accountHash } from '../policy.js';
import { createSocialAuthFlow, createSocialAuthHandler, fetchSocialProfile, pkceChallenge,
  socialIdentityKey, socialUid, socialSessionHash, SOCIAL_SESSION_MS, SOCIAL_RETURN_URI } from '../social-auth-core.js';

const verifier = 'Z'.repeat(64), appId = '1:123:android:abc';
function setup(options = {}) {
  let time = 10000000, counter = 0, profileCalls = 0;
  const db = memoryDb(), users = new Map(), minted = [], creates = [];
  const auth = {
    async getUser(uid) {if (!users.has(uid)) throw Object.assign(new Error('absent'), {code:'auth/user-not-found'}); return users.get(uid);},
    async createUser(value) {creates.push(value); users.set(value.uid, {...value}); return users.get(value.uid);},
    async setCustomUserClaims(uid, claims) {users.get(uid).customClaims = claims;},
    async createCustomToken(uid, claims) {minted.push({uid, claims}); return `token-for-${uid}`;},
  };
  const config = {clientId:'test-client', clientSecret:'test-server-secret', callbackUrl:'https://example.test/socialAuth',graphVersion:'v26.0'};
  const flow = createSocialAuthFlow({db, auth, now:() => time, getConfig:() => config,
    token:() => (++counter).toString().padStart(43, '0'),
    fetchProfile:async () => {profileCalls++; return {subject:'user-123', email:'must-not-link@example.test'};}, ...options});
  async function start(provider = 'kakao') {return flow.start({provider, codeChallenge:pkceChallenge(verifier), appId, rateKey:'test-ip'});}
  async function ready(provider = 'kakao') {
    const begin = await start(provider), state = new URL(begin.authorizationUrl).searchParams.get('state');
    const result = await flow.callback({state, code:'provider-code'});
    return {...begin, state, result};
  }
  return {db, users, auth, flow, config, minted, creates, start, ready,
    get profileCalls() {return profileCalls;}, advance:ms => {time += ms;}};
}
const exchange = (s, session, changes = {}) => s.flow.exchange({session, codeVerifier:verifier, appId, ...changes});

test('authorization URLs use configured callback, random server state, and never expose secret', async () => {
  const s = setup(), start = await s.start('naver'), url = new URL(start.authorizationUrl);
  assert.equal(url.origin, 'https://nid.naver.com');
  assert.equal(url.searchParams.get('redirect_uri'), s.config.callbackUrl);
  assert.equal(url.searchParams.get('client_id'), s.config.clientId);
  assert.equal(url.searchParams.get('response_type'), 'code');
  assert.equal(url.searchParams.get('state').length, 43);
  assert.notEqual(url.searchParams.get('state'), start.session);
  assert.ok(!start.authorizationUrl.includes(s.config.clientSecret));
});
test('disabled/insecure providers and malformed challenge fail without storing sessions', async () => {
  for (const override of [{clientId:''}, {clientSecret:''}, {callbackUrl:'http://example.test'},
    {callbackUrl:'https://example.test/cb?return=evil'}, {callbackUrl:'https://user:pass@example.test/cb'}]) {
    const s = setup(); Object.assign(s.config, override);
    await assert.rejects(s.start(), /provider-disabled/);
    assert.equal(s.db.rows.size, 0);
  }
  const s = setup();
  await assert.rejects(s.start('evil'), /invalid-provider/);
  await assert.rejects(s.flow.start({provider:'kakao', codeChallenge:'plain', appId}), /invalid-proof/);
  assert.equal(s.db.rows.size, 0);
});
test('CSRF unknown or malformed state never calls provider', async () => {
  const s = setup(); await s.start();
  await assert.rejects(s.flow.callback({state:'bad', code:'x'}), /invalid-state/);
  await assert.rejects(s.flow.callback({state:'A'.repeat(43), code:'x'}), /session-expired/);
  assert.equal(s.profileCalls, 0);
});
test('concurrent callback and state replay exchange provider code exactly once', async () => {
  const s = setup(), begin = await s.start(), state = new URL(begin.authorizationUrl).searchParams.get('state');
  const calls = await Promise.allSettled([s.flow.callback({state, code:'one'}), s.flow.callback({state, code:'two'})]);
  assert.equal(calls.filter(x => x.status === 'fulfilled').length, 1);
  assert.equal(s.profileCalls, 1);
  await assert.rejects(s.flow.callback({state, code:'three'}), /session-used/);
});
test('callback returns only opaque session; browser never receives auth/access tokens or identity', async () => {
  const s = setup(), r = await s.ready(), url = new URL(r.result.redirectUrl);
  assert.equal(url.origin, new URL(SOCIAL_RETURN_URI).origin);
  assert.equal(url.protocol, 'com.mysticcat.journal.auth:');
  assert.equal(url.hostname, 'callback');
  assert.deepEqual([...url.searchParams.keys()], ['session']);
  assert.equal(url.searchParams.get('session'), r.session);
  assert.equal(s.minted.length, 0);
});
test('cancelled consent returns safe error and never creates an account', async () => {
  const s = setup(), begin = await s.start(), state = new URL(begin.authorizationUrl).searchParams.get('state');
  const result = await s.flow.callback({state, error:'access_denied<script>'});
  assert.equal(new URL(result.redirectUrl).searchParams.get('error'), 'login-cancelled');
  await assert.rejects(exchange(s, begin.session), /login-cancelled/);
  assert.equal(s.profileCalls, 0); assert.equal(s.creates.length, 0);
});
test('wrong PKCE or wrong app cannot consume successful callback', async () => {
  const s = setup(), r = await s.ready();
  await assert.rejects(exchange(s, r.session, {codeVerifier:'A'.repeat(64)}), /invalid-proof/);
  await assert.rejects(exchange(s, r.session, {appId:'another-app'}), /app-check-required/);
  const result = await exchange(s, r.session);
  assert.ok(result.customToken.startsWith('token-for-social_kakao_'));
  assert.equal(s.minted.length, 1);
});
test('exchange cannot mint before callback succeeds', async () => {
  const s = setup(), r = await s.start();
  await assert.rejects(exchange(s, r.session), /session-not-ready/);
  assert.equal(s.minted.length, 0);
});
test('expired state and expired ready exchange fail closed even before TTL cleanup', async () => {
  const s = setup(), r = await s.start(), state = new URL(r.authorizationUrl).searchParams.get('state');
  s.advance(SOCIAL_SESSION_MS);
  await assert.rejects(s.flow.callback({state, code:'x'}), /session-expired/);
  const r2 = await s.ready(); s.advance(SOCIAL_SESSION_MS);
  await assert.rejects(exchange(s, r2.session), /session-expired/);
  assert.equal(s.minted.length, 0);
});
test('concurrent exchange and subsequent replay mint one token total', async () => {
  const s = setup(), r = await s.ready();
  const results = await Promise.allSettled([exchange(s,r.session), exchange(s,r.session)]);
  assert.equal(results.filter(x => x.status === 'fulfilled').length,1);
  assert.equal(s.minted.length,1);
  await assert.rejects(exchange(s,r.session), /session-used/);
});
test('new identity uses server-only claims, never email linking or verified-email forgery', async () => {
  const s = setup(), r = await s.ready('naver');
  await exchange(s,r.session);
  assert.deepEqual(Object.keys(s.creates[0]), ['uid']);
  assert.deepEqual(s.minted[0].claims, {garden_social_verified:true, garden_social_provider:'naver'});
  const user = s.users.get(s.minted[0].uid);
  assert.equal(user.email,undefined); assert.equal(user.emailVerified,undefined);
  assert.equal(user.customClaims.garden_social_verified,true);
  for (const value of s.db.rows.values()) {
    const json = JSON.stringify(value);
    assert.ok(!json.includes('must-not-link')); assert.ok(!json.includes('provider-code')); assert.ok(!json.includes('token-for-'));
  }
});
test('same provider identity reuses UID and different provider is isolated', async () => {
  const s = setup();
  await exchange(s,(await s.ready('kakao')).session);
  await exchange(s,(await s.ready('kakao')).session);
  await exchange(s,(await s.ready('naver')).session);
  assert.equal(s.minted[0].uid,s.minted[1].uid);
  assert.notEqual(s.minted[0].uid,s.minted[2].uid);
  assert.equal(s.creates.length,2);
});
test('disabled Firebase social account remains disabled', async () => {
  const s = setup(), key = socialIdentityKey('kakao','user-123'), uid = socialUid('kakao',key);
  s.users.set(uid,{uid,disabled:true});
  await assert.rejects(exchange(s,(await s.ready()).session), /account-disabled/);
  assert.equal(s.minted.length,0);
  assert.equal((await s.db.doc(`accountLocks/${accountHash(uid)}`).get()).data().owner,undefined);
});
test('in-progress or incompletely finished deletion cannot recreate old identity', async () => {
  for (const lock of [{deleting:true}, {deleted:true}, {deleted:true,deleting:true}]) {
    const s=setup(), uid=socialUid('kakao',socialIdentityKey('kakao','user-123'));
    s.users.set(uid,{uid}); // Auth deletion has not completed.
    await s.db.doc(`accountLocks/${accountHash(uid)}`).set(lock);
    await assert.rejects(exchange(s,(await s.ready()).session), /account-deleting/);
    assert.equal(s.creates.length,0); assert.equal(s.minted.length,0);
  }
});

test('lost deletion completion marker recovers only after data cleanup and authoritative Auth absence', async () => {
  const s=setup(),key=socialIdentityKey('facebook','user-123'),oldUid=socialUid('facebook',key);
  await s.db.doc(`socialAuthIdentities/${key}`).set({provider:'facebook',generation:0,uid:oldUid});
  await s.db.doc(`accountLocks/${accountHash(oldUid)}`).set({deleted:true,deleting:true});
  await s.db.doc('purchaseTokens/old-purchase').set({deleted:true});
  await exchange(s,(await s.ready('facebook')).session);
  assert.equal(s.minted[0].uid,socialUid('facebook',key,1));
  assert.equal((await s.db.doc(`accountLocks/${accountHash(oldUid)}`).get()).data().deletionCompleted,true);
  assert.deepEqual((await s.db.doc('purchaseTokens/old-purchase').get()).data(),{deleted:true});
  assert.equal(s.users.has(oldUid),false);
  assert.equal(s.creates.some(user=>user.uid===oldUid),false);
});
test('Auth absence without completed data cleanup never recovers deletion', async () => {
  const s=setup(),key=socialIdentityKey('kakao','user-123'),uid=socialUid('kakao',key);
  await s.db.doc(`accountLocks/${accountHash(uid)}`).set({deleting:true});
  let lookups=0;s.auth.getUser=async()=>{lookups++;throw Object.assign(new Error('absent'),{code:'auth/user-not-found'});};
  await assert.rejects(exchange(s,(await s.ready()).session),/account-deleting/);
  assert.equal(lookups,0);assert.equal(s.minted.length,0);
});
test('existing or disabled Auth account and non-not-found outages cannot mark deletion complete', async () => {
  for (const mode of ['existing','disabled','outage','untyped-not-found']) {
    const s=setup(),key=socialIdentityKey('kakao','user-123'),uid=socialUid('kakao',key);
    const ref=s.db.doc(`accountLocks/${accountHash(uid)}`);
    await ref.set({deleted:true});
    s.auth.getUser=async()=>{
      if(mode==='outage')throw Object.assign(new Error('network-unavailable'),{code:'auth/internal-error'});
      if(mode==='untyped-not-found')throw new Error('auth/user-not-found');
      return {uid,disabled:mode==='disabled'};
    };
    await assert.rejects(exchange(s,(await s.ready()).session));
    assert.notEqual((await ref.get()).data().deletionCompleted,true);
    assert.equal(s.minted.length,0);assert.equal(s.creates.length,0);
  }
});
test('a failed recovery marker write can be retried by a fresh verified social sign-in', async () => {
  const s=setup(),key=socialIdentityKey('naver','user-123'),oldUid=socialUid('naver',key);
  const ref=s.db.doc(`accountLocks/${accountHash(oldUid)}`);
  await ref.set({deleted:true});
  const original=s.db.runTransaction;let failMarker=true;
  s.db.runTransaction=fn=>original(tx=>fn({...tx,set:(target,value,options)=>{
    if(target.path===ref.path && value.deletionCompleted===true && failMarker) {
      failMarker=false;throw new Error('marker-write-failed');
    }
    return tx.set(target,value,options);
  }}));
  await assert.rejects(exchange(s,(await s.ready('naver')).session),/marker-write-failed/);
  assert.equal(s.minted.length,0);assert.notEqual((await ref.get()).data().deletionCompleted,true);
  await exchange(s,(await s.ready('naver')).session);
  assert.equal(s.minted[0].uid,socialUid('naver',key,1));
  assert.equal((await ref.get()).data().deletionCompleted,true);
});
test('concurrent lost-marker recovery advances the social generation only once', async () => {
  const s=setup(),key=socialIdentityKey('kakao','user-123'),oldUid=socialUid('kakao',key);
  await s.db.doc(`accountLocks/${accountHash(oldUid)}`).set({deleted:true});
  const first=await s.ready(),second=await s.ready();
  const results=await Promise.allSettled([exchange(s,first.session),exchange(s,second.session)]);
  assert.ok(results.some(result=>result.status==='fulfilled'));
  assert.equal((await s.db.doc(`socialAuthIdentities/${key}`).get()).data().generation,1);
  assert.ok(s.minted.every(result=>result.uid===socialUid('kakao',key,1)));
  assert.equal(s.creates.some(user=>user.uid===oldUid),false);
});
test('recovery rechecks cleanup state transactionally after the Auth lookup', async () => {
  const s=setup(),key=socialIdentityKey('kakao','user-123'),uid=socialUid('kakao',key);
  const ref=s.db.doc(`accountLocks/${accountHash(uid)}`);
  await ref.set({deleted:true});
  s.auth.getUser=async()=>{
    await ref.set({deleting:true});
    throw Object.assign(new Error('absent'),{code:'auth/user-not-found'});
  };
  await assert.rejects(exchange(s,(await s.ready()).session),/account-deleting/);
  assert.notEqual((await ref.get()).data().deletionCompleted,true);
  assert.equal(s.minted.length,0);
});
test('completed deletion creates next generation without resurrecting records or purchases', async () => {
  const s=setup(), key=socialIdentityKey('kakao','user-123'), oldUid=socialUid('kakao',key);
  await s.db.doc(`socialAuthIdentities/${key}`).set({provider:'kakao',generation:0,uid:oldUid});
  await s.db.doc(`accountLocks/${accountHash(oldUid)}`).set({deleted:true,deletionCompleted:true});
  await s.db.doc('purchaseTokens/old').set({deleted:true});
  await exchange(s,(await s.ready()).session);
  assert.equal(s.minted[0].uid,socialUid('kakao',key,1));
  assert.deepEqual((await s.db.doc('purchaseTokens/old').get()).data(),{deleted:true});
  assert.equal(s.db.rows.has(`users/${oldUid}`),false);
});
test('concurrent rejoin chooses one next generation even if other login is busy', async () => {
  const s=setup(), key=socialIdentityKey('kakao','user-123'), oldUid=socialUid('kakao',key);
  await s.db.doc(`accountLocks/${accountHash(oldUid)}`).set({deleted:true,deletionCompleted:true});
  const r1=await s.ready(),r2=await s.ready();
  const results=await Promise.allSettled([exchange(s,r1.session),exchange(s,r2.session)]);
  assert.ok(results.some(r => r.status === 'fulfilled'));
  assert.equal((await s.db.doc(`socialAuthIdentities/${key}`).get()).data().generation,1);
  assert.ok(s.minted.every(r => r.uid === socialUid('kakao',key,1)));
});
test('failed mint releases account lease and requires new flow; no token is cached', async () => {
  const s=setup(); s.auth.createCustomToken=async()=>{throw new Error('internal signing secret details');};
  const r=await s.ready();
  await assert.rejects(exchange(s,r.session), /internal signing/);
  await assert.rejects(exchange(s,r.session), /login-restart-required/);
  const uid=socialUid('kakao',socialIdentityKey('kakao','user-123'));
  assert.equal((await s.db.doc(`accountLocks/${accountHash(uid)}`).get()).data().owner,undefined);
});
test('start quota expires and never stores raw IP', async () => {
  const s=setup(); for(let i=0;i<20;i++) await s.start();
  await assert.rejects(s.start(), /rate-limit/);
  assert.ok(!JSON.stringify([...s.db.rows]).includes('test-ip'));
  s.advance(SOCIAL_SESSION_MS); await s.start();
});

function response() {
  return {statusCode:200, headers:{}, set(k,v){this.headers[k]=v;return this;}, status(n){this.statusCode=n;return this;},
    json(body){this.body=body;}, redirect(status,url){this.statusCode=status;this.url=url;}};
}
function request(body={}, overrides={}) {
  return {method:'POST',secure:true,ip:'127.0.0.1',rawBody:Buffer.from(JSON.stringify(body)),body,
    get:name=>name==='X-Firebase-AppCheck'?'valid-token':undefined,...overrides};
}
test('HTTP handler requires correct AppCheck project app for both start/exchange', async () => {
  for (const action of ['start','exchange']) {
    const s=setup(), handler=createSocialAuthHandler({flow:s.flow,expectedAppId:appId,verifyAppCheck:async()=>({appId:'wrong'})}),res=response();
    await handler(request({action,provider:'kakao',codeChallenge:pkceChallenge(verifier)}),res);
    assert.equal(res.statusCode,401); assert.equal(res.body.error,'app-check-required');
    assert.equal(s.db.rows.size,0);
  }
});
test('HTTP handler rejects plain HTTP, wrong methods and oversize without authentication calls', async () => {
  const s=setup(); let checks=0;
  const handler=createSocialAuthHandler({flow:s.flow,expectedAppId:appId,verifyAppCheck:async()=>{checks++;return {appId};}});
  for (const [override,status] of [[{secure:false},400],[{method:'PUT'},405],[{rawBody:Buffer.alloc(8193)},413]]) {
    const res=response(); await handler(request({},override),res); assert.equal(res.statusCode,status);
  }
  assert.equal(checks,0);
});
test('HTTP callback requires state but not AppCheck, redirect and JSON are no-store', async () => {
  const s=setup(), r=await s.start(),state=new URL(r.authorizationUrl).searchParams.get('state');
  const handler=createSocialAuthHandler({flow:s.flow,expectedAppId:appId,verifyAppCheck:async()=>{throw new Error('must not be called');}}),res=response();
  await handler(request({}, {method:'GET',query:{state,code:'valid'}}),res);
  assert.equal(res.statusCode,302); assert.ok(res.url.startsWith(SOCIAL_RETURN_URI));
  assert.equal(res.headers['Cache-Control'],'no-store'); assert.equal(res.headers['Referrer-Policy'],'no-referrer');
});
test('HTTP handler sanitizes unexpected errors rather than leak provider credentials', async () => {
  const res=response(),handler=createSocialAuthHandler({flow:{start:async()=>{throw new Error('client_secret=DO_NOT_LEAK');}},
    expectedAppId:appId,verifyAppCheck:async()=>({appId})});
  await handler(request({action:'start'}),res);
  assert.equal(res.statusCode,503);assert.deepEqual(res.body,{error:'temporarily-unavailable'});
});

test('Naver token exchange posts server secret and state, retrieves identity with bearer; no email linking', async () => {
  const calls=[], config={clientId:'id',clientSecret:'secret',callbackUrl:'https://example.test/cb'};
  const fetchImpl=async(url,options)=>{calls.push({url,options});return {ok:true,text:async()=>JSON.stringify(calls.length===1?{access_token:'provider-token'}:{resultcode:'00',response:{id:'subject',email:'ignored@example.test'}})};};
  const result=await fetchSocialProfile({provider:'naver',code:'code',state:'state',config,fetchImpl});
  assert.deepEqual(result,{subject:'subject'});
  assert.equal(calls[0].url,'https://nid.naver.com/oauth2.0/token');
  assert.equal(calls[0].options.method,'POST');
  assert.equal(new URLSearchParams(calls[0].options.body).get('state'),'state');
  assert.equal(new URLSearchParams(calls[0].options.body).get('client_secret'),'secret');
  assert.equal(calls[1].options.headers.Authorization,'Bearer provider-token');
  assert.equal(calls[0].options.redirect,'error');
});
test('Kakao rejects unsafe numeric subject instead of rounding identity', async () => {
  let count=0;
  await assert.rejects(fetchSocialProfile({provider:'kakao',code:'x',state:'s',config:{clientId:'id',clientSecret:'secret',callbackUrl:'https://example.test/cb'},
    fetchImpl:async()=>({ok:true,text:async()=>JSON.stringify(++count===1?{access_token:'token'}:{id:9007199254740992})})}),/invalid-provider-identity/);
});
test('provider HTTP failure cannot make ready session or mint token', async () => {
  const s=setup({fetchProfile:async()=>{throw new Error('provider access_token=secret');}}),r=await s.ready();
  assert.equal(new URL(r.result.redirectUrl).searchParams.get('error'),'provider-error');
  await assert.rejects(exchange(s,r.session), /provider-error/); assert.equal(s.minted.length,0);
});

test('Facebook authorization uses pinned version, minimal scope, configured callback and one-time state', async () => {
  const s=setup(), start=await s.start('facebook'), url=new URL(start.authorizationUrl);
  assert.equal(url.origin,'https://www.facebook.com');
  assert.equal(url.pathname,'/v26.0/dialog/oauth');
  assert.equal(url.searchParams.get('scope'),'public_profile');
  assert.equal(url.searchParams.get('response_type'),'code');
  assert.equal(url.searchParams.get('redirect_uri'),s.config.callbackUrl);
  assert.equal(url.searchParams.get('state').length,43);
  assert.ok(!start.authorizationUrl.includes(s.config.clientSecret));
  for (const graphVersion of [undefined,'','26.0','v26.0/evil','v0.0']) {
    s.config.graphVersion=graphVersion;
    await assert.rejects(s.start('facebook'),/provider-disabled/);
  }
});
test('Facebook verified identity gets isolated UID and server-only provider claims', async () => {
  const s=setup();
  await exchange(s,(await s.ready('facebook')).session);
  await exchange(s,(await s.ready('kakao')).session);
  await exchange(s,(await s.ready('facebook')).session);
  assert.equal(s.minted[0].uid,s.minted[2].uid);
  assert.notEqual(s.minted[0].uid,s.minted[1].uid);
  assert.deepEqual(s.minted[0].claims,{garden_social_verified:true,garden_social_provider:'facebook'});
  assert.deepEqual(Object.keys(s.creates[0]),['uid']);
});

function facebookFetch({debugChanges={}, profileChanges={}, tokenChanges={}}={}) {
  const calls=[];
  const config={clientId:'123456',clientSecret:'server-secret',callbackUrl:'https://example.test/socialAuth',graphVersion:'v26.0'};
  const responses=[{access_token:'facebook-user-token',...tokenChanges},
    {data:{is_valid:true,type:'USER',app_id:'123456',user_id:'987654',expires_at:2000000000,data_access_expires_at:2000000000,...debugChanges}},
    {id:'987654',email:'ignored@example.test',...profileChanges}];
  const fetchImpl=async(url,options)=>{
    calls.push({url,options});
    return {ok:true,text:async()=>JSON.stringify(responses[calls.length-1])};
  };
  return {calls,run:()=>fetchSocialProfile({provider:'facebook',code:'one-time-code',state:'state',config,fetchImpl,now:()=>1000000000000}),config};
}
test('Facebook server validates app/user/token before accepting app-scoped profile ID; bearer and secret proof stay server-side', async () => {
  const s=facebookFetch();
  assert.deepEqual(await s.run(),{subject:'987654'});
  const tokenUrl=new URL(s.calls[0].url);
  assert.equal(s.calls[0].options.method,'GET');
  assert.equal(tokenUrl.pathname,'/v26.0/oauth/access_token');
  assert.equal(tokenUrl.searchParams.get('client_secret'),'server-secret');
  assert.equal(tokenUrl.searchParams.get('redirect_uri'),s.config.callbackUrl);
  assert.equal(tokenUrl.searchParams.get('code'),'one-time-code');
  assert.equal(new URL(s.calls[1].url).pathname,'/v26.0/debug_token');
  assert.equal(s.calls[1].options.headers.Authorization,'Bearer 123456|server-secret');
  const profileUrl=new URL(s.calls[2].url);
  assert.equal(profileUrl.searchParams.get('fields'),'id');
  assert.equal(profileUrl.searchParams.get('appsecret_proof'),createHmac('sha256','server-secret').update('facebook-user-token').digest('hex'));
  assert.equal(profileUrl.searchParams.get('access_token'),null);
  assert.equal(s.calls[2].options.headers.Authorization,'Bearer facebook-user-token');
  assert.ok(s.calls.every(call=>call.options.redirect==='error'));
});
test('Facebook wrong app, page tokens, expired access, malformed user IDs and mismatched profile are rejected', async () => {
  for (const debugChanges of [
    {is_valid:false},{app_id:'other-app'},{type:'PAGE'},{user_id:987654},{user_id:'abc'},
    {expires_at:999999999},{expires_at:'2000000000'},{data_access_expires_at:999999999},
  ]) {
    const s=facebookFetch({debugChanges});
    await assert.rejects(s.run(),/invalid-provider-identity/);
    assert.equal(s.calls.length,2);
  }
  for (const profileChanges of [{id:'999999'},{id:987654},{id:null},{error:{message:'hidden'}}]) {
    await assert.rejects(facebookFetch({profileChanges}).run(),/invalid-provider-identity/);
  }
  const invalidToken=facebookFetch({tokenChanges:{access_token:''}});
  await assert.rejects(invalidToken.run(),/provider-error/);
  assert.equal(invalidToken.calls.length,1);
});
