import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import * as village from '../garden-village.js';
import {confirmGardenBloom} from '../garden-blooms.js';
import {beginCheerDelivery} from '../cheer-delivery.js';
import {accountHash} from '../policy.js';
const deps = {stamp: () => '2026-10-16T11:00:00.000Z', accountHash};
const snapshot = {seedCounts: {pine: 1}, equippedDecorationIds: ['bench'], treeStageIndex: 1};
async function prepared() {
  const db = memoryDb();
  await village.publishVillageGarden(db, 'alice', {snapshot, nickname: '앨리스', visibility: 'neighbors'}, deps);
  await village.publishVillageGarden(db, 'bob', {snapshot, nickname: '보리', visibility: 'neighbors'}, deps);
  const profile = await village.getVillageProfile(db, 'bob', deps);
  await village.requestNeighbor(db, 'alice', {inviteCode: profile.inviteCode}, deps);
  await village.respondNeighbor(db, 'bob', {gardenId: 'alice', accept: true}, deps);
  return db;
}
const gift = {gardenId: 'bob', messageIndex: 0, flowerKind: 'tulip', reaction: 'heart', deliveryKind: 'gift'};

test('legacy public snapshot never opts into discovery; invitation code remains private', async () => {
  const db = memoryDb({'publicGardens/bob': {...snapshot, nickname: '보리', privateDiary: 'not exposed'}});
  assert.deepEqual(await village.listDiscoverableGardens(db, 'alice'), {gardens: [], nextCursor: null});
  const own = await village.getVillageProfile(db, 'bob', deps);
  assert.match(own.inviteCode, /^[A-F0-9]{12}$/);
  assert.equal((await village.getVillageProfile(db, 'bob', deps)).inviteCode, own.inviteCode);
  await village.updateVillageProfile(db, 'bob', {discoveryOptIn: true}, deps);
  const cards = await village.listDiscoverableGardens(db, 'alice');
  assert.equal(cards.gardens.length, 1);
  assert.equal(cards.gardens[0].inviteCode, undefined);
  assert.equal(cards.gardens[0].privateDiary, undefined);
  const looked = await village.lookupNeighbor(db, 'alice', {inviteCode: own.inviteCode});
  assert.equal(looked.nickname, '보리');
  assert.equal(looked.seedCounts, undefined);
});

test('two accounts connect by invite, accept only incoming, visit neighbors scope, remove symmetrically', async () => {
  const db = memoryDb();
  await village.publishVillageGarden(db, 'bob', {snapshot, nickname: '보리', visibility: 'neighbors'}, deps);
  const own = await village.getVillageProfile(db, 'bob', deps);
  await assert.rejects(village.getNeighborGarden(db, 'alice', {gardenId: 'bob'}), /garden-not-found/);
  await assert.rejects(village.requestNeighbor(db, 'alice', {gardenId: 'bob'}, deps), /garden-not-found/);
  await village.requestNeighbor(db, 'alice', {inviteCode: own.inviteCode}, deps);
  await village.requestNeighbor(db, 'alice', {inviteCode: own.inviteCode}, deps);
  assert.equal((await village.listNeighbors(db, 'bob')).incoming.length, 1);
  await assert.rejects(village.respondNeighbor(db, 'alice', {gardenId: 'bob', accept: true}, deps), /neighbor-request-not-found/);
  await village.respondNeighbor(db, 'bob', {gardenId: 'alice', accept: true}, deps);
  await village.respondNeighbor(db, 'bob', {gardenId: 'alice', accept: true}, deps);
  assert.equal((await village.getNeighborGarden(db, 'alice', {gardenId: 'bob'})).garden.nickname, '보리');
  await village.removeNeighbor(db, 'alice', {gardenId: 'bob'});
  assert.equal((await village.listNeighbors(db, 'bob')).neighbors.length, 0);
  await assert.rejects(village.getNeighborGarden(db, 'alice', {gardenId: 'bob'}), /garden-not-found/);
});

