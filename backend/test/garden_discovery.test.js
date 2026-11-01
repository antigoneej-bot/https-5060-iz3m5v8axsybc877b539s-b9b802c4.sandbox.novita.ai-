import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import * as village from '../garden-village.js';
import {randomPublicGarden, getPublicVisitGarden, setFavoriteGarden, listFavoriteGardens} from '../garden-discovery.js';
import {accountHash, validatePublicSnapshot} from '../policy.js';
import {enforceCommunityPolicy} from '../community-policy.js';

const deps = {stamp: () => '2026-10-31T12:00:00.000Z', random: () => 0, accountExists: async () => true};
const snapshot = {seedCounts: {pine: 3}, equippedDecorationIds: ['bench'], treeStageIndex: 1,
  memoryTreeStage: 2, layout: {version:1, spaces:1, positions:{'decor:bench':[.5,.8]}}, publicCat:{coat:'calico',stage:2}};
async function publish(db, uid, randomVisitOptIn = true) {
  await village.publishVillageGarden(db, uid, {snapshot, nickname: uid, visibility:'public', discoveryOptIn:true, randomVisitOptIn}, deps);
}
test('legacy consent does not enroll anyone in random discovery; explicit choice creates only a minimal index', async () => {
  const db = memoryDb({'publicGardens/bob': snapshot, 'villageProfiles/bob':{visibility:'public',discoveryOptIn:true}});
  assert.equal((await village.getVillageProfile(db,'bob',deps)).randomVisitOptIn,false);
  assert.equal((await randomPublicGarden(db,'alice',{},deps)).garden,null);
  await village.updateVillageProfile(db,'bob',{randomVisitOptIn:true},deps);
  assert.deepEqual(Object.keys(db.rows.get('gardenDiscovery/bob')).sort(),['rank','version']);
  assert.equal((await randomPublicGarden(db,'alice',{},deps)).garden.gardenId,'bob');
  assert.equal([...db.rows.keys()].some(k=>k.includes('/neighbors/')),false);
});
test('withdrawal removes sampling entry and denies stale/favorite/direct random visit; existing records remain', async () => {
  const db=memoryDb({'users/bob/journals/private':{text:'KEEP'}});await publish(db,'bob');
  await setFavoriteGarden(db,'alice',{gardenId:'bob',favorite:true},deps);
  await village.updateVillageProfile(db,'bob',{randomVisitOptIn:false},deps);
  assert.equal(db.rows.has('gardenDiscovery/bob'),false);
  db.rows.set('gardenDiscovery/bob',{rank:0,version:1}); // deliberately stale entry
  assert.equal((await randomPublicGarden(db,'alice',{},deps)).garden,null);
  assert.equal((await listFavoriteGardens(db,'alice',{},deps)).gardens.length,0);
  await assert.rejects(getPublicVisitGarden(db,'alice',{gardenId:'bob'},deps),/garden-not-found/);
  assert.equal(db.rows.get('users/bob/journals/private').text,'KEEP');
});
test('private scope, either-direction block, deleting/deleted and disabled/missing auth accounts cannot be recommended', async () => {
  for(const restriction of ['private','outgoing','incoming','deleting','deleted','missing-auth']) {
    const db=memoryDb();await publish(db,'bob');
    if(restriction==='private')await village.updateVillageProfile(db,'bob',{visibility:'private'},deps);
    if(restriction==='outgoing')await village.blockNeighbor(db,'alice',{gardenId:'bob',blocked:true},deps);
    if(restriction==='incoming')await village.blockNeighbor(db,'bob',{gardenId:'alice',blocked:true},deps);
    if(['deleting','deleted'].includes(restriction))db.rows.set(`accountLocks/${accountHash('bob')}`,{[restriction]:true});
    const d={...deps,accountExists:async()=>restriction!=='missing-auth'};
    assert.equal((await randomPublicGarden(db,'alice',{},d)).garden,null,restriction);
    await assert.rejects(getPublicVisitGarden(db,'alice',{gardenId:'bob'},d),/garden-not-found/);
    await assert.rejects(setFavoriteGarden(db,'alice',{gardenId:'bob',favorite:true},d),/garden-not-found/);
  }
});
test('self and empty pool return empty; a single garden is not shown twice consecutively', async () => {
  const db=memoryDb();await publish(db,'alice');
  assert.equal((await randomPublicGarden(db,'alice',{},deps)).garden,null);
  await publish(db,'bob');
  assert.equal((await randomPublicGarden(db,'alice',{},deps)).garden.gardenId,'bob');
  assert.equal((await randomPublicGarden(db,'alice',{},deps)).garden,null);
});
test('production cryptographic sampling source produces valid range queries without test injection', async () => {
  const db=memoryDb();await publish(db,'bob');
  assert.equal((await randomPublicGarden(db,'alice',{}, {stamp:deps.stamp,accountExists:deps.accountExists})).garden.gardenId,'bob');
});
test('missing account existence dependency fails closed instead of authorizing a stale snapshot',async()=>{
  const db=memoryDb();await publish(db,'bob');
  await assert.rejects(getPublicVisitGarden(db,'alice',{gardenId:'bob'}),/temporarily-unavailable/);
  await assert.rejects(randomPublicGarden(db,'alice'),/temporarily-unavailable/);
});
test('random visits read a bounded minimal index window, never a full users/profile collection', async () => {
  const db=memoryDb();for(let i=0;i<1000;i++){
    const id=`owner${i}`;db.rows.set(`gardenDiscovery/${id}`,{rank:i/1000,version:1});
    db.rows.set(`publicGardens/${id}`,snapshot);db.rows.set(`villageProfiles/${id}`,{visibility:'public',discoveryOptIn:true,randomVisitOptIn:true});
  }
  const original=db.collection.bind(db);let reads=0;
  const wrapped=q=>new Proxy(q,{get(t,k){if(k==='get')return async()=>{const r=await t.get();reads+=r.docs.length;return r;};if(['where','limit','orderBy','startAfter'].includes(k))return(...args)=>wrapped(t[k](...args));return t[k];}});
  db.collection=name=>{assert.equal(name,'gardenDiscovery');return wrapped(original(name));};
  assert.ok((await randomPublicGarden(db,'viewer',{}, {...deps,random:()=>.5})).garden);
  assert.ok(reads<=24);
});
test('old-client discovery withdrawal and later legacy publication cannot restore new random consent', async()=>{
  const db=memoryDb();await publish(db,'bob');
  await village.updateVillageProfile(db,'bob',{discoveryOptIn:false},deps);
  await village.publishVillageGarden(db,'bob',{snapshot,visibility:'public',discoveryOptIn:true},deps);
  assert.equal((await village.getVillageProfile(db,'bob',deps)).randomVisitOptIn,false);
  assert.equal(db.rows.has('gardenDiscovery/bob'),false);
});
test('recent visits do not repeat until the small pool is exhausted, then oldest is reused without consecutive repeats', async () => {
  const db=memoryDb();for(const uid of ['bob','carol','dave'])await publish(db,uid);
  const visited=[];for(let i=0;i<9;i++)visited.push((await randomPublicGarden(db,'alice',{},deps)).garden.gardenId);
  assert.equal(new Set(visited.slice(0,3)).size,3);
  for(let i=1;i<visited.length;i++)assert.notEqual(visited[i],visited[i-1]);
  assert.ok(db.rows.get('users/alice/settings/discoveryHistory').recent.length<=8);
});
test('a withdrawal/block between sampling and commit is rechecked, not authorized by the sampled snapshot', async () => {
  for(const restriction of ['withdraw','block']) {
    const db=memoryDb();await publish(db,'bob');let changed=false;
    const d={...deps,accountExists:async()=>{if(!changed){changed=true;if(restriction==='withdraw')await village.updateVillageProfile(db,'bob',{randomVisitOptIn:false},deps);else await village.blockNeighbor(db,'bob',{gardenId:'alice',blocked:true},deps);}return true;}};
    assert.equal((await randomPublicGarden(db,'alice',{},d)).garden,null);
    assert.equal(db.rows.has('users/alice/settings/discoveryHistory'),false);
  }
});
test('favorites are private identifiers, idempotent, revalidated and removable after access is revoked', async () => {
  const db=memoryDb();await publish(db,'bob');
  for(let i=0;i<2;i++)await setFavoriteGarden(db,'alice',{gardenId:'bob',favorite:true,uid:'bob'},deps);
  assert.deepEqual(db.rows.get('users/alice/favoriteGardens/bob'),{createdAt:deps.stamp()});
  assert.equal([...db.rows.keys()].some(k=>k.startsWith('users/bob/favoriteGardens/')),false);
  assert.equal((await getPublicVisitGarden(db,'alice',{gardenId:'bob'},deps)).garden.isFavorite,true);
  await village.updateVillageProfile(db,'bob',{visibility:'private'},deps);
  assert.equal((await listFavoriteGardens(db,'alice',{},deps)).gardens.length,0);
  await setFavoriteGarden(db,'alice',{gardenId:'bob',favorite:false},deps);
  assert.equal(db.rows.has('users/alice/favoriteGardens/bob'),false);
  await assert.rejects(setFavoriteGarden(db,'alice',{gardenId:'alice',favorite:true},deps),/invalid-target/);
});
test('favorite cap and owner/action-bound pagination cannot read another owner list', async () => {
  const db=memoryDb();await publish(db,'bob');await publish(db,'carol');
  for(const id of ['bob','carol'])await setFavoriteGarden(db,'alice',{gardenId:id,favorite:true},deps);
  const first=await listFavoriteGardens(db,'alice',{pageSize:1},deps);
  assert.equal(first.gardens.length,1);assert.ok(first.nextCursor);
  const next=await listFavoriteGardens(db,'alice',{pageSize:1,cursor:first.nextCursor},deps);
  assert.notEqual(first.gardens[0].gardenId,next.gardens[0].gardenId);
  await assert.rejects(listFavoriteGardens(db,'mallory',{cursor:first.nextCursor},deps),/invalid-cursor/);
  for(let i=0;i<200;i++)db.rows.set(`users/full/favoriteGardens/target${i}`,{createdAt:deps.stamp()});
  await assert.rejects(setFavoriteGarden(db,'full',{gardenId:'bob',favorite:true},deps),/favorites-limit/);
});
test('public response whitelists nested appearance and reaction fields, never memory/letter/email payloads', async () => {
  const db=memoryDb();await publish(db,'bob');
  const garden=db.rows.get('publicGardens/bob');
  Object.assign(garden,{email:'SECRET_EMAIL',letters:['SECRET_LETTER'],memoryTree:{date:'SECRET_DATE',text:'SECRET_MEMORY'},
    publicCat:{coat:'calico',stage:2,name:'SECRET_CAT_NAME',email:'SECRET_CAT_EMAIL'},
    seedCounts:{pine:3,privateDiary:'SECRET_DIARY'}, reactions:[{kind:'heart',expiresAt:'2099-01-01T00:00:00.000Z',text:'SECRET_REACTION'}]});
  const result=await getPublicVisitGarden(db,'alice',{gardenId:'bob'},deps);
  assert.equal(JSON.stringify(result).includes('SECRET'),false);
  assert.deepEqual(result.garden.publicCat,{coat:'calico',stage:2});
  garden.layout={...snapshot.layout,privateMemory:'SECRET_LAYOUT'};
  assert.equal((await getPublicVisitGarden(db,'alice',{gardenId:'bob'},deps)).garden.layout,null);
  assert.equal(validatePublicSnapshot({...snapshot,publicCat:{coat:'ginger',stage:1,name:'private'}}),false);
});
test('appearance-only and legacy publication never enable or restore the new consent; explicit opt-in still needs community policy', async () => {
  const db=memoryDb();await publish(db,'bob',false);
  await village.publishVillageGarden(db,'bob',{snapshot,appearanceOnly:true},deps);
  assert.equal(db.rows.has('gardenDiscovery/bob'),false);
  await assert.rejects(enforceCommunityPolicy(db,'bob','updateVillageProfile'),/community-consent-required/);
  assert.equal((await village.getVillageProfile(db,'bob',deps)).randomVisitOptIn,false);
});

