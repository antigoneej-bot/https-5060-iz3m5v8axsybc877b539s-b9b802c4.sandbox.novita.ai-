import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {accountHash} from '../policy.js';
import {listDiscoverableGardens, listVillageCheers, publishVillageGarden, villagePublicationStatus} from '../garden-village.js';

const snapshot = {seedCounts: {pine: 1}, equippedDecorationIds: ['bench'], treeStageIndex: 1};
const iso = '2026-10-16T11:00:00.000Z';
const deps = {stamp: () => iso};
class Timestamp {
  constructor(seconds, nanoseconds) {this.seconds = seconds; this.nanoseconds = nanoseconds;}
  toDate() {return new Date(this.seconds * 1000 + this.nanoseconds / 1000000);}
}
const timeDeps = {timestampFromParts: (seconds, nanos) => new Timestamp(seconds, nanos)};
const id = n => `item-${String(n).padStart(3, '0')}`;
function addGarden(db, target, settings = {}) {
  db.rows.set(`villageProfiles/${target}`, {visibility: 'public', discoveryOptIn: true, ...settings});
  db.rows.set(`publicGardens/${target}`, {...snapshot, nickname: target, privateDiary: 'must not leak'});
}
function addCheer(db, n, data = {}) {
  db.rows.set(`users/alice/receivedCheers/${id(n)}`, {createdAt: iso, claimed: true, flowerKind: 'tulip', ...data});
}

test('discovery pages reach beyond 80 candidates without repetition and exhaust exactly', async () => {
  const db = memoryDb();
  for (let n = 0; n < 103; n++) addGarden(db, id(n));
  const seen = [], cursors = new Set();
  let cursor = null;
  do {
    const page = await listDiscoverableGardens(db, 'alice', {cursor, pageSize: 12});
    assert.ok(page.gardens.length <= 12);
    for (const garden of page.gardens) {
      assert.equal(garden.privateDiary, undefined);
      assert.equal(garden.inviteCode, undefined);
      seen.push(garden.gardenId);
    }
    cursor = page.nextCursor;
    if (cursor) {assert.ok(!cursors.has(cursor)); cursors.add(cursor);}
  } while (cursor);
  assert.deepEqual(seen, Array.from({length: 103}, (_, n) => id(n)));
});

test('an entirely hidden discovery page advances, rechecks both block directions and current privacy', async () => {
  const db = memoryDb();
  for (let n = 0; n < 85; n++) {
    addGarden(db, id(n));
    if (n < 40) db.rows.set(`users/alice/blockedNeighbors/${id(n)}`, {});
    else if (n < 80) db.rows.set(`users/${id(n)}/blockedNeighbors/alice`, {});
  }
  const first = await listDiscoverableGardens(db, 'alice');
  assert.deepEqual(first.gardens, []);
  assert.equal(typeof first.nextCursor, 'string');
  db.rows.delete(`villageProfiles/${id(79)}`); // Seeking does not depend on the cursor document surviving.
  db.rows.get(`villageProfiles/${id(80)}`).visibility = 'neighbors';
  db.rows.get(`villageProfiles/${id(81)}`).discoveryOptIn = false;
  db.rows.set(`accountLocks/${accountHash(id(82))}`, {deleting: true});
  const next = await listDiscoverableGardens(db, 'alice', {cursor: first.nextCursor});
  assert.deepEqual(next.gardens.map(g => g.gardenId), [id(83), id(84)]);
  assert.equal(next.nextCursor, null);
});

test('inbox pages recover old claimed and planted flowers with stable equal-time ID tie-breaks', async () => {
  const db = memoryDb();
  for (let n = 0; n < 191; n++) addCheer(db, n, {bloomConfirmed: true, plantedFlowerKind: 'tulip'});
  const seen = [];
  let cursor = null;
  do {
    const page = await listVillageCheers(db, 'alice', {cursor, pageSize: 80});
    assert.ok(page.cheers.every(cheer => cheer.bloomConfirmed && cheer.plantedFlowerKind === 'tulip'));
    seen.push(...page.cheers.map(cheer => cheer.id));
    cursor = page.nextCursor;
  } while (cursor);
  assert.deepEqual(seen, Array.from({length: 191}, (_, n) => id(190 - n)));
});

test('timestamp cursors preserve submillisecond precision and survive cursor-record deletion', async () => {
  const db = memoryDb();
  addCheer(db, 0, {createdAt: new Timestamp(100, 1)});
  addCheer(db, 1, {createdAt: new Timestamp(100, 2)});
  addCheer(db, 2, {createdAt: new Timestamp(100, 2)});
  const first = await listVillageCheers(db, 'alice', {pageSize: 1}, timeDeps);
  assert.deepEqual(first.cheers.map(c => c.id), [id(2)]);
  db.rows.delete(`users/alice/receivedCheers/${id(2)}`);
  const second = await listVillageCheers(db, 'alice', {pageSize: 1, cursor: first.nextCursor}, timeDeps);
  assert.deepEqual(second.cheers.map(c => c.id), [id(1)]);
  const third = await listVillageCheers(db, 'alice', {pageSize: 1, cursor: second.nextCursor}, timeDeps);
  assert.deepEqual(third.cheers.map(c => c.id), [id(0)]);
  assert.equal(third.nextCursor, null);
});

