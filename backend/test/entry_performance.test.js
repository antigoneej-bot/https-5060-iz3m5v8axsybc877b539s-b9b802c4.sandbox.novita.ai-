import test from 'node:test';
import assert from 'node:assert/strict';
import {boundedMap} from '../bounded-map.js';
import {getVillageEntry} from '../garden-village.js';
import {memoryDb} from '../testing/memory-db.js';

test('bounded reads overlap, preserve order and never exceed four workers', async () => {
  let active=0, peak=0;
  const releases=[];
  const result=boundedMap([0,1,2,3,4,5],4,async n=>{
    active++; peak=Math.max(peak,active);
    await new Promise(resolve=>releases.push(resolve));
    active--; return n;
  });
  assert.equal(active,4);
  while(releases.length) { releases.shift()(); await Promise.resolve(); await Promise.resolve(); }
  assert.deepEqual(await result,[0,1,2,3,4,5]);
  assert.equal(peak,4);
});
test('bounded read failures reject rather than returning incomplete permission checks', async () => {
  await assert.rejects(boundedMap([1,2],4,async()=>{throw new Error('offline');}), /offline/);
});
test('combined entry retains private/blocked access filtering and own profile', async () => {
  const db=memoryDb({
    'users/alice/neighbors/bob':{status:'accepted'},
    'users/alice/neighbors/carol':{status:'accepted'},
    'villageProfiles/bob':{visibility:'private'},
    'publicGardens/bob':{nickname:'Bob',seedCounts:{pine:1},treeStageIndex:1,equippedDecorationIds:[],visibility:'private'},
    'publicGardens/carol':{nickname:'Carol',seedCounts:{pine:1},treeStageIndex:1,equippedDecorationIds:[],visibility:'public'},
    'users/carol/blockedNeighbors/alice':{createdAt:'2026-11-05'},
  });
  const entry=await getVillageEntry(db,'alice',{}, {stamp:()=> '2026-11-05'});
  assert.match(entry.profile.inviteCode,/^[A-F0-9]{12}$/);
  assert.equal(entry.neighbors.neighbors.some(x=>x.gardenId==='carol'),false);
  const bob=entry.neighbors.neighbors.find(x=>x.gardenId==='bob');
  assert.ok(bob);
  assert.equal(bob.canVisit,false); assert.equal(bob.publicCat,null);
  assert.equal(JSON.stringify(entry).includes('seedCounts'),false);
});
