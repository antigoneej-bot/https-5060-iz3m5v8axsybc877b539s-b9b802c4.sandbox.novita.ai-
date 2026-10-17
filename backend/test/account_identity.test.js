import test from 'node:test';
import assert from 'node:assert/strict';
import { hasTrustedAccount, isSignedInAccount, hasRecentAuthentication } from '../account-identity.js';

test('verified legacy email and Google remain accepted', () => {
  assert.equal(hasTrustedAccount({uid:'u',email_verified:true,firebase:{sign_in_provider:'password'}}),true);
  assert.equal(hasTrustedAccount({uid:'u',firebase:{sign_in_provider:'google.com'}}),true);
});
test('social identity requires custom sign-in plus both server-controlled claims', () => {
  for (const provider of ['kakao','naver','facebook']) {
    const valid={uid:'u',firebase:{sign_in_provider:'custom'},garden_social_verified:true,garden_social_provider:provider};
    assert.equal(hasTrustedAccount(valid),true);
    assert.equal(hasTrustedAccount({...valid,garden_social_verified:false}),false);
    assert.equal(hasTrustedAccount({...valid,firebase:{sign_in_provider:'password'}}),false);
    assert.equal(hasTrustedAccount({...valid,garden_social_provider:'unknown'}),false);
    assert.equal(hasTrustedAccount({...valid,uid:''}),false);
  }
});
test('anonymous, absent identity and unverified email never become trusted', () => {
  assert.equal(hasTrustedAccount(null),false);
  assert.equal(hasTrustedAccount({uid:'u',email_verified:false,firebase:{sign_in_provider:'password'}}),false);
  assert.equal(hasTrustedAccount({uid:'u',email_verified:true,firebase:{sign_in_provider:'anonymous'}}),false);
});

test('deletion accepts unverified password ownership but rejects anonymous or missing provider identity', () => {
  assert.equal(isSignedInAccount({uid:'u',email_verified:false,firebase:{sign_in_provider:'password'}}),true);
  assert.equal(isSignedInAccount({uid:'u',firebase:{sign_in_provider:'custom'}}),true);
  for (const identity of [null,{uid:'u'},{uid:'',firebase:{sign_in_provider:'password'}},
    {uid:'u',firebase:{sign_in_provider:'anonymous'}},{uid:'u',firebase:{sign_in_provider:''}}]) {
    assert.equal(isSignedInAccount(identity),false);
  }
});
test('recent authentication has bounded numeric time including explicit clock-skew allowance', () => {
  const now=10000;
  for (const auth_time of [9700,10000,10030]) assert.equal(hasRecentAuthentication({auth_time},now),true);
  for (const auth_time of [undefined,null,NaN,Infinity,-Infinity,'10000',0,-1,9699,10031]) {
    assert.equal(hasRecentAuthentication({auth_time},now),false);
  }
});