test('blocked/transferred history advances without exposing senders; old pending delivery and global retirements stay recoverable', async () => {
  const db = memoryDb();
  for (let n = 0; n < 5; n++) addCheer(db, n, {senderId: 'bob', senderNickname: 'secret'});
  db.rows.set('users/bob/blockedNeighbors/alice', {});
  addCheer(db, 0, {transferred: true, claimed: true});
  db.rows.set('users/alice/receivedCheers/pending-old', {deliveryPending: true, claimed: true, flowerKind: 'daisy'});
  const first = await listVillageCheers(db, 'alice', {pageSize: 2});
  assert.deepEqual(first.cheers.map(c => c.id), ['pending-old']);
  assert.deepEqual(first.retiredIds, [id(0)]);
  assert.ok(first.nextCursor);
  const second = await listVillageCheers(db, 'alice', {pageSize: 2, cursor: first.nextCursor});
  assert.deepEqual(second.cheers, []);
  assert.deepEqual(second.retiredIds, [id(0)]);
  assert.ok(second.nextCursor);
  const third = await listVillageCheers(db, 'alice', {pageSize: 2, cursor: second.nextCursor});
  assert.deepEqual(third.cheers, []);
  assert.equal(third.nextCursor, null);
});

test('new arrivals do not repeat existing pages and appear on an explicit refresh', async () => {
  const db = memoryDb();
  for (let n = 0; n < 3; n++) addCheer(db, n);
  const first = await listVillageCheers(db, 'alice', {pageSize: 2});
  addCheer(db, 3, {createdAt: '2026-10-16T12:00:00.000Z'});
  const next = await listVillageCheers(db, 'alice', {pageSize: 2, cursor: first.nextCursor});
  assert.deepEqual(next.cheers.map(c => c.id), [id(0)]);
  const refreshed = await listVillageCheers(db, 'alice', {pageSize: 2});
  assert.deepEqual(refreshed.cheers.map(c => c.id), [id(3), id(2)]);
});

test('cursors reject wrong owners/actions, malformed timestamps/paths and invalid page sizes', async () => {
  const db = memoryDb();
  addGarden(db, 'bob'); addGarden(db, 'carol');
  addCheer(db, 0); addCheer(db, 1);
  const cursor = (await listVillageCheers(db, 'alice', {pageSize: 1})).nextCursor;
  await assert.rejects(listVillageCheers(db, 'bob', {cursor}), /invalid-cursor/);
  await assert.rejects(listDiscoverableGardens(db, 'alice', {cursor}), /invalid-cursor/);
  for (const bad of ['', '{}', [], 1, 'x'.repeat(1025)]) await assert.rejects(listVillageCheers(db, 'alice', {cursor: bad}), /invalid-cursor/);
  const base = JSON.parse(Buffer.from(cursor, 'base64url').toString());
  for (const change of [{id: 'a/b'}, {at: ['timestamp', 1, 1000000000]}, {at: ['string', 'invalid']}, {owner: 'wrong'}, {extra: 'private'}]) {
    const bad = Buffer.from(JSON.stringify({...base, ...change})).toString('base64url');
    await assert.rejects(listVillageCheers(db, 'alice', {cursor: bad}), /invalid-cursor/);
  }
  for (const pageSize of [0, -1, 81, 1.1, '10', null]) await assert.rejects(listVillageCheers(db, 'alice', {pageSize}), /invalid-page-size/);
  await assert.rejects(listDiscoverableGardens(db, 'alice', {pageSize: 25}), /invalid-page-size/);
});

test('owner publication status returns the exact allowed appearance and server time, never private fields', async () => {
  const db = memoryDb();
  const result = await publishVillageGarden(db, 'alice', {snapshot, nickname: '나의 정원', visibility: 'neighbors'}, deps);
  assert.deepEqual(result.snapshot, {...snapshot, memoryTreeStage: 0, hasCheerFlowers: false, flowerKinds: [], layout: null});
  assert.equal(result.updatedAt, iso);
  db.rows.get('publicGardens/alice').privateDiary = 'do not return';
  const status = await villagePublicationStatus(db, 'alice');
  assert.equal(status.snapshot.privateDiary, undefined);
  const empty = await villagePublicationStatus(db, 'bob');
  assert.equal(empty.snapshot, null);
  assert.equal(empty.updatedAt, null);
});

test('appearance-only updates preserve latest nickname/privacy/preferences even after a device made the garden private', async () => {
  const db = memoryDb();
  await publishVillageGarden(db, 'alice', {snapshot, nickname: '지킬 이름', visibility: 'public', discoveryOptIn: true, receiveGifts: false}, deps);
  db.rows.get('villageProfiles/alice').visibility = 'private';
  db.rows.get('villageProfiles/alice').discoveryOptIn = false;
  const updated = await publishVillageGarden(db, 'alice', {snapshot: {...snapshot, treeStageIndex: 2}, appearanceOnly: true}, deps);
  assert.equal(updated.published, false);
  assert.equal(updated.nickname, '지킬 이름');
  assert.equal(updated.visibility, 'private');
  assert.equal(updated.discoveryOptIn, false);
  assert.equal(updated.receiveGifts, false);
  assert.equal(updated.snapshot.treeStageIndex, 2);
  const fresh = await publishVillageGarden(db, 'fresh', {snapshot, appearanceOnly: true}, deps);
  assert.equal(fresh.visibility, 'private');
  assert.equal(fresh.published, false);
  for (const extra of [{nickname: 'replace'}, {visibility: 'public'}, {discoveryOptIn: true}, {receiveGifts: true}]) {
    await assert.rejects(publishVillageGarden(db, 'alice', {snapshot, appearanceOnly: true, ...extra}, deps), /invalid-profile/);
  }
  await assert.rejects(publishVillageGarden(db, 'alice', {snapshot, appearanceOnly: 'true'}, deps), /invalid-profile/);
});
