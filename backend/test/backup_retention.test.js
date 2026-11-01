import test from 'node:test';import assert from 'node:assert/strict';import {keepBackupIds} from '../backup-retention.js';
test('frequent edits preserve older daily recovery points while retaining at most ten copies',()=>{
 const versions=[...Array.from({length:20},(_,i)=>({id:`today-${i}`,day:'2026-10-24'})),...Array.from({length:8},(_,i)=>({id:`older-${i}`,day:`2026-10-${23-i}`}))];
 const kept=keepBackupIds(versions);assert.equal(kept.size,10);
 for(let i=0;i<5;i++){assert(kept.has(`today-${i}`));assert(kept.has(`older-${i}`));}
});
test('one day or fewer than ten backups retains the latest available copies',()=>{
 const versions=Array.from({length:12},(_,i)=>({id:String(i),day:'2026-10-24'}));
 assert.deepEqual([...keepBackupIds(versions)],Array.from({length:10},(_,i)=>String(i)));
 assert.equal(keepBackupIds(versions.slice(0,2)).size,2);
});
