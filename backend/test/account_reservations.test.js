import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {removeAccountReservations} from '../account-reservations.js';

test('deleting a user removes their personal reservation and releases only their seat', async () => {
  const db = memoryDb({
    'gardenNews/event': {reservedCount: 2},
    'gardenNewsReservations/event_alice': {newsId: 'event', uid: 'alice', email: 'a@example.invalid', note: 'private'},
    'gardenNewsReservations/event_bob': {newsId: 'event', uid: 'bob'},
  });
  assert.equal(await removeAccountReservations(db, 'alice'), 1);
  assert.equal(db.rows.has('gardenNewsReservations/event_alice'), false);
  assert.equal(db.rows.has('gardenNewsReservations/event_bob'), true);
  assert.equal(db.rows.get('gardenNews/event').reservedCount, 1);
  assert.equal(await removeAccountReservations(db, 'alice'), 0);
  assert.equal(db.rows.get('gardenNews/event').reservedCount, 1);
});
test('partial cleanup retries without subtracting a seat twice', async () => {
  const db = memoryDb({
    'gardenNews/a': {reservedCount: 1}, 'gardenNews/b': {reservedCount: 1},
    'gardenNewsReservations/a_alice': {newsId: 'a', uid: 'alice'},
    'gardenNewsReservations/b_alice': {newsId: 'b', uid: 'alice'},
  });
  let commits = 0;
  db.beforeCommit = () => {if (++commits === 2) throw new Error('interrupted');};
  await assert.rejects(removeAccountReservations(db, 'alice'), /interrupted/);
  assert.equal(db.rows.get('gardenNews/a').reservedCount, 0);
  assert.equal(db.rows.get('gardenNews/b').reservedCount, 1);
  assert.equal(db.rows.has('gardenNewsReservations/b_alice'), true);
  db.beforeCommit = null;
  await removeAccountReservations(db, 'alice');
  assert.equal(db.rows.get('gardenNews/a').reservedCount, 0);
  assert.equal(db.rows.get('gardenNews/b').reservedCount, 0);
});
test('missing or malformed news does not strand personal reservation data', async () => {
  const db = memoryDb({
    'gardenNewsReservations/a_alice': {newsId: 'deleted', uid: 'alice'},
    'gardenNewsReservations/b_alice': {newsId: '../bad', uid: 'alice'},
  });
  await removeAccountReservations(db, 'alice');
  assert.equal(db.rows.size, 0);
});
test('cleanup continues beyond one page and counters never become negative', async () => {
  const db = memoryDb({'gardenNews/event': {reservedCount: 0}});
  for (let i = 0; i < 51; i++) db.rows.set(`gardenNewsReservations/${i}`, {newsId: 'event', uid: 'alice'});
  assert.equal(await removeAccountReservations(db, 'alice'), 51);
  assert.equal(db.rows.size, 1);
  assert.equal(db.rows.get('gardenNews/event').reservedCount, 0);
});
