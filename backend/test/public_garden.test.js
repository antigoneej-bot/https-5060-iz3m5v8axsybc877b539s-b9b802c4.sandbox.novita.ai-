import test from 'node:test';
import assert from 'node:assert/strict';
import { sanitizeNickname, validatePublicSnapshot, KNOWN_SEED_IDS, KNOWN_DECORATION_IDS,
  PUBLIC_CHEER_MESSAGE_COUNT, MAX_CHEER_GIFT_LIGHT_ESSENCE } from '../policy.js';

test('sanitizeNickname trims, strips control chars, caps length', () => {
  assert.equal(sanitizeNickname('  고양이정원  '), '고양이정원');
  assert.equal(sanitizeNickname('a\u0000b\u001fc'), 'abc');
  assert.equal(sanitizeNickname(''), null);
  assert.equal(sanitizeNickname('   '), null);
  assert.equal(sanitizeNickname(null), null);
  assert.equal(sanitizeNickname(42), null);
  assert.equal(sanitizeNickname('x'.repeat(50)).length, 20);
});

test('validatePublicSnapshot accepts a well-formed snapshot', () => {
  assert.equal(validatePublicSnapshot({
    seedCounts: {pine: 3, love: 10},
    equippedDecorationIds: ['bench', 'lantern'],
    treeStageIndex: 2,
  }), true);
});

test('validatePublicSnapshot rejects unknown seed/decoration ids', () => {
  assert.equal(validatePublicSnapshot({
    seedCounts: {not_a_real_seed: 1}, equippedDecorationIds: [], treeStageIndex: 0,
  }), false);
  assert.equal(validatePublicSnapshot({
    seedCounts: {}, equippedDecorationIds: ['not_a_real_decoration'], treeStageIndex: 0,
  }), false);
});

test('validatePublicSnapshot rejects out-of-range counts and stage index', () => {
  assert.equal(validatePublicSnapshot({seedCounts: {pine: -1}, equippedDecorationIds: [], treeStageIndex: 0}), false);
  assert.equal(validatePublicSnapshot({seedCounts: {pine: 10000}, equippedDecorationIds: [], treeStageIndex: 0}), false);
  assert.equal(validatePublicSnapshot({seedCounts: {}, equippedDecorationIds: [], treeStageIndex: 4}), false);
  assert.equal(validatePublicSnapshot({seedCounts: {}, equippedDecorationIds: [], treeStageIndex: -2}), false);
});

test('validatePublicSnapshot rejects malformed shapes', () => {
  assert.equal(validatePublicSnapshot(null), false);
  assert.equal(validatePublicSnapshot({}), false);
  assert.equal(validatePublicSnapshot({seedCounts: [], equippedDecorationIds: [], treeStageIndex: 0}), false);
  assert.equal(validatePublicSnapshot({seedCounts: {}, equippedDecorationIds: 'nope', treeStageIndex: 0}), false);
});

test('known id sets and limits are sane (regression guard against silent drift)', () => {
  assert.ok(KNOWN_SEED_IDS.has('pine'));
  assert.ok(KNOWN_DECORATION_IDS.has('bench'));
  assert.equal(PUBLIC_CHEER_MESSAGE_COUNT, 6);
  assert.equal(MAX_CHEER_GIFT_LIGHT_ESSENCE, 5);
});
