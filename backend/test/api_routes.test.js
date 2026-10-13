import test from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

test('actual gardenApi handlers: delivery, retries, currency rejection and deletion', () => {
  const run = spawnSync(process.execPath, ['--experimental-vm-modules',
    fileURLToPath(new URL('../testing/api-regression.mjs', import.meta.url))],
    {encoding: 'utf8', timeout: 15000});
  assert.equal(run.status, 0, `${run.stdout}\n${run.stderr}`);
});
