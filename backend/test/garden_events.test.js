import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {validateEventSessions, saveGardenEvent, reserveGardenEvent, cancelGardenEvent,
  handleGardenNewsAction, publicGardenNews} from '../garden-events.js';
import {removeAccountReservations} from '../account-reservations.js';

const nowMs = Date.parse('2026-11-01T10:00:00Z');
const deps = {now: () => nowMs, stamp: () => new Date(nowMs).toISOString()};
const admin = {uid: 'operator', firebase: {sign_in_provider: 'custom'}, garden_news_admin: true};
const member = {uid: 'member', firebase: {sign_in_provider: 'custom'}, garden_social_verified: true};
const slot = (id = 'one', capacity = 2) => ({id, startsAt: '2026-11-02T10:00:00Z',
  endsAt: '2026-11-02T10:20:00Z', bookingOpensAt: '2026-10-31T10:00:00Z',
  bookingClosesAt: '2026-11-02T09:00:00Z', capacity, state: 'open'});
const input = (slots = [slot()]) => ({title: '함께 편지 쓰는 저녁', body: '각자의 기록은 공유하지 않아요.',
  type: 'event', status: 'recruiting', eventMode: 'online', meetingUrl: 'https://example.org/meeting', sessions: slots});
async function setup(slots) { const db = memoryDb(); const created = await saveGardenEvent(db, 'operator', admin, input(slots), null, deps); return {db, id: created.id}; }

test('sessions require bounded capacity, unique IDs, timezone and ordered booking/event times', () => {
  assert.equal(validateEventSessions([slot()])[0].capacity, 2);
  for (const bad of [
    {...slot(), id: '../escape'}, {...slot(), capacity: 0}, {...slot(), capacity: 1.5},
    {...slot(), startsAt: '2026-11-02T10:00:00'}, {...slot(), endsAt: slot().startsAt},
    {...slot(), bookingClosesAt: '2026-11-03T10:00:00Z'},
    {...slot(), bookingOpensAt: slot().bookingClosesAt}, {...slot(), state: 'popular'}]) {
    assert.throws(() => validateEventSessions([bad]), /invalid-event-sessions/);
  }
  assert.throws(() => validateEventSessions([slot(), slot()]), /invalid-event-sessions/);
  assert.throws(() => validateEventSessions(Array.from({length: 13}, (_, i) => slot(String(i)))), /invalid-event-sessions/);
});

test('only trusted operator role can create or change sessions; counts and private data are not accepted', async () => {
  const db = memoryDb();
  await assert.rejects(saveGardenEvent(db, 'member', member, input(), null, deps), /admin-required/);
  const created = await saveGardenEvent(db, 'operator', admin,
    {...input([{...slot(), reservedCount: 999}]), reservedCount: 999, privateLetter: 'never copy'}, null, deps);
  const data = db.rows.get(`gardenNews/${created.id}`);
  assert.equal(data.reservedCount, 0); assert.equal(data.sessions[0].reservedCount, 0);
  assert.equal(data.privateLetter, undefined);
});

test('concurrent last-seat requests accept one member and preserve exact slot and total counts', async () => {
  const {db, id} = await setup([slot('one', 1)]);
  const results = await Promise.allSettled(['alice', 'bob'].map(uid => reserveGardenEvent(db, uid, member,
    {newsId: id, sessionId: 'one'}, deps)));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.filter(r => r.status === 'rejected')[0].reason.message, 'reservation-full');
  assert.equal(db.rows.get(`gardenNews/${id}`).reservedCount, 1);
  assert.equal(db.rows.get(`gardenNews/${id}`).sessions[0].reservedCount, 1);
});

test('lost-response replay never consumes an extra seat and cannot silently switch sessions', async () => {
  const {db, id} = await setup([slot('one'), slot('two')]);
  const first = await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one', displayName: '친구'}, deps);
  const again = await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  assert.equal(first.reservation.id, again.reservation.id);
  assert.equal(again.news.reservedCount, 1);
  await assert.rejects(reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'two'}, deps), /already-reserved/);
  assert.equal(db.rows.get(`gardenNews/${id}`).sessions[1].reservedCount, 0);
});

