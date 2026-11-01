import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {COMMUNITY_VERSION, enforceCommunityPolicy, acceptCommunityPolicy, resolveGardenReport, restoreCommunityAccess} from '../community-policy.js';
import {subscriptionNotificationToken} from '../play-notification.js';
const stamp = () => '2026-10-31T00:00:00Z';
test('consent is account scoped, versioned, preserves suspension; private and deletion routes remain available', async () => {
  const db=memoryDb();
  await assert.rejects(enforceCommunityPolicy(db,'a','publishGarden'), /consent-required/);
  await acceptCommunityPolicy(db,'a',COMMUNITY_VERSION,stamp);
  await enforceCommunityPolicy(db,'a','publishGarden');
  await assert.rejects(enforceCommunityPolicy(db,'b','addSharedTreeNote'), /consent-required/);
  await assert.rejects(acceptCommunityPolicy(db,'a','old',stamp), /consent-required/);
  await db.doc('users/a/settings/community').set({suspended:true},{merge:true});
  await acceptCommunityPolicy(db,'a',COMMUNITY_VERSION,stamp);
  await assert.rejects(enforceCommunityPolicy(db,'a','publishGarden'), /suspended/);
  for(const action of ['backup','deleteCloudAccount','unpublishGarden','reportGarden','deleteSharedTreeNote']) await enforceCommunityPolicy(db,'a',action);
});

test('legacy private access does not even read community state while every protected write still requires explicit acceptance', async () => {
  const unavailableCommunityStore = {doc() {throw new Error('private-access-must-not-depend-on-community');}};
  for (const action of ['status','verify','backup','listBackups','downloadBackup','deleteCloudAccount']) {
    await enforceCommunityPolicy(unavailableCommunityStore,'old-client',action);
  }
  const db = memoryDb({'users/old-client/private/journal':{text:'retain'}});
  for (const action of ['publishGarden','updateVillageProfile','createSharedTree','addSharedTreeNote',
    'inviteCatVisit','respondCatVisit','requestNeighbor','sendPublicCheer','sendGardenGift',
    'setCardDisplay','offerCardTrade']) {
    await assert.rejects(enforceCommunityPolicy(db,'old-client',action),/community-consent-required/);
  }
  assert.equal(db.rows.has('users/old-client/settings/community'),false);
  assert.equal(db.rows.get('users/old-client/private/journal').text,'retain');
});
test('moderation atomically hides public appearance, retains private records, resolves once', async () => {
  const id='a'.repeat(64), db=memoryDb({[`villageReports/${id}`]:{targetId:'a',state:'pending'},
    'publicGardens/a':{nickname:'x'},'users/a/private/journal':{text:'retain'}});
  await resolveGardenReport(db,id,'suspend','operator',stamp);
  assert.equal(db.rows.has('publicGardens/a'),false);
  assert.equal(db.rows.get('users/a/private/journal').text,'retain');
  assert.equal(db.rows.get('villageProfiles/a').discoveryOptIn,false);
  await assert.rejects(enforceCommunityPolicy(db,'a','addSharedTreeNote'), /suspended/);
  assert.deepEqual(await resolveGardenReport(db,id,'dismiss','operator',stamp),{alreadyResolved:true});
  await assert.rejects(resolveGardenReport(db,'../x','hide','operator',stamp), /invalid-moderation/);
  await restoreCommunityAccess(db,'a','operator',stamp);
  assert.equal(db.rows.get('users/a/settings/community').suspended,false);
  assert.equal(db.rows.has('publicGardens/a'),false);
  await assert.rejects(enforceCommunityPolicy(db,'a','publishGarden'), /consent-required/);
});
test('RTDN supports voided subscriptions, ignores other packages, one-time products and malformed tokens', () => {
  const pkg='com.mysticcat.journal', token='valid-purchase-token';
  assert.equal(subscriptionNotificationToken({packageName:pkg,voidedPurchaseNotification:{productType:1,purchaseToken:token}},pkg),token);
  assert.equal(subscriptionNotificationToken({packageName:pkg,subscriptionNotification:{purchaseToken:token}},pkg),token);
  for(const n of [{packageName:'other',subscriptionNotification:{purchaseToken:token}},
    {packageName:pkg,voidedPurchaseNotification:{productType:2,purchaseToken:token}},
    {packageName:pkg,subscriptionNotification:{purchaseToken:{}}}]) assert.equal(subscriptionNotificationToken(n,pkg),null);
});
