import test from 'node:test';
import assert from 'node:assert/strict';
import { readOwnPublicGardenStatus } from '../public-garden-status.js';

test('a new device discovers an existing publication for its authenticated UID', async () => {
  const db = {doc(path) {
    assert.equal(path, 'publicGardens/account-a');
    return {get: async () => ({exists: true, data: () => ({nickname: '내 정원', seedCounts: {pine: 4}})})};
  }};
  assert.deepEqual(await readOwnPublicGardenStatus(db, 'account-a'), {
    published: true, nickname: '내 정원',
  });
});

test('an absent publication is explicitly private', async () => {
  const db = {doc: () => ({get: async () => ({exists: false})})};
  assert.deepEqual(await readOwnPublicGardenStatus(db, 'account-a'), {
    published: false, nickname: null,
  });
});

test('a database failure propagates instead of claiming private status', async () => {
  const db = {doc: () => ({get: async () => {throw new Error('unavailable');}})};
  await assert.rejects(readOwnPublicGardenStatus(db, 'account-a'), /unavailable/);
});

test('switching accounts never reads the prior account publication', async () => {
  const db = {doc: path => ({get: async () => ({
    exists: path === 'publicGardens/account-a',
    data: () => ({nickname: 'A'}),
  })})};
  assert.equal((await readOwnPublicGardenStatus(db, 'account-a')).published, true);
  assert.equal((await readOwnPublicGardenStatus(db, 'account-b')).published, false);
});
