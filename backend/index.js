import { randomUUID } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onRequest } from 'firebase-functions/v2/https';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { GoogleAuth } from 'google-auth-library';
import { PACKAGE, PRODUCTS, entitlement, assertOwner, tokenHash, validEnvelope, nextAccountLease, accountHash } from './policy.js';
initializeApp();
const db = getFirestore();
const publisher = new GoogleAuth({scopes:['https://www.googleapis.com/auth/androidpublisher']});
async function acquireAccountLease(uid, action) {
  const ref = db.doc(`accountLocks/${accountHash(uid)}`);
  const owner = randomUUID();
  await db.runTransaction(async tx => {
    const previous = await tx.get(ref);
    tx.set(ref, nextAccountLease(previous.data(), action, owner));
  });
  return {
    ref,
    release: async () => db.runTransaction(async tx => {
      const current = await tx.get(ref);
      if (current.data()?.owner === owner) {
        tx.update(ref, {owner: FieldValue.delete(), until: FieldValue.delete()});
      }
    }),
  };
}
async function lookup(token) {
  const client = await publisher.getClient();
  const response = await client.request({url: `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`});
  return response.data;
}
async function acknowledge(token, productId, purchase) {
  if (purchase.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_PENDING') return;
  const client = await publisher.getClient();
  await client.request({method:'POST', url:`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/purchases/subscriptions/${productId}/tokens/${encodeURIComponent(token)}:acknowledge`, data:{}});
}
async function verify(uid, token) {
  const ref = db.doc(`purchaseTokens/${tokenHash(token)}`);
  const purchase = await lookup(token);
  // Bind transactionally so two accounts cannot claim the same purchase.
  await db.runTransaction(async tx => {
    const existing = await tx.get(ref);
    if (existing.data()?.deleted) throw new Error('purchase-owner-mismatch');
    assertOwner(purchase, uid, existing.data()?.uid);
    tx.set(ref, {uid, token, updatedAt: FieldValue.serverTimestamp()}, {merge:true});
  });
  const result = entitlement(purchase);
  if (result.active) await acknowledge(token, result.productId, purchase);
  await db.doc(`users/${uid}/entitlements/${tokenHash(token)}`).set(result);
  return result;
}
async function status(uid, refresh = false) {
  if (refresh) {
    const tokens = await db.collection('purchaseTokens').where('uid','==',uid).get();
    // Failure propagates: never replace known status with a fabricated expiry.
    for (const doc of tokens.docs) {
      try { await verify(uid, doc.data().token); }
      catch (error) {
        if (error.response?.status !== 410) throw error;
        await db.doc(`users/${uid}/entitlements/${doc.id}`).set({active:false, expiresAt:null, productId:null, checkedAt:new Date().toISOString()});
      }
    }
  }
  const records = await db.collection(`users/${uid}/entitlements`).get();
  const now = Date.now();
  const active = records.docs.map(d => d.data()).filter(e => e.active && Date.parse(e.expiresAt) > now)
    .sort((a,b) => Date.parse(b.expiresAt)-Date.parse(a.expiresAt));
  return active[0] ?? {active:false, state: records.empty ? 'free' : 'expired', expiresAt:null, productId:null, checkedAt:new Date(now).toISOString()};
}
async function rateLimit(uid, action) {
  const ref = db.doc(`users/${uid}/limits/${action}`);
  await db.runTransaction(async tx => {
    const doc = await tx.get(ref); const old = doc.data() ?? {}; const now = Date.now();
    const window = now - (old.start ?? 0) < 60000;
    const count = window ? (old.count ?? 0) + 1 : 1;
    if (count > (action === 'backup' ? 2 : 20)) throw new Error('rate-limit');
    tx.set(ref,{start:window?old.start:now,count});
  });
}
export const gardenApi = onRequest({region:'asia-northeast3', maxInstances:3, timeoutSeconds:60, memory:'512MiB'}, async (req,res) => {
  res.set('Cache-Control','no-store');
  if (req.method !== 'POST') {res.status(405).json({error:'method-not-allowed'}); return;}
  let identity;
  try {
    const bearer = req.get('Authorization') ?? '';
    if (!bearer.startsWith('Bearer ')) throw new Error();
    identity = await getAuth().verifyIdToken(bearer.slice(7), true);
    const attestation = await getAppCheck().verifyToken(req.get('X-Firebase-AppCheck') ?? '');
    if (!process.env.GARDEN_ANDROID_APP_ID || attestation.appId !== process.env.GARDEN_ANDROID_APP_ID) throw new Error();
  } catch {res.status(401).json({error:'authentication-required'});return;}
  if (!identity.email_verified) {res.status(403).json({error:'verify-email'});return;}
  const uid = identity.uid;
  const action = req.body?.action;
  let lease;
  try {
    lease = await acquireAccountLease(uid, action);
    if (req.rawBody.length > 8 * 1024 * 1024) {res.status(413).json({error:'too-large'});return;}
    await rateLimit(uid, action === 'backup' ? 'backup' : 'api');
    if (action === 'verify') {
      const token = req.body.token;
      if (typeof token !== 'string' || token.length < 8 || token.length > 4096) {res.status(400).json({error:'invalid-token'});return;}
      await verify(uid, token); res.json(await status(uid)); return;
    }
    if (action === 'status') {res.json(await status(uid,true));return;}
    if (action === 'backup') {
      if (!(await status(uid,true)).active) {res.status(403).json({error:'subscription-required'});return;}
      const envelope = req.body.envelope;
      if (!validEnvelope(envelope)) {res.status(400).json({error:'invalid-backup'});return;}
      const id = `${Date.now()}-${randomUUID()}`;
      const object = getStorage().bucket().file(`backups/${uid}/${id}.json`);
      await object.save(JSON.stringify(envelope), {resumable:false, contentType:'application/json'});
      await db.doc(`users/${uid}/backups/${id}`).set({createdAt:FieldValue.serverTimestamp(), id});
      // Keep ten complete snapshots, not only the newest copy.
      const versions = await db.collection(`users/${uid}/backups`).orderBy('createdAt','desc').get();
      for (const doc of versions.docs.slice(10)) {
        await getStorage().bucket().file(`backups/${uid}/${doc.id}.json`).delete({ignoreNotFound:true});
        await doc.ref.delete();
      }
      res.json({id, savedAt:new Date().toISOString()});return;
    }
    if (action === 'listBackups') {
      // Restoration is allowed even after subscription expires.
      const versions = await db.collection(`users/${uid}/backups`).orderBy('createdAt','desc').limit(10).get();
      res.json({versions:versions.docs.map(d=>({id:d.id, createdAt:d.data().createdAt?.toDate().toISOString()}))});return;
    }
    if (action === 'downloadBackup') {
      const id = req.body.id;
      if (typeof id !== 'string' || !/^[0-9]+-[a-f0-9-]{36}$/.test(id)) {res.status(400).json({error:'invalid-id'});return;}
      const [bytes] = await getStorage().bucket().file(`backups/${uid}/${id}.json`).download();
      res.json({envelope:JSON.parse(bytes.toString('utf8'))});return;
    }
    if (action === 'deleteCloudAccount') {
      if (Date.now()/1000 - identity.auth_time > 300) {res.status(403).json({error:'recent-login-required'});return;}
      await lease.ref.set({deleting:true}, {merge:true});
      await getStorage().bucket().deleteFiles({prefix:`backups/${uid}/`});
      await db.recursiveDelete(db.doc(`users/${uid}`));
      // Keep only irreversible ownership tombstones; remove uid and raw token.
      const owned = await db.collection('purchaseTokens').where('uid','==',uid).get();
      for (const doc of owned.docs) await doc.ref.set({deleted:true});
      await lease.ref.set({deleted:true}, {merge:true});
      await getAuth().deleteUser(uid);
      res.json({deleted:true});return;
    }
    res.status(400).json({error:'unknown-action'});
  } catch (error) {
    const expected = ['purchase-owner-mismatch','purchase-migration-required','rate-limit','account-busy','account-deleting'];
    const code = expected.includes(error.message) ? error.message : 'temporarily-unavailable';
    res.status(code === 'rate-limit' ? 429 : code === 'temporarily-unavailable' ? 503 : 403).json({error:code});
  } finally {
    if (lease) await lease.release().catch(() => {});
  }
});

// Configure Play Console to publish RTDN to this topic. Payload is a signal;
// always fetch the current purchase from Google, never trust notification state.
export const playNotifications = onMessagePublished({topic:'play-rtdn',region:'asia-northeast3',retry:true,timeoutSeconds:60}, async event => {
  const notification = event.data.message.json;
  if (notification?.packageName !== PACKAGE) return;
  const token = notification.subscriptionNotification?.purchaseToken;
  if (typeof token !== 'string') return;
  const doc = await db.doc(`purchaseTokens/${tokenHash(token)}`).get();
  if (!doc.exists || doc.data().deleted) return;
  const uid = doc.data().uid;
  let lease;
  try {
    lease = await acquireAccountLease(uid, 'rtdn');
    try { await getAuth().getUser(uid); } catch (error) {
      if (error.code === 'auth/user-not-found') return;
      throw error;
    }
    try { await verify(uid,token); }
    catch (error) {
      if (error.response?.status !== 410) throw error;
      await db.doc(`users/${uid}/entitlements/${tokenHash(token)}`).set({active:false, expiresAt:null, productId:null, checkedAt:new Date().toISOString()});
    }
  } catch (error) {
    if (error.message !== 'account-deleting') throw error;
  } finally {
    if (lease) await lease.release();
  }
});