test('booking window and canceled/closed sessions are enforced by server time', async () => {
  for (const [alter, expected] of [
    [{bookingOpensAt: '2026-11-02T08:00:00Z'}, 'reservation-not-open'],
    [{bookingClosesAt: '2026-11-01T09:00:00Z'}, 'reservation-closed'],
    [{state: 'closed'}, 'reservation-closed'], [{state: 'canceled'}, 'reservation-closed']]) {
    const {db, id} = await setup([{...slot(), ...alter}]);
    await assert.rejects(reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps), new RegExp(expected));
    assert.equal(db.rows.get(`gardenNews/${id}`).reservedCount, 0);
  }
});

test('scheduled bookings require an explicit existing session; legacy undated bookings remain usable', async () => {
  const {db, id} = await setup();
  await assert.rejects(reserveGardenEvent(db, 'alice', member, {newsId: id}, deps), /event-session-required/);
  db.rows.set('gardenNews/legacy', {capacity: 3, reservedCount: 0});
  await reserveGardenEvent(db, 'alice', member, {newsId: 'legacy'}, deps);
  await reserveGardenEvent(db, 'alice', member, {newsId: 'legacy'}, deps);
  assert.equal(db.rows.get('gardenNews/legacy').reservedCount, 1);
});

test('cancel is idempotent and account deletion releases only the selected session seat', async () => {
  const {db, id} = await setup([slot('one'), slot('two')]);
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  await reserveGardenEvent(db, 'bob', member, {newsId: id, sessionId: 'two'}, deps);
  await cancelGardenEvent(db, 'alice', {newsId: id});
  await cancelGardenEvent(db, 'alice', {newsId: id});
  let data = db.rows.get(`gardenNews/${id}`);
  assert.equal(data.reservedCount, 1); assert.deepEqual(data.sessions.map(s => s.reservedCount), [0, 1]);
  await removeAccountReservations(db, 'bob');
  data = db.rows.get(`gardenNews/${id}`);
  assert.equal(data.reservedCount, 0); assert.deepEqual(data.sessions.map(s => s.reservedCount), [0, 0]);
});

test('reserved session timing/deletion/capacity shrink is blocked; closing or canceling is explicit', async () => {
  const {db, id} = await setup([slot('one', 2)]);
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  await reserveGardenEvent(db, 'bob', member, {newsId: id, sessionId: 'one'}, deps);
  for (const sessions of [[], [slot('one', 1)], [{...slot('one', 2), startsAt: '2026-11-02T10:05:00Z'}]]) {
    await assert.rejects(saveGardenEvent(db, 'operator', admin, input(sessions), id, deps), /event-has-reservations/);
  }
  await saveGardenEvent(db, 'operator', admin, input([{...slot(), state: 'canceled'}]), id, deps);
  assert.equal(db.rows.get(`gardenNews/${id}`).sessions[0].reservedCount, 2);
});

test('public listing omits meeting link and participant data; only booked account can open online meeting', async () => {
  const {db, id} = await setup();
  const publicView = publicGardenNews(id, db.rows.get(`gardenNews/${id}`));
  assert.equal(publicView.meetingUrl, undefined); assert.equal(publicView.createdBy, undefined);
  await assert.rejects(handleGardenNewsAction(db, 'alice', member, 'getGardenEventAccess', {newsId: id}), /reservation-required/);
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  assert.equal((await handleGardenNewsAction(db, 'alice', member, 'getGardenEventAccess', {newsId: id})).meetingUrl, 'https://example.org/meeting');
  await assert.rejects(handleGardenNewsAction(db, 'bob', member, 'adminListGardenNewsReservations', {newsId: id}), /admin-required/);
});

test('deletion closes booking during cleanup and removes all reservation pages', async () => {
  const {db, id} = await setup();
  for (let i = 0; i < 101; i++) db.rows.set(`gardenNewsReservations/${id}_${i}`, {newsId: id, uid: String(i)});
  await handleGardenNewsAction(db, 'operator', admin, 'adminDeleteGardenNews', {id});
  assert.equal(db.rows.has(`gardenNews/${id}`), false);
  assert.equal([...db.rows.keys()].some(key => key.startsWith('gardenNewsReservations/')), false);
});

