import test from 'node:test';
import assert from 'node:assert/strict';
import {requireBackupStorage} from '../backup-storage.js';

test('cleanup checks only the verified owner prefix using existing list permission, without fallback storage', async () => {
  const bucket = {getFiles: async options => {
    assert.deepEqual(options,{prefix:'backups/owner/',maxResults:1,autoPaginate:false});
    return [[]];
  }};
  assert.equal(await requireBackupStorage({bucket: () => bucket},'owner'), bucket);
});

test('missing, denied and unconfigured storage fail closed before cleanup', async () => {
  for (const code of [404,403,500]) {
    await assert.rejects(requireBackupStorage({bucket: () => ({
      getFiles: async () => {throw Object.assign(new Error('details-must-not-leak'),{code});},
    })},'owner'), {message:'backup-storage-unavailable'});
  }
  await assert.rejects(requireBackupStorage({bucket: () => {throw new Error('no-default-bucket');}}),
    {message:'backup-storage-unavailable'});
});
