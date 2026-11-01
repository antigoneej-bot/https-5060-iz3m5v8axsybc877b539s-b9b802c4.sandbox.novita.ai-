import test from 'node:test';
import assert from 'node:assert/strict';
import { isGardenNewsAdmin } from '../garden-news-admin.js';

const social = {
  uid: 'kakao-owner',
  firebase: {sign_in_provider: 'custom'},
  garden_social_verified: true,
  garden_social_provider: 'kakao',
};

test('news role permits a verified-token social identity without an email', () => {
  assert.equal(isGardenNewsAdmin({...social, garden_news_admin: true}), true);
  assert.equal(isGardenNewsAdmin(social), false);
});

test('news role accepts only literal boolean true', () => {
  for (const garden_news_admin of [false, undefined, null, 0, 1, 'true', '1', {}, []]) {
    assert.equal(isGardenNewsAdmin({...social, garden_news_admin}), false);
  }
});

test('verified legacy admin email remains accepted without the new role', () => {
  const legacy = {uid: 'legacy-owner', firebase: {sign_in_provider: 'password'},
    email: 'ANTIGONE.EJ@GMAIL.COM', email_verified: true};
  assert.equal(isGardenNewsAdmin(legacy), true);
  assert.equal(isGardenNewsAdmin({...legacy, email_verified: false}), false);
  assert.equal(isGardenNewsAdmin({...legacy, email_verified: 'true'}), false);
  assert.equal(isGardenNewsAdmin({...legacy, email: 'member@example.invalid'}), false);
});

test('missing UID, missing provider and anonymous identities cannot manage news', () => {
  const admin = {...social, garden_news_admin: true,
    email: 'antigone.ej@gmail.com', email_verified: true};
  for (const identity of [null, undefined, {},
    {...admin, uid: undefined}, {...admin, uid: ''}, {...admin, uid: 1},
    {...admin, firebase: undefined}, {...admin, firebase: {}},
    {...admin, firebase: {sign_in_provider: ''}},
    {...admin, firebase: {sign_in_provider: 'anonymous'}}]) {
    assert.equal(isGardenNewsAdmin(identity), false);
  }
});