test('bad update identifier cannot create a notice and private link schemes are rejected', async () => {
  const db = memoryDb();
  await assert.rejects(handleGardenNewsAction(db, 'operator', admin, 'adminUpdateGardenNews', {news: input()}), /invalid-id/);
  for (const url of ['http://example.org', 'javascript:alert(1)', 'https://name:password@example.org']) {
    await assert.rejects(saveGardenEvent(db, 'operator', admin, {...input(), meetingUrl: url}, null, deps), /invalid-event-link/);
  }
  assert.equal(db.rows.size, 0);
});


test('older editor updates preserve schedules and private links while incompatible types are rejected', async () => {
  const {db, id} = await setup();
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  await saveGardenEvent(db, 'operator', admin, {title: '운영 안내 수정', body: '새 안내', type: 'event'}, id, deps);
  const data = db.rows.get(`gardenNews/${id}`);
  assert.equal(data.sessions[0].reservedCount, 1);
  assert.equal(data.meetingUrl, 'https://example.org/meeting');
  assert.equal(data.eventMode, 'online');
  await assert.rejects(saveGardenEvent(db, 'operator', admin,
    {title: '일반 안내로 변경', body: '새 안내', type: 'info'}, id, deps), /invalid-event-sessions/);
  await assert.rejects(saveGardenEvent(db, 'operator', admin, {...input(), eventMode: null}, null, deps), /invalid-event-mode/);
});

test('a canceled session cannot expose the meeting link and offline events do not retain old links', async () => {
  const {db, id} = await setup();
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  await saveGardenEvent(db, 'operator', admin, input([{...slot(), state: 'canceled'}]), id, deps);
  await assert.rejects(handleGardenNewsAction(db, 'alice', member, 'getGardenEventAccess', {newsId: id}), /event-canceled/);
  await saveGardenEvent(db, 'operator', admin, {...input([{...slot(), state: 'closed'}]), eventMode: 'offline'}, id, deps);
  assert.equal(db.rows.get(`gardenNews/${id}`).meetingUrl, null);
});

test('legacy booked events cannot lose capacity or shrink below live bookings', async () => {
  const db = memoryDb();
  const legacy = {title: '원데이 모임', body: '안내', type: 'event', capacity: 3, sessions: []};
  const {id} = await saveGardenEvent(db, 'operator', admin, legacy, null, deps);
  await reserveGardenEvent(db, 'alice', member, {newsId: id}, deps);
  await reserveGardenEvent(db, 'bob', member, {newsId: id}, deps);
  for (const capacity of [null, undefined, 0, 1]) {
    await assert.rejects(saveGardenEvent(db, 'operator', admin, {...legacy, capacity}, id, deps), /event-has-reservations/);
  }
  await saveGardenEvent(db, 'operator', admin, {...legacy, capacity: 2, status: 'closed'}, id, deps);
  assert.equal(db.rows.get(`gardenNews/${id}`).reservedCount, 2);
  await cancelGardenEvent(db, 'alice', {newsId: id});
  assert.equal(db.rows.get(`gardenNews/${id}`).reservedCount, 1);
  assert.equal(db.rows.has(`gardenNewsReservations/${id}_bob`), true);
});

test('interrupted delete remains discoverable only to operator and safely resumes', async () => {
  const {db, id} = await setup();
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  await reserveGardenEvent(db, 'bob', member, {newsId: id, sessionId: 'one'}, deps);
  let deletes = 0;
  const interrupted = {...db, runTransaction: fn => db.runTransaction(tx => fn({...tx,
    delete: ref => {
      if (ref.path.startsWith('gardenNewsReservations/') && ++deletes === 2) throw new Error('temporary-storage-failure');
      return tx.delete(ref);
    },
  }))};
  await assert.rejects(handleGardenNewsAction(interrupted, 'operator', admin, 'adminDeleteGardenNews', {id}), /temporary-storage-failure/);
  const operatorList = await handleGardenNewsAction(db, 'operator', admin, 'listGardenNews', {});
  assert.equal(operatorList.news.find(news => news.id === id).deleting, true);
  assert.equal((await handleGardenNewsAction(db, 'operator', admin, 'getGardenNews', {newsId: id})).news.deleting, true);
  assert.equal((await handleGardenNewsAction(db, 'bob', member, 'listGardenNews', {})).news.length, 0);
  await assert.rejects(handleGardenNewsAction(db, 'bob', member, 'getGardenNews', {newsId: id}), /news-not-found/);
  await assert.rejects(handleGardenNewsAction(db, 'operator', admin, 'getGardenEventAccess', {newsId: id}), /news-not-found/);
  await assert.rejects(reserveGardenEvent(db, 'bob', member, {newsId: id, sessionId: 'one'}, deps), /reservation-closed/);
  await handleGardenNewsAction(db, 'operator', admin, 'adminDeleteGardenNews', {id});
  await handleGardenNewsAction(db, 'operator', admin, 'adminDeleteGardenNews', {id});
  assert.equal(db.rows.has(`gardenNews/${id}`), false);
  assert.equal([...db.rows.keys()].some(key => key.startsWith('gardenNewsReservations/')), false);
});