test('private scope and discovery preference cannot be weakened by legacy publication or stranger block lookup', async () => {
  const db = await prepared();
  await village.updateVillageProfile(db, 'bob', {visibility: 'private', discoveryOptIn: true}, deps);
  await village.publishVillageGarden(db, 'bob', {snapshot, nickname: '비밀'}, deps);
  const profile = await village.getVillageProfile(db, 'bob', deps);
  assert.equal(profile.visibility, 'private');
  assert.equal(profile.discoveryOptIn, false);
  assert.equal((await village.villagePublicationStatus(db, 'bob')).published, false);
  await assert.rejects(village.getNeighborGarden(db, 'alice', {gardenId: 'bob'}), /garden-not-found/);
  await village.blockNeighbor(db, 'stranger', {gardenId: 'bob', blocked: true}, deps);
  assert.equal((await village.listNeighbors(db, 'stranger')).blocked[0].nickname, null);
});

test('fresh flower and reaction sends are free, daily idempotent, preserve sender/date, respect receiving preference', async () => {
  const db = await prepared();
  await village.sendVillageCheer(db, 'alice', gift, deps);
  await village.sendVillageCheer(db, 'alice', gift, deps);
  let inbox = await village.listVillageCheers(db, 'bob');
  assert.equal(inbox.cheers.length, 1);
  assert.equal(inbox.cheers[0].senderNickname, '앨리스');
  assert.equal(inbox.cheers[0].senderGardenId, 'alice');
  assert.equal(inbox.cheers[0].createdAt, deps.stamp());
  await assert.rejects(village.sendVillageCheer(db, 'alice', {...gift, flowerKind: 'daisy'}, deps), /cheer-already-sent-today/);
  await village.updateVillageProfile(db, 'bob', {receiveGifts: false}, deps);
  await assert.rejects(village.sendVillageCheer(db, 'alice', gift, {...deps, now: Date.now() + 86400000}), /gifts-disabled/);
  await village.sendVillageCheer(db, 'alice', {...gift, deliveryKind: 'cheer'}, deps);
  inbox = await village.listVillageCheers(db, 'bob');
  const cheer = inbox.cheers.find(value => value.deliveryKind === 'cheer');
  assert.equal(cheer.flowerKind, null);
  await assert.rejects(confirmGardenBloom(db, 'bob', cheer.id, 'daisy', deps), /invalid-bloom/);
});

test('bilateral blocks cover discovery, direct visits, codes, old sends, inbox, claims and bloom confirmations', async () => {
  const db = await prepared();
  await village.sendVillageCheer(db, 'alice', gift, deps);
  const received = (await village.listVillageCheers(db, 'bob')).cheers[0];
  const code = (await village.getVillageProfile(db, 'bob', deps)).inviteCode;
  await village.updateVillageProfile(db, 'bob', {visibility: 'public', discoveryOptIn: true}, deps);
  await village.blockNeighbor(db, 'bob', {gardenId: 'alice', blocked: true}, deps);
  assert.equal((await village.listDiscoverableGardens(db, 'alice')).gardens.length, 0);
  assert.equal((await village.listNeighbors(db, 'alice')).neighbors.length, 0);
  assert.equal((await village.listVillageCheers(db, 'bob')).cheers.length, 0);
  await assert.rejects(village.lookupNeighbor(db, 'alice', {inviteCode: code}), /garden-not-found/);
  await assert.rejects(village.getNeighborGarden(db, 'alice', {gardenId: 'bob'}), /garden-not-found/);
  await assert.rejects(village.sendVillageCheer(db, 'alice', {...gift, deliveryKind: 'cheer'}, deps), /garden-not-found/);
  await assert.rejects(beginCheerDelivery(db, 'bob', received.id), /cheer-not-found/);
  await assert.rejects(confirmGardenBloom(db, 'bob', received.id, 'tulip', deps), /cheer-not-found/);
});

test('owned unplanted gift transfers once across retry and request IDs; retired ID blocks later claims/planting', async () => {
  const db = await prepared();
  db.rows.set('users/alice/receivedCheers/source', {flowerKind: 'lavender', senderId: 'carol', giftLightEssence: 0, createdAt: deps.stamp()});
  const request = {gardenId: 'bob', sourceCheerId: 'source', requestId: 'request-1234567890'};
  const first = await village.sendGardenGift(db, 'alice', request, deps);
  assert.deepEqual(await village.sendGardenGift(db, 'alice', request, deps), first);
  assert.equal((await village.listVillageCheers(db, 'bob')).cheers.length, 1);
  assert.deepEqual((await village.listVillageCheers(db, 'alice')).retiredIds, ['source']);
  await assert.rejects(village.sendGardenGift(db, 'alice', {...request, requestId: 'different-request-123'}, deps), /cheer-transferred/);
  await assert.rejects(village.sendGardenGift(db, 'alice', {...request, sourceCheerId: 'another'}, deps), /request-conflict/);
  await assert.rejects(confirmGardenBloom(db, 'alice', 'source', 'lavender', deps), /cheer-transferred/);
  await assert.rejects(beginCheerDelivery(db, 'alice', 'source'), /cheer-transferred/);
  await assert.rejects(village.sendGardenGift(db, 'carol', request, deps), /neighbor-required/);
});

