import test from 'node:test';
import assert from 'node:assert/strict';
import { nextAccountLease } from '../policy.js';

test('first operation holds a lease longer than the function timeout', () => {
  assert.deepEqual(nextAccountLease({}, 'backup', 'one', 1000), {owner:'one',until:121000});
});
test('backup, deletion and RTDN cannot enter an unexpired account operation', () => {
  for (const action of ['backup','verify','rtdn','deleteCloudAccount']) {
    assert.throws(() => nextAccountLease({owner:'one',until:121000}, action, 'two', 1001), /account-busy/);
  }
});
test('failed function lease can be recovered after timeout', () => {
  assert.equal(nextAccountLease({owner:'one',until:121000}, 'backup', 'two', 121001).owner, 'two');
});
test('partial deletion blocks uploads, purchase verification and notifications', () => {
  for (const action of ['backup','status','verify','rtdn']) {
    assert.throws(() => nextAccountLease({deleting:true}, action, 'one', 1000), /account-deleting/);
  }
});
test('deletion can retry while tombstones remain in place', () => {
  const resumed = nextAccountLease({deleted:true,deleting:true}, 'deleteCloudAccount', 'retry', 1000);
  assert.equal(resumed.deleted, true);
  assert.equal(resumed.owner, 'retry');
});
