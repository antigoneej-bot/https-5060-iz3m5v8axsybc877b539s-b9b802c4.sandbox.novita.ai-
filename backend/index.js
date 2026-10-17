import * as village from './garden-village.js';
import { confirmGardenBloom } from './garden-blooms.js';
import { beginCheerDelivery, acknowledgeCheerDelivery } from './cheer-delivery.js';
import { removeAccountReservations } from './account-reservations.js';
import { hasTrustedAccount, isSignedInAccount, hasRecentAuthentication } from './account-identity.js';
export { socialAuth } from './social-auth.js';
import { randomUUID } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onRequest } from 'firebase-functions/v2/https';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { GoogleAuth } from 'google-auth-library';
import { PACKAGE, PRODUCTS, entitlement, assertOwner, tokenHash, validEnvelope, nextAccountLease, accountHash,
  isAdminEmail, validateGardenNewsInput, sanitizeReservationNote } from './policy.js';
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
  const action = req.body?.action;
  if (action === 'deleteCloudAccount') {
    if (!isSignedInAccount(identity)) {res.status(401).json({error:'authentication-required'});return;}
    if (!hasRecentAuthentication(identity)) {res.status(403).json({error:'recent-login-required'});return;}
  } else if (!hasTrustedAccount(identity)) {res.status(403).json({error:'verify-email'});return;}
  const uid = identity.uid;
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
    // ── 3단계: 공개정원 / 응원 (opt-in, read-only visits, no ranking) ──
    const villageDeps = {stamp: () => FieldValue.serverTimestamp(), timestampFromParts: (seconds, nanos) => new Timestamp(seconds, nanos)};
    const villageActions = {
      getVillageProfile: village.getVillageProfile,
      updateVillageProfile: village.updateVillageProfile,
      listNeighbors: village.listNeighbors,
      lookupNeighbor: village.lookupNeighbor,
      requestNeighbor: village.requestNeighbor,
      respondNeighbor: village.respondNeighbor,
      removeNeighbor: village.removeNeighbor,
      getNeighborGarden: village.getNeighborGarden,
      blockNeighbor: village.blockNeighbor,
      reportGarden: village.reportGarden,
      sendGardenGift: village.sendGardenGift,
    };
    if (Object.hasOwn(villageActions, action)) {
      const result = action === 'getVillageProfile'
        ? await village.getVillageProfile(db, uid, villageDeps)
        : await villageActions[action](db, uid, req.body, villageDeps);
      res.json(result); return;
    }
    if (action === 'getMyPublicGardenStatus') {
      res.json(await village.villagePublicationStatus(db, uid));return;
    }
    if (action === 'publishGarden') {
      res.json(await village.publishVillageGarden(db, uid, req.body, villageDeps));return;
    }
    if (action === 'unpublishGarden') {
      res.json(await village.unpublishVillageGarden(db, uid, villageDeps));return;
    }
    if (action === 'listPublicGardens') {
      res.json(await village.listDiscoverableGardens(db, uid, req.body));return;
    }
    if (action === 'sendPublicCheer') {
      res.json(await village.sendVillageCheer(db, uid, req.body, villageDeps));return;
    }
    if (action === 'listMyCheers') {
      res.json(await village.listVillageCheers(db, uid, req.body, villageDeps));return;
    }
    if (action === 'confirmFlowerPlanted') {
      const result = await confirmGardenBloom(db, uid, req.body.id, req.body.flowerKind, {stamp: () => FieldValue.serverTimestamp(), accountHash});
      res.json(result);return;
    }
    if (action === 'listFlowerBlooms') {
      res.json(await village.listVillageBlooms(db, uid));return;
    }
    if (action === 'claimCheer' || action === 'claimCheerV2') {
      res.json(await beginCheerDelivery(db, uid, req.body.id, {legacy: action === 'claimCheer', deviceId: req.body.deviceId}));return;
    }
    if (action === 'ackCheer') {
      res.json(await acknowledgeCheerDelivery(db, uid, req.body.id, req.body.receipt, req.body.deviceId));return;
    }
    // ── 정원소식(= 기존 "공지") 관리자 CRUD + 경량 예약 ────────────────
    // 읍일전용 조회는 모든 로그인 사용자가 할 수 있고, 작성/수정/삭제는
    // ADMIN_EMAILS에 있는 계정만 할 수 있다(서버에서 다시 검증 - 클라이언트
    // 쪼코드의 관리자 메뉴 노출 여부를 신뢰하지 않는다).
    if (action === 'listGardenNews') {
      const snap = await db.collection('gardenNews').orderBy('createdAt', 'desc').limit(50).get();
      const news = snap.docs.map(doc => {
        const d = doc.data();
        return {
          id: doc.id, title: d.title, body: d.body, emoji: d.emoji, type: d.type,
          status: d.status ?? null, period: d.period ?? null, location: d.location ?? null,
          cost: d.cost ?? null, applyUrl: d.applyUrl ?? null, capacity: d.capacity ?? null,
          reservedCount: d.reservedCount ?? 0,
          createdAt: d.createdAt?.toDate().toISOString() ?? null,
        };
      });
      res.json({news});return;
    }
    if (action === 'adminCreateGardenNews' || action === 'adminUpdateGardenNews') {
      if (identity.email_verified !== true || !isAdminEmail(identity.email)) {res.status(403).json({error:'admin-required'});return;}
      const parsed = validateGardenNewsInput(req.body.news);
      if (!parsed) {res.status(400).json({error:'invalid-news'});return;}
      if (action === 'adminCreateGardenNews') {
        const ref = db.collection('gardenNews').doc();
        await ref.set({...parsed, reservedCount: 0, createdBy: uid,
          createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp()});
        res.json({id: ref.id});return;
      }
      const id = req.body.id;
      if (typeof id !== 'string' || !id) {res.status(400).json({error:'invalid-id'});return;}
      const ref = db.doc(`gardenNews/${id}`);
      const existing = await ref.get();
      if (!existing.exists) {res.status(404).json({error:'news-not-found'});return;}
      // capacity가 줄어도 이미 예약된 인원(reservedCount)은 그대로 둔다 -
      // 관리자가 정원을 낮췄다고 기존 신청자를 자동으로 취소시키지 않는다.
      await ref.update({...parsed, updatedAt: FieldValue.serverTimestamp()});
      res.json({id});return;
    }
    if (action === 'adminDeleteGardenNews') {
      if (identity.email_verified !== true || !isAdminEmail(identity.email)) {res.status(403).json({error:'admin-required'});return;}
      const id = req.body.id;
      if (typeof id !== 'string' || !id) {res.status(400).json({error:'invalid-id'});return;}
      await db.doc(`gardenNews/${id}`).delete();
      // Clean up this news item's reservations too (bounded: admin content,
      // never attracts an unbounded crowd the way a public ranking would).
      const reservations = await db.collection('gardenNewsReservations').where('newsId','==',id).get();
      for (const doc of reservations.docs) await doc.ref.delete();
      res.json({deleted:true});return;
    }
    if (action === 'adminListGardenNewsReservations') {
      if (identity.email_verified !== true || !isAdminEmail(identity.email)) {res.status(403).json({error:'admin-required'});return;}
      const newsId = req.body.newsId;
      if (typeof newsId !== 'string' || !newsId) {res.status(400).json({error:'invalid-id'});return;}
      const snap = await db.collection('gardenNewsReservations').where('newsId','==',newsId).get();
      const reservations = snap.docs
        .map(doc => ({email: doc.data().email, note: doc.data().note ?? null,
          createdAt: doc.data().createdAt?.toDate().toISOString() ?? null}))
        .sort((a,b) => (a.createdAt ?? '').localeCompare(b.createdAt ?? ''));
      res.json({reservations});return;
    }
    if (action === 'reserveGardenNews') {
      const newsId = req.body.newsId;
      if (typeof newsId !== 'string' || !newsId) {res.status(400).json({error:'invalid-id'});return;}
      const note = sanitizeReservationNote(req.body.note);
      const newsRef = db.doc(`gardenNews/${newsId}`);
      const reservationRef = db.doc(`gardenNewsReservations/${newsId}_${uid}`);
      await db.runTransaction(async tx => {
        const [news, existingReservation] = await Promise.all([tx.get(newsRef), tx.get(reservationRef)]);
        if (!news.exists) throw new Error('news-not-found');
        if (existingReservation.exists) throw new Error('already-reserved');
        const data = news.data();
        if (data.status === 'closed') throw new Error('reservation-closed');
        if (data.capacity == null) throw new Error('reservation-not-available');
        const reservedCount = data.reservedCount ?? 0;
        if (reservedCount >= data.capacity) throw new Error('reservation-full');
        tx.set(reservationRef, {newsId, uid, email: identity.email_verified === true ? identity.email ?? null : null, note,
          createdAt: FieldValue.serverTimestamp()});
        tx.update(newsRef, {reservedCount: reservedCount + 1});
      });
      res.json({reserved:true});return;
    }
    if (action === 'cancelGardenNewsReservation') {
      const newsId = req.body.newsId;
      if (typeof newsId !== 'string' || !newsId) {res.status(400).json({error:'invalid-id'});return;}
      const newsRef = db.doc(`gardenNews/${newsId}`);
      const reservationRef = db.doc(`gardenNewsReservations/${newsId}_${uid}`);
      await db.runTransaction(async tx => {
        const [news, reservation] = await Promise.all([tx.get(newsRef), tx.get(reservationRef)]);
        if (!reservation.exists) return; // Idempotent: nothing to cancel.
        tx.delete(reservationRef);
        if (news.exists) {
          const reservedCount = Math.max(0, (news.data().reservedCount ?? 0) - 1);
          tx.update(newsRef, {reservedCount});
        }
      });
      res.json({canceled:true});return;
    }
    if (action === 'myGardenNewsReservations') {
      const snap = await db.collection('gardenNewsReservations').where('uid','==',uid).get();
      res.json({newsIds: snap.docs.map(doc => doc.data().newsId)});return;
    }
    if (action === 'deleteCloudAccount') {
      if (!hasRecentAuthentication(identity)) {res.status(403).json({error:'recent-login-required'});return;}
      await lease.ref.set({deleting:true}, {merge:true});
      await removeAccountReservations(db, uid);
      await village.removeVillageAccount(db, uid);
      await getStorage().bucket().deleteFiles({prefix:`backups/${uid}/`});
      // publicGardens lives outside users/{uid}; remove it explicitly so a
      // deleted account's garden immediately stops appearing to visitors.
      await db.doc(`publicGardens/${uid}`).delete();
      await db.recursiveDelete(db.doc(`users/${uid}`));
      // Keep only irreversible ownership tombstones; remove uid and raw token.
      const owned = await db.collection('purchaseTokens').where('uid','==',uid).get();
      for (const doc of owned.docs) await doc.ref.set({deleted:true});
      await lease.ref.set({deleted:true}, {merge:true});
      await getAuth().deleteUser(uid);
      // Only this final marker permits a social identity to create a NEW UID.
      // A partially failed deletion stays locked and never revives old records.
      await lease.ref.set({deletionCompleted:true}, {merge:true});
      res.json({deleted:true});return;
    }
    res.status(400).json({error:'unknown-action'});
  } catch (error) {
    const expected = ['purchase-owner-mismatch','purchase-migration-required','rate-limit','account-busy',
      'invalid-bloom','cheer-not-found','account-deleting','cheer-already-sent-today','news-not-found','already-reserved',
      'reservation-closed','reservation-not-available','reservation-full',
      'garden-not-found','invalid-id','invalid-garden-gift','invalid-delivery-receipt','client-update-required',
      'delivery-other-device','invalid-delivery-device', 'invalid-profile', 'invalid-invite-code',
      'neighbor-request-not-found', 'neighbor-required', 'gifts-disabled', 'invalid-report',
      'cheer-transferred', 'flower-already-planted', 'request-conflict', 'invalid-target',
      'invalid-message', 'invalid-snapshot', 'invalid-cursor', 'invalid-page-size', 'currency-gifts-unavailable'];
    const code = expected.includes(error.message) ? error.message : 'temporarily-unavailable';
    const statusCode = code === 'rate-limit' ? 429
      : ['cheer-already-sent-today','already-reserved','request-conflict','cheer-transferred','flower-already-planted'].includes(code) ? 409
      : ['news-not-found','garden-not-found','cheer-not-found','neighbor-request-not-found'].includes(code) ? 404
      : ['invalid-id','invalid-garden-gift','invalid-delivery-receipt','invalid-delivery-device','invalid-profile','invalid-invite-code','invalid-report','invalid-target','invalid-message','invalid-snapshot','invalid-cursor','invalid-page-size'].includes(code) ? 400
      : code === 'temporarily-unavailable' ? 503 : 403;
    res.status(statusCode).json({error:code});
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