test('my bookings join actual date/status without other accounts or private meeting links', async () => {
  const {db, id} = await setup();
  await reserveGardenEvent(db, 'alice', member, {newsId: id, sessionId: 'one'}, deps);
  db.rows.set('gardenNewsReservations/other_bob', {newsId: 'other', uid: 'bob'});
  const result = await handleGardenNewsAction(db, 'alice', member, 'myGardenNewsReservations', {});
  assert.equal(result.reservations.length, 1);
  assert.equal(Date.parse(result.reservations[0].sessionStartsAt), Date.parse(slot().startsAt));
  assert.equal(result.reservations[0].news.title, input().title);
  assert.equal(result.reservations[0].news.meetingUrl, undefined);
  assert.equal(result.reservations[0].eventUnavailable, false);
  await db.doc(`gardenNews/${id}`).update({deleting: true});
  const pending = await handleGardenNewsAction(db, 'alice', member, 'myGardenNewsReservations', {});
  assert.equal(pending.reservations[0].news, null);
  assert.equal(pending.reservations[0].eventUnavailable, true);
  await cancelGardenEvent(db, 'alice', {newsId: id});
  assert.equal((await handleGardenNewsAction(db, 'alice', member, 'myGardenNewsReservations', {})).reservations.length, 0);
});

test('create request survives lost response, concurrent replay, and later edits without duplicates', async () => {
  const db = memoryDb();
  const payload = {news: input(), requestId: 'persisted-draft-key'};
  const save = () => handleGardenNewsAction(db, 'operator', admin, 'adminCreateGardenNews', payload, deps);
  const results = await Promise.all([save(), save(), save()]);
  assert.equal(new Set(results.map(r => r.id)).size, 1);
  assert.equal([...db.rows.keys()].filter(k => k.startsWith('gardenNews/')).length, 1);
  const id = results[0].id;
  await saveGardenEvent(db, 'operator', admin, {...input(), title: 'edited'}, id, deps);
  assert.equal((await save()).id, id);
  assert.equal(db.rows.get(`gardenNews/${id}`).title, 'edited');
});

test('create key binds payload and owner; validation and admin permissions still apply', async () => {
  const db = memoryDb();
  const d = {...deps, requestId: 'same-key'};
  const first = await saveGardenEvent(db, 'operator', admin, input(), null, d);
  await assert.rejects(saveGardenEvent(db, 'operator', admin, {...input(), title: 'other'}, null, d), /request-payload-mismatch/);
  await assert.rejects(saveGardenEvent(db, 'member', member, input(), null, d), /admin-required/);
  await assert.rejects(saveGardenEvent(db, 'operator', admin, input(), null, {...d, requestId: '../bad'}), /invalid-request-id/);
  const second = await saveGardenEvent(db, 'other-operator', admin, input(), null, d);
  assert.notEqual(first.id, second.id);
});

test('late create replay cannot resurrect a deleted notice', async () => {
  const db = memoryDb();
  const d = {...deps, requestId: 'deleted-key'};
  const first = await saveGardenEvent(db, 'operator', admin, input(), null, d);
  await handleGardenNewsAction(db, 'operator', admin, 'adminDeleteGardenNews', {id: first.id}, deps);
  await assert.rejects(saveGardenEvent(db, 'operator', admin, input(), null, d), /news-not-found/);
  assert.equal([...db.rows.keys()].filter(k => k.startsWith('gardenNews/')).length, 0);
});
