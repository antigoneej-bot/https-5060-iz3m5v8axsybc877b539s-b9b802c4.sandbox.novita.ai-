import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {acceptsGiftAmount, beginCheerDelivery as begin, acknowledgeCheerDelivery as acknowledge} from '../cheer-delivery.js';

const deviceId = 'device-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const beginCheerDelivery = (db, uid, id, options = {}) => begin(db, uid, id, {deviceId, ...options});
const acknowledgeCheerDelivery = (db, uid, id, receipt) => acknowledge(db, uid, id, receipt, deviceId);
const path = 'users/bob/receivedCheers/gift1';
const fixture = () => memoryDb({[path]: {giftLightEssence: 5, claimed: false}});

test('client-provided currency cannot mint a new gift', () => {
  for (const value of [1, 5, -1, 0.1, '0', '5', null, NaN, Infinity, {}]) {
    assert.equal(acceptsGiftAmount(value), false);
  }
  assert.equal(acceptsGiftAmount(0), true);
  assert.equal(acceptsGiftAmount(undefined), true);
});
test('lost claim response replays the same receipt until ACK', async () => {
  const db = fixture();
  const first = await beginCheerDelivery(db, 'bob', 'gift1');
  const retry = await beginCheerDelivery(db, 'bob', 'gift1');
  assert.deepEqual(retry, first);
  assert.equal(retry.amount, 5);
  assert.equal(db.rows.get(path).deliveryPending, true);
  await acknowledgeCheerDelivery(db, 'bob', 'gift1', first.receipt);
  await acknowledgeCheerDelivery(db, 'bob', 'gift1', first.receipt); // lost ACK response
  assert.equal((await beginCheerDelivery(db, 'bob', 'gift1')).amount, 0);
  assert.equal(db.rows.get(path).deliveryPending, false);
});
test('concurrent claims reserve one durable receipt', async () => {
  const db = fixture();
  const [a, b] = await Promise.all([
    beginCheerDelivery(db, 'bob', 'gift1'), beginCheerDelivery(db, 'bob', 'gift1'),
  ]);
  assert.deepEqual(a, b);
});
test('failed transaction does not swallow an unclaimed gift', async () => {
  const db = fixture();
  db.beforeCommit = () => {throw new Error('storage-offline');};
  await assert.rejects(beginCheerDelivery(db, 'bob', 'gift1'), /storage-offline/);
  assert.equal(db.rows.get(path).claimed, false);
  db.beforeCommit = null;
  assert.equal((await beginCheerDelivery(db, 'bob', 'gift1')).amount, 5);
});
test('wrong owner, path injection and wrong ACK cannot consume a gift', async () => {
  const db = fixture();
  await assert.rejects(beginCheerDelivery(db, 'alice', 'gift1'), /cheer-not-found/);
  await assert.rejects(beginCheerDelivery(db, 'bob', '../gift1'), /invalid-id/);
  await beginCheerDelivery(db, 'bob', 'gift1');
  await assert.rejects(acknowledgeCheerDelivery(db, 'bob', 'gift1', 'invented'), /invalid-delivery-receipt/);
  assert.equal(db.rows.get(path).deliveryPending, true);
});
test('old clients cannot prematurely consume currency or pending receipts', async () => {
  const db = fixture();
  await assert.rejects(beginCheerDelivery(db, 'bob', 'gift1', {legacy: true}), /client-update-required/);
  assert.equal(db.rows.get(path).claimed, false);
  await beginCheerDelivery(db, 'bob', 'gift1');
  await assert.rejects(beginCheerDelivery(db, 'bob', 'gift1', {legacy: true}), /client-update-required/);
  db.rows.set(path, {claimed: false, giftLightEssence: 0});
  assert.equal((await beginCheerDelivery(db, 'bob', 'gift1', {legacy: true})).amount, 0);
});
test('old claims with no receipt are never guessed to be unpaid', async () => {
  const db = memoryDb({[path]: {claimed: true, giftLightEssence: 5}});
  assert.equal((await beginCheerDelivery(db, 'bob', 'gift1')).amount, 0);
});
test('malformed stored currency is rejected before modifying the gift', async () => {
  for (const amount of [-1, 6, 1.5, '5']) {
    const db = memoryDb({[path]: {giftLightEssence: amount, claimed: false}});
    await assert.rejects(beginCheerDelivery(db, 'bob', 'gift1'), /invalid-garden-gift/);
    assert.equal(db.rows.get(path).claimed, false);
  }
});

test('a second installation cannot replay or ACK an in-flight currency gift', async () => {
  const db = fixture();
  const first = await beginCheerDelivery(db, 'bob', 'gift1');
  const otherDevice = 'device-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  await assert.rejects(beginCheerDelivery(db, 'bob', 'gift1', {deviceId: otherDevice}), /delivery-other-device/);
  await assert.rejects(acknowledge(db, 'bob', 'gift1', first.receipt, otherDevice), /delivery-other-device/);
  assert.equal(db.rows.get(path).deliveryPending, true);
  assert.equal((await beginCheerDelivery(db, 'bob', 'gift1')).receipt, first.receipt);
});
test('currency delivery requires a persistent installation identifier', async () => {
  const db = fixture();
  await assert.rejects(begin(db, 'bob', 'gift1'), /invalid-delivery-device/);
  assert.equal(db.rows.get(path).claimed, false);
});
