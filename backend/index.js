import {enforceCommunityPolicy, acceptCommunityPolicy} from './community-policy.js';
import {subscriptionNotificationToken} from './play-notification.js';
import {requireBackupStorage} from './backup-storage.js';
import {memoryCardActions, removeMemoryCards} from './memory-cards.js';
import {premiumFeatureAccess} from './premium-test-access.js';
import {orchardActions} from './orchard.js';
import {catVisitActions, removeCatVisits} from './cat-visits.js';
import {keepBackupIds} from './backup-retention.js';
import {setPushDevice, deliverPushJob, removePushDevices, listGardenUpdates} from './push-notifications.js';
import {getMessaging} from 'firebase-admin/messaging';
import {onDocumentCreated} from 'firebase-functions/v2/firestore';
import { handleGardenNewsAction, gardenNewsActions, GardenEventError } from './garden-events.js';
import { storeVerifiedPurchase } from './purchase-replacement.js';
import { isGardenNewsAdmin } from './garden-news-admin.js';
import * as village from './garden-village.js';
import {discoveryActions} from './garden-discovery.js';
import * as sharedTrees from './shared-trees.js';
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
  const purchase = await lookup(token);
  const result = await storeVerifiedPurchase(db, uid, token, purchase, () => FieldValue.serverTimestamp());
  if (result.active) await acknowledge(token, result.productId, purchase);
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
async function featurePremium(uid) {
  // Match the existing app administrator benefit, using server-trusted identity.
  const user = await getAuth().getUser(uid);
  if (user.emailVerified === true && isAdminEmail(user.email)) return true;
  return premiumFeatureAccess(uid, {verifiedStatus: owner => status(owner, true)});
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
    if (action === 'acceptCommunityPolicy') {res.json(await acceptCommunityPolicy(db, uid, req.body.version, () => FieldValue.serverTimestamp()));return;}
    await enforceCommunityPolicy(db, uid, action);
    if (action === 'listGardenUpdates') {res.json(await listGardenUpdates(db, uid));return;}
    if (action === 'setPushDevice') {res.json(await setPushDevice(db, uid, req.body));return;}
    if (action === 'verify') {
      const token = req.body.token;
      if (typeof token !== 'string' || token.length < 8 || token.length > 4096) {res.status(400).json({error:'invalid-token'});return;}
      await verify(uid, token); res.json(await status(uid)); return;
    }
    if (action === 'status') {res.json(await status(uid,true));return;}
    if (action === 'backup') {
      if (!(await featurePremium(uid))) {res.status(403).json({error:'subscription-required'});return;}
      const envelope = req.body.envelope;
      if (!validEnvelope(envelope)) {res.status(400).json({error:'invalid-backup'});return;}
      const id = `${Date.now()}-${randomUUID()}`;
      const backupBucket = getStorage().bucket();
      const object = backupBucket.file(`backups/${uid}/${id}.json`);
      await object.save(JSON.stringify(envelope), {resumable:false, contentType:'application/json'});
      await db.doc(`users/${uid}/backups/${id}`).set({createdAt:FieldValue.serverTimestamp(), id});
      // Keep ten complete snapshots, not only the newest copy.
      const versions = await db.collection(`users/${uid}/backups`).orderBy('createdAt','desc').get();
      const retained = keepBackupIds(versions.docs.map(doc => ({id: doc.id, day: doc.data().createdAt?.toDate().toISOString().slice(0,10)})));
      for (const doc of versions.docs.filter(doc => !retained.has(doc.id))) {
        await backupBucket.file(`backups/${uid}/${doc.id}.json`).delete({ignoreNotFound:true});
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
      const backupBucket = getStorage().bucket();
      const [bytes] = await backupBucket.file(`backups/${uid}/${id}.json`).download();
      res.json({envelope:JSON.parse(bytes.toString('utf8'))});return;
    }
    // ── 3단계: 공개정원 / 응원 (opt-in, read-only visits, no ranking) ──
    const villageDeps = {stamp: () => FieldValue.serverTimestamp(), timestampFromParts: (seconds, nanos) => new Timestamp(seconds, nanos),
      accountExists: async target => {
        try {return !(await getAuth().getUser(target)).disabled;}
        catch (error) {if (error.code === 'auth/user-not-found') return false; throw error;}
      }};
    if (Object.hasOwn(sharedTrees.sharedTreeActions, action)) {
      res.json(await sharedTrees.sharedTreeActions[action](db, uid, req.body, {
        ...villageDeps,
        hasActiveSubscription: featurePremium,
      }));
      return;
    }
    const villageActions = {
      ...discoveryActions,
      ...catVisitActions,
      ...orchardActions,
      ...memoryCardActions,
      getVillageProfile: village.getVillageProfile,
      getVillageEntry: village.getVillageEntry,
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
      listSentGardenGifts: village.listSentGardenGifts,
    };
    if (Object.hasOwn(orchardActions, action) && !(await featurePremium(uid))) {
      res.status(403).json({error:'subscription-required'});return;
    }
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
    // News and event bookings share the existing authenticated API boundary.
    if (gardenNewsActions.has(action)) {
      try {
        res.json(await handleGardenNewsAction(db, uid, identity, action, req.body,
          {stamp: () => FieldValue.serverTimestamp()}));
      } catch (error) {
        if (error instanceof GardenEventError) {res.status(error.status).json({error: error.message});}
        else throw error;
      }
      return;
    }
    if (action === 'deleteCloudAccount') {
      if (!hasRecentAuthentication(identity)) {res.status(403).json({error:'recent-login-required'});return;}
      // Fail before marking deletion or removing any private/community records.
      const backupBucket = await requireBackupStorage(getStorage(), uid);
      await lease.ref.set({deleting:true}, {merge:true});
      await removeAccountReservations(db, uid);
      await sharedTrees.removeSharedTreeAccount(db, uid);
      await removeMemoryCards(db, uid);
      await removeCatVisits(db, uid);
      await village.removeVillageAccount(db, uid);
      await backupBucket.deleteFiles({prefix:`backups/${uid}/`});
      // publicGardens lives outside users/{uid}; remove it explicitly so a
      // deleted account's garden immediately stops appearing to visitors.
      await db.doc(`publicGardens/${uid}`).delete();
      await db.doc(`gardenDiscovery/${uid}`).delete();
      await removePushDevices(db, uid);
      await db.recursiveDelete(db.doc(`users/${uid}`));
      // Keep only irreversible ownership tombstones; remove uid and raw token.
      const owned = await db.collection('purchaseTokens').where('uid','==',uid).get();
      for (const doc of owned.docs) await doc.ref.set({deleted:true});
      // Generation + hashed identity key are sufficient for safe re-registration.
      // Drop the redundant UID only for the account explicitly being deleted.
      const socialLinks = await db.collection('socialAuthIdentities').where('uid','==',uid).get();
      for (const doc of socialLinks.docs) await doc.ref.update({uid:FieldValue.delete()});
      await lease.ref.set({deleted:true}, {merge:true});
      await getAuth().deleteUser(uid);
      // Only this final marker permits a social identity to create a NEW UID.
      // A partially failed deletion stays locked and never revives old records.
      await lease.ref.set({deletionCompleted:true}, {merge:true});
      res.json({deleted:true});return;
    }
    res.status(400).json({error:'unknown-action'});
  } catch (error) {
    const expected = ['favorites-limit','community-consent-required','community-suspended','invalid-card','card-stock','card-trade-limit','card-trade-missing','card-trade-expired','invalid-orchard','orchard-owned','orchard-coins','orchard-watered','orchard-not-ready','orchard-stock','orchard-full','invalid-cat-visit','cat-visit-unavailable','cat-invite-daily-limit','purchase-owner-mismatch','purchase-migration-required','rate-limit','account-busy',
      'invalid-bloom','cheer-not-found','account-deleting','cheer-already-sent-today','news-not-found','already-reserved',
      'reservation-closed','reservation-not-available','reservation-full',
      'garden-not-found','invalid-id','invalid-garden-gift','invalid-delivery-receipt','client-update-required',
      'delivery-other-device','invalid-delivery-device', 'invalid-profile', 'invalid-invite-code',
      'neighbor-request-not-found', 'neighbor-required', 'gifts-disabled', 'invalid-report',
      'cheer-transferred', 'flower-already-planted', 'request-conflict', 'invalid-target',
      'invalid-message', 'invalid-snapshot', 'invalid-cursor', 'invalid-page-size', 'currency-gifts-unavailable',
      'shared-tree-not-found', 'shared-tree-invitation-required', 'shared-tree-note-limit',
      'invalid-shared-tree', 'invalid-shared-tree-note', 'subscription-required'];
    const code = error.message === 'backup-storage-unavailable' ? error.message
      : expected.includes(error.message) ? error.message : 'temporarily-unavailable';
    const statusCode = code === 'rate-limit' ? 429
      : ['favorites-limit','cheer-already-sent-today','already-reserved','request-conflict','cheer-transferred','flower-already-planted'].includes(code) ? 409
      : ['news-not-found','garden-not-found','cheer-not-found','neighbor-request-not-found','shared-tree-not-found'].includes(code) ? 404
      : ['invalid-id','invalid-garden-gift','invalid-delivery-receipt','invalid-delivery-device','invalid-profile','invalid-invite-code','invalid-report','invalid-target','invalid-message','invalid-snapshot','invalid-cursor','invalid-page-size','invalid-shared-tree','invalid-shared-tree-note'].includes(code) ? 400
      : ['temporarily-unavailable','backup-storage-unavailable'].includes(code) ? 503 : 403;
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
  const token = subscriptionNotificationToken(notification, PACKAGE);
  if (!token) return;
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

// BEGIN MINDNYANG_RTDN_CLOUDEVENT_V3
// Explicit registration keeps the Firebase v2 CloudEvent envelope intact even
// when the deployment launcher defaults to the legacy event signature.
import { cloudEvent as registerMindnyangCloudEvent } from '@google-cloud/functions-framework';
registerMindnyangCloudEvent('playNotifications', playNotifications);
// END MINDNYANG_RTDN_CLOUDEVENT_V3

export const gardenPush = onDocumentCreated({document: 'gardenPushJobs/{jobId}', region: 'asia-northeast3', retry: true, maxInstances: 3, timeoutSeconds: 60}, async event => {
  await deliverPushJob(db, event.params.jobId, getMessaging());
});

registerMindnyangCloudEvent('gardenPush', gardenPush);