function seedDiscoveryPool(db, count, rank = i => i / count) {
  for (let i = 0; i < count; i++) {
    const id = `candidate${String(i).padStart(3, '0')}`;
    db.rows.set(`gardenDiscovery/${id}`, {rank: rank(i), version: 1});
    db.rows.set(`publicGardens/${id}`, snapshot);
    db.rows.set(`villageProfiles/${id}`, {visibility: 'public', discoveryOptIn: true, randomVisitOptIn: true});
  }
}

test('discovery advances beyond a full rejected page, including equal-rank entries', async () => {
  const db = memoryDb(); seedDiscoveryPool(db, 30, () => .5);
  const checked = [];
  const result = await randomPublicGarden(db, 'viewer', {}, {...deps, accountExists: async id => {
    checked.push(id); return id === 'candidate029';
  }});
  assert.equal(result.garden.gardenId, 'candidate029');
  assert.equal(new Set(checked).size, checked.length);
  assert.ok(checked.length > 24);
});

test('discovery wraps below the pivot after rejecting a full higher-rank page', async () => {
  const db = memoryDb(); seedDiscoveryPool(db, 30);
  const result = await randomPublicGarden(db, 'viewer', {}, {...deps, random: () => .2,
    accountExists: async id => id === 'candidate000'});
  assert.equal(result.garden.gardenId, 'candidate000');
});

test('additional discovery pages still enforce block and withdrawn consent', async () => {
  const db = memoryDb(); seedDiscoveryPool(db, 28, () => .5);
  await village.blockNeighbor(db, 'candidate024', {gardenId: 'viewer', blocked: true}, deps);
  db.rows.get('villageProfiles/candidate025').randomVisitOptIn = false;
  const result = await randomPublicGarden(db, 'viewer', {}, {...deps,
    accountExists: async id => ['candidate024', 'candidate025', 'candidate027'].includes(id)});
  assert.equal(result.garden.gardenId, 'candidate027');
});

test('all-rejected pools stop after 96 unique candidates rather than scanning all accounts', async () => {
  const db = memoryDb(); seedDiscoveryPool(db, 1000);
  const checked = [];
  const result = await randomPublicGarden(db, 'viewer', {}, {...deps, accountExists: async id => {
    checked.push(id); return false;
  }});
  assert.equal(result.garden, null);
  assert.equal(checked.length, 96);
  assert.equal(new Set(checked).size, 96);
  assert.equal(db.rows.has('users/viewer/settings/discoveryHistory'), false);
});
