import test from 'node:test';
import assert from 'node:assert/strict';
import { isAdminEmail, ADMIN_EMAILS, validateGardenNewsInput, sanitizeReservationNote,
  GARDEN_NEWS_TYPES, GARDEN_NEWS_STATUSES } from '../policy.js';

test('isAdminEmail matches only known admin emails, case-insensitively', () => {
  assert.equal(isAdminEmail('antigone.ej@gmail.com'), true);
  assert.equal(isAdminEmail('ANTIGONE.EJ@GMAIL.COM'), true);
  assert.equal(isAdminEmail('someone-else@example.com'), false);
  assert.equal(isAdminEmail(null), false);
  assert.equal(isAdminEmail(undefined), false);
  assert.equal(isAdminEmail(42), false);
});

test('validateGardenNewsInput accepts a well-formed info notice (no reservation)', () => {
  const result = validateGardenNewsInput({
    title: '원데이 클래스 안내', body: '함께 명상해요', emoji: '🧘', type: 'info',
  });
  assert.deepEqual(result, {
    title: '원데이 클래스 안내', body: '함께 명상해요', emoji: '🧘', type: 'info',
    status: null, period: null, location: null, cost: null, applyUrl: null, capacity: null,
  });
});

test('validateGardenNewsInput accepts a reservation-enabled event with capacity', () => {
  const result = validateGardenNewsInput({
    title: '원데이 클래스', body: '선착순 모집합니다', type: 'event', status: 'recruiting',
    period: '2026-09-01 ~ 2026-09-01', location: '온라인(줌)', cost: '무료', capacity: 20,
  });
  assert.equal(result.capacity, 20);
  assert.equal(result.status, 'recruiting');
  assert.equal(result.emoji, '📌'); // default when omitted
});

test('validateGardenNewsInput rejects missing/blank title or body', () => {
  assert.equal(validateGardenNewsInput({title: '', body: '내용'}), null);
  assert.equal(validateGardenNewsInput({title: '제목', body: ''}), null);
  assert.equal(validateGardenNewsInput({title: '   ', body: '내용'}), null);
  assert.equal(validateGardenNewsInput(null), null);
  assert.equal(validateGardenNewsInput('not-an-object'), null);
});

test('validateGardenNewsInput falls back to type=info for unknown type', () => {
  const result = validateGardenNewsInput({title: '제목', body: '내용', type: 'not-a-real-type'});
  assert.equal(result.type, 'info');
});

test('validateGardenNewsInput rejects unknown explicit status string', () => {
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', status: 'popular'}), null);
});

test('validateGardenNewsInput rejects out-of-range or non-integer capacity', () => {
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', capacity: -1}), null);
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', capacity: 1.5}), null);
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', capacity: 100001}), null);
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', capacity: 'twenty'}), null);
});

test('validateGardenNewsInput rejects non-https applyUrl', () => {
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', applyUrl: 'http://example.com'}), null);
  assert.equal(validateGardenNewsInput({title: '제목', body: '내용', applyUrl: 'javascript:alert(1)'}), null);
});

test('validateGardenNewsInput accepts https applyUrl', () => {
  const result = validateGardenNewsInput({
    title: '제목', body: '내용', applyUrl: 'https://forms.gle/example',
  });
  assert.equal(result.applyUrl, 'https://forms.gle/example');
});

test('validateGardenNewsInput trims/limits title and body length', () => {
  const result = validateGardenNewsInput({title: 'x'.repeat(200), body: 'y'.repeat(5000)});
  assert.equal(result.title.length, 80);
  assert.equal(result.body.length, 4000);
});

test('sanitizeReservationNote trims, strips control chars, caps length', () => {
  assert.equal(sanitizeReservationNote('  반려동물 동반 가능한가요?  '), '반려동물 동반 가능한가요?');
  assert.equal(sanitizeReservationNote(''), null);
  assert.equal(sanitizeReservationNote('z'.repeat(500)).length, 200);
});

test('known type/status sets are sane (regression guard against silent drift)', () => {
  assert.ok(GARDEN_NEWS_TYPES.has('info'));
  assert.ok(GARDEN_NEWS_TYPES.has('update'));
  assert.ok(GARDEN_NEWS_TYPES.has('event'));
  assert.ok(GARDEN_NEWS_STATUSES.has('recruiting'));
  assert.ok(GARDEN_NEWS_STATUSES.has('ongoing'));
  assert.ok(GARDEN_NEWS_STATUSES.has('closed'));
  assert.ok(ADMIN_EMAILS.has('antigone.ej@gmail.com'));
});