test('planting and transfer race commits exactly one outcome; forged flower choice is rejected', async () => {
  for (const transferFirst of [true, false]) {
    const db = await prepared();
    db.rows.set('users/alice/receivedCheers/source', {flowerKind: 'tulip', giftLightEssence: 0});
    await assert.rejects(confirmGardenBloom(db, 'alice', 'source', 'lavender', deps), /invalid-bloom/);
    const transfer = () => village.sendGardenGift(db, 'alice', {gardenId: 'bob', sourceCheerId: 'source', requestId: 'request-1234567890'}, deps);
    const plant = () => confirmGardenBloom(db, 'alice', 'source', 'tulip', deps);
    const results = await Promise.allSettled(transferFirst ? [transfer(), plant()] : [plant(), transfer()]);
    assert.equal(results.filter(value => value.status === 'fulfilled').length, 1);
    const source = db.rows.get('users/alice/receivedCheers/source');
    assert.notEqual(source.transferred === true, source.bloomConfirmed === true);
  }
});

test('account cleanup removes codes, neighbors, moderation and external attribution without deleting recipient gifts', async () => {
  const db = await prepared();
  const code = (await village.getVillageProfile(db, 'alice', deps)).inviteCode;
  await village.sendVillageCheer(db, 'alice', gift, deps);
  await village.reportGarden(db, 'bob', {gardenId: 'alice', reason: 'spam'}, deps);
  await assert.rejects(village.reportGarden(db, 'bob', {gardenId: 'alice', reason: 'private diary text'}, deps), /invalid-report/);
  await village.removeVillageAccount(db, 'alice');
  assert.equal(db.rows.has(`villageInviteCodes/${code}`), false);
  assert.equal(db.rows.has('users/bob/neighbors/alice'), false);
  assert.equal([...db.rows.keys()].some(key => key.startsWith('villageReports/')), false);
  const giftRecord = [...db.rows.entries()].find(([key]) => key.startsWith('users/bob/receivedCheers/'))[1];
  assert.equal(giftRecord.senderId, null);
  assert.equal(giftRecord.senderNickname, null);
  assert.equal(giftRecord.flowerKind, 'tulip');
});

test('deletion tombstone rejects new requests, sends and transfers without recreating target data', async () => {
  const db = await prepared();
  const code = (await village.getVillageProfile(db, 'bob', deps)).inviteCode;
  db.rows.set(`accountLocks/${accountHash('bob')}`, {deleting: true});
  await assert.rejects(village.lookupNeighbor(db, 'alice', {inviteCode: code}), /garden-not-found/);
  await assert.rejects(village.sendVillageCheer(db, 'alice', gift, deps), /garden-not-found/);
  await assert.rejects(village.requestNeighbor(db, 'alice', {inviteCode: code}, deps), /garden-not-found/);
  assert.equal([...db.rows.keys()].some(key => key.startsWith('users/bob/receivedCheers/')), false);
});


test('a pre-village lost gift response remains idempotent after upgrade', async () => {
  const db = await prepared();
  const now = Date.now();
  const date = new Date(now + 9 * 3600000).toISOString().slice(0, 10);
  db.rows.set('cheerSentLog/alice_bob', {date, fingerprint: JSON.stringify([0, 'tulip', 'heart'])});
  assert.deepEqual(await village.sendVillageCheer(db, 'alice', gift, {...deps, now}), {sent: true});
  assert.equal((await village.listVillageCheers(db, 'bob')).cheers.length, 0);
  await assert.rejects(village.sendVillageCheer(db, 'alice', {...gift, flowerKind: 'daisy'}, {...deps, now}), /cheer-already-sent-today/);
});
