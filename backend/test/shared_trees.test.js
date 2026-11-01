import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {accountHash} from '../policy.js';
import * as tree from '../shared-trees.js';
const now = Date.parse('2026-10-21T15:01:00Z'); // Korean date is Oct 22.
const deps = {now, stamp: () => new Date(now).toISOString(), hasActiveSubscription: async uid => uid === 'host'};
function prepared() { return memoryDb({
  'users/host/neighbors/guest': {status: 'accepted'},
  'users/guest/neighbors/host': {status: 'accepted'},
  'villageProfiles/host': {nickname: '나무'}, 'villageProfiles/guest': {nickname: '꽃'},
}); }
const input = {gardenId: 'guest', requestId: 'create-request-123456', name: '우리의 겨울', anniversaryOn: '2026-10-21'};
async function accepted() {
  const db = prepared(); const created = await tree.createSharedTree(db, 'host', input, deps);
  await tree.respondSharedTree(db, 'guest', {id: created.tree.id, accept: true}, deps);
  return {db, id: created.tree.id};
}
test('only server-confirmed subscribers create; free invited guest can accept and water', async () => {
  const db = prepared();
  await assert.rejects(tree.createSharedTree(db, 'host', input, {}), /subscription-required/);
  await assert.rejects(tree.createSharedTree(db, 'host', input, {...deps, hasActiveSubscription: async () => false}), /subscription-required/);
  const {tree: created} = await tree.createSharedTree(db, 'host', input, deps);
  assert.equal(created.status, 'invited');
  await assert.rejects(tree.waterSharedTree(db, 'guest', {id: created.id}, deps), /invitation-required/);
  await tree.respondSharedTree(db, 'guest', {id: created.id, accept: true}, deps);
  const {tree: watered} = await tree.waterSharedTree(db, 'guest', {id: created.id}, {...deps, hasActiveSubscription: async () => false});
  assert.equal(watered.wateredToday, true); assert.equal(watered.myLastWateredOn, '2026-10-22');
});
test('creation is owner-scoped idempotent and conflicts reject changed intent', async () => {
  const db = prepared();
  const result = await tree.createSharedTree(db, 'host', input, deps);
  assert.deepEqual(await tree.createSharedTree(db, 'host', input, {...deps, hasActiveSubscription: async () => false}), result);
  await assert.rejects(tree.createSharedTree(db, 'host', {...input, name: '다른 제목'}, deps), /request-conflict/);
  assert.equal((await tree.listSharedTrees(db, 'guest', {}, deps)).trees.length, 1);
});
test('strangers and host cannot accept on behalf of invitee; private input is rejected', async () => {
  const db = prepared(); const {tree: created} = await tree.createSharedTree(db, 'host', input, deps);
  await assert.rejects(tree.respondSharedTree(db, 'host', {id: created.id, accept: true}, deps), /invitation-required/);
  for (const action of [tree.getSharedTree, tree.waterSharedTree, tree.leaveSharedTree]) {
    await assert.rejects(action(db, 'stranger', {id: created.id}, deps), /not-found/);
  }
  await assert.rejects(tree.createSharedTree(db, 'host', {...input, privateLetter: 'secret'}, deps), /invalid-shared-tree/);
  await assert.rejects(tree.createSharedTree(db, 'host', {...input, anniversaryOn: '2026-02-31'}, deps), /invalid-shared-tree/);
});
test('both neighbors must still consent; neither private garden visibility nor absent premium blocks invitee', async () => {
  const db = prepared(); db.rows.set('villageProfiles/guest', {visibility: 'private'});
  const {tree: created} = await tree.createSharedTree(db, 'host', input, deps);
  assert.equal(created.name, input.name);
  db.rows.delete('users/guest/neighbors/host');
  await assert.rejects(tree.getSharedTree(db, 'host', {id: created.id}, deps), /not-found/);
  assert.deepEqual((await tree.listSharedTrees(db, 'guest', {}, deps)).trees, []);
});
test('watering race and retries grow only once per Korean date, absence never decays', async () => {
  const {db, id} = await accepted();
  await Promise.all([tree.waterSharedTree(db, 'host', {id}, deps), tree.waterSharedTree(db, 'guest', {id}, deps), tree.waterSharedTree(db, 'host', {id}, deps)]);
  assert.equal((await tree.getSharedTree(db, 'host', {id}, deps)).tree.activeDays, 1);
  const later = {...deps, now: now + 30 * 86400000};
  const before = (await tree.getSharedTree(db, 'host', {id}, later)).tree;
  assert.equal(before.activeDays, 1); assert.equal(before.wateredToday, false);
  assert.equal((await tree.waterSharedTree(db, 'host', {id}, later)).tree.activeDays, 2);
});
test('after subscription expiry existing tree and free notes still work', async () => {
  const {db, id} = await accepted();
  const free = {...deps, hasActiveSubscription: async () => false};
  await tree.waterSharedTree(db, 'host', {id}, free);
  const result = await tree.addSharedTreeNote(db, 'guest', {id, requestId: 'note-request-123456', text: '다녀갔어'}, free);
  assert.equal(result.tree.notes[0].text, '다녀갔어');
  assert.equal(result.tree.notes[0].mine, true);
  assert.equal(result.tree.notes[0].authorUid, undefined);
});
test('notes deduplicate concurrent retries; deleted note cannot resurrect through replay', async () => {
  const {db, id} = await accepted(); const note = {id, requestId: 'note-request-123456', text: '응원해'};
  await Promise.all([tree.addSharedTreeNote(db, 'guest', note, deps), tree.addSharedTreeNote(db, 'guest', note, deps)]);
  const n = (await tree.getSharedTree(db, 'guest', {id}, deps)).tree.notes[0];
  await assert.rejects(tree.addSharedTreeNote(db, 'guest', {...note, text: '변경'}, deps), /request-conflict/);
  await assert.rejects(tree.deleteSharedTreeNote(db, 'host', {id, noteId: n.id}, deps), /not-found/);
  await tree.deleteSharedTreeNote(db, 'guest', {id, noteId: n.id}, deps);
  assert.equal((await tree.addSharedTreeNote(db, 'guest', note, deps)).tree.notes.length, 0);
});
test('leaving revokes guest access, preserves host archive and prevents further watering', async () => {
  const {db, id} = await accepted();
  await tree.leaveSharedTree(db, 'guest', {id}, deps);
  await assert.rejects(tree.getSharedTree(db, 'guest', {id}, deps), /not-found/);
  assert.equal((await tree.getSharedTree(db, 'host', {id}, deps)).tree.status, 'archived');
  await assert.rejects(tree.waterSharedTree(db, 'host', {id}, deps), /invitation-required/);
  assert.equal((await tree.listSharedTrees(db, 'guest', {}, deps)).trees.length, 0);
});
test('blocks, removed links and deletion tombstones cover all existing and archived access', async () => {
  for (const blocked of ['block', 'remove', 'delete']) {
    const {db, id} = await accepted();
    if (blocked === 'block') db.rows.set('users/guest/blockedNeighbors/host', {});
    if (blocked === 'remove') db.rows.delete('users/host/neighbors/guest');
    if (blocked === 'delete') db.rows.set(`accountLocks/${accountHash('guest')}`, {deleting: true});
    await assert.rejects(tree.getSharedTree(db, 'host', {id}, deps), /not-found/);
    await assert.rejects(tree.addSharedTreeNote(db, 'host', {id, requestId: 'note-request-123456', text: 'x'}, deps), /not-found/);
  }
});
test('account deletion cleans all shared content and both indexes, including left trees', async () => {
  const {db, id} = await accepted();
  await tree.addSharedTreeNote(db, 'guest', {id, requestId: 'note-request-123456', text: '내 메모'}, deps);
  await tree.leaveSharedTree(db, 'guest', {id}, deps);
  await tree.removeSharedTreeAccount(db, 'guest');
  assert.equal([...db.rows.keys()].some(p => p.startsWith('sharedTrees/')), false);
  assert.equal([...db.rows.keys()].some(p => p.endsWith(`/sharedTrees/${id}`)), false);
});
test('pending invitation never exposes activity or notes accidentally stored on root', async () => {
  const db = prepared(); const {tree: created} = await tree.createSharedTree(db, 'host', input, deps);
  db.rows.get(`sharedTrees/${created.id}`).notes.push({id: 'legacy', text: 'hidden until accepted', authorUid: 'host'});
  assert.deepEqual((await tree.getSharedTree(db, 'guest', {id: created.id}, deps)).tree.notes, []);
});
test('host-only style changes need verified entitlement; retained style survives downgrade', async () => {
  const {db, id} = await accepted();
  await assert.rejects(tree.setSharedTreeStyle(db, 'guest', {id, style: 'blossom'}, {...deps, hasActiveSubscription: async () => true}), /not-found/);
  await assert.rejects(tree.setSharedTreeStyle(db, 'host', {id, style: 'blossom'}, {...deps, hasActiveSubscription: async () => false}), /subscription-required/);
  await tree.setSharedTreeStyle(db, 'host', {id, style: 'blossom'}, deps);
  const result = await tree.getSharedTree(db, 'guest', {id}, {...deps, hasActiveSubscription: async () => false});
  assert.equal(result.tree.style, 'blossom');
});

test('former participant can find and erase only their own notes after revoke or block', async () => {
  const {db, id} = await accepted();
  await tree.addSharedTreeNote(db, 'host', {id, requestId: 'host-note-12345678', text: 'host private shared words'}, deps);
  const {tree: withNote} = await tree.addSharedTreeNote(db, 'guest', {id, requestId: 'guest-note-12345678', text: '내가 쓴 말'}, deps);
  const note = withNote.notes.find(n => n.mine);
  await tree.leaveSharedTree(db, 'host', {id}, deps);
  db.rows.set('users/host/blockedNeighbors/guest', {});
  await assert.rejects(tree.getSharedTree(db, 'guest', {id}, deps), /not-found/);
  const own = await tree.listMySharedTreeNotes(db, 'guest');
  assert.equal(own.notes.length, 1);
  assert.deepEqual(Object.keys(own.notes[0]).sort(), ['createdAt', 'id', 'text', 'treeId']);
  assert.equal(own.notes[0].text, '내가 쓴 말');
  assert.equal(JSON.stringify(own).includes('host private shared words'), false);
  assert.deepEqual(await tree.listMySharedTreeNotes(db, 'stranger'), {notes: [], nextCursor: null});
  await assert.rejects(tree.deleteSharedTreeNote(db, 'stranger', {id, noteId: note.id}, deps), /not-found/);
  await tree.deleteSharedTreeNote(db, 'guest', {id, noteId: note.id}, deps);
  assert.deepEqual(await tree.deleteSharedTreeNote(db, 'guest', {id, noteId: note.id}, deps), {deleted: true});
  assert.equal(db.rows.get(`sharedTrees/${id}`).notes.length, 1);
});

test('remove and block generations prevent reconnect from reviving old shared consent', async () => {
  const village = await import('../garden-village.js');
  for (const mode of ['remove', 'block']) {
    const {db, id} = await accepted();
    if (mode === 'remove') await village.removeNeighbor(db, 'host', {gardenId: 'guest'});
    else {
      await village.blockNeighbor(db, 'host', {gardenId: 'guest', blocked: true}, deps);
      await village.blockNeighbor(db, 'host', {gardenId: 'guest', blocked: false}, deps);
    }
    // Ordinary neighbor approval is independent of a new tree invitation.
    db.rows.set('users/host/neighbors/guest', {status: 'accepted'});
    db.rows.set('users/guest/neighbors/host', {status: 'accepted'});
    await assert.rejects(tree.getSharedTree(db, 'host', {id}, deps), /not-found/);
    await assert.rejects(tree.respondSharedTree(db, 'guest', {id, accept: true}, deps), /not-found/);
    const next = await tree.createSharedTree(db, 'host', {...input, requestId: 'fresh-create-12345678'}, deps);
    assert.equal(next.tree.status, 'invited');
    await assert.rejects(tree.waterSharedTree(db, 'guest', {id: next.tree.id}, deps), /invitation-required/);
    await tree.respondSharedTree(db, 'guest', {id: next.tree.id, accept: true}, deps);
    assert.equal((await tree.waterSharedTree(db, 'guest', {id: next.tree.id}, deps)).tree.wateredToday, true);
  }
});

test('leave and decline lost-response retries succeed only for the original participants', async () => {
  const {db, id} = await accepted();
  await tree.leaveSharedTree(db, 'guest', {id}, deps);
  assert.deepEqual(await tree.leaveSharedTree(db, 'guest', {id}, deps), {left: true});
  await assert.rejects(tree.leaveSharedTree(db, 'stranger', {id}, deps), /not-found/);
  const other = prepared();
  const result = await tree.createSharedTree(other, 'host', input, deps);
  await tree.respondSharedTree(other, 'guest', {id: result.tree.id, accept: false}, deps);
  assert.deepEqual(await tree.respondSharedTree(other, 'guest', {id: result.tree.id, accept: false}, deps), {left: true});
  await assert.rejects(tree.respondSharedTree(other, 'stranger', {id: result.tree.id, accept: false}, deps), /invitation-required/);
});

test('real neighbor actions alone generate unread badges and marking a shown revision preserves newer arrivals', async () => {
  const db = prepared();
  const {tree: created} = await tree.createSharedTree(db, 'host', input, deps);
  const id = created.id;
  assert.equal(created.unreadCount, 0);
  let guest = (await tree.getSharedTree(db, 'guest', {id}, deps)).tree;
  assert.equal(guest.unreadCount, 1);
  assert.deepEqual(guest.activities.map(a => a.type), ['invited']);
  await tree.markSharedTreeSeen(db, 'guest', {id, version: guest.activityVersion}, deps);
  await tree.respondSharedTree(db, 'guest', {id, accept: true}, deps);
  const shown = (await tree.getSharedTree(db, 'host', {id}, deps)).tree;
  assert.equal(shown.unreadCount, 1);
  await tree.waterSharedTree(db, 'guest', {id}, deps);
  await tree.waterSharedTree(db, 'guest', {id}, deps); // Daily retry adds no second activity.
  await tree.markSharedTreeSeen(db, 'host', {id, version: shown.activityVersion}, deps);
  const result = (await tree.getSharedTree(db, 'host', {id}, deps)).tree;
  assert.equal(result.unreadCount, 1);
  assert.equal(result.activities.at(-1).type, 'watered');
  assert.equal(result.activities.at(-1).mine, false);
  assert.equal(result.activities.at(-1).authorUid, undefined);
  assert.equal(result.activities.filter(a => a.type === 'watered').length, 1);
  await assert.rejects(tree.markSharedTreeSeen(db, 'stranger', {id, version: 100}, deps), /not-found/);
});

test('shared note reports require membership, deduplicate, and never copy private text', async () => {
  const {db,id} = await accepted();
  await tree.addSharedTreeNote(db,'host',{id,requestId:'note-request-12345',text:'shared content'},deps);
  const note=db.rows.get(`sharedTrees/${id}`).notes[0];
  await assert.rejects(tree.reportSharedTreeNote(db,'stranger',{id,noteId:note.id},deps),/not-found/);
  await assert.rejects(tree.reportSharedTreeNote(db,'host',{id,noteId:note.id},deps),/invalid-shared-tree-note/);
  await tree.reportSharedTreeNote(db,'guest',{id,noteId:note.id},deps);
  await tree.reportSharedTreeNote(db,'guest',{id,noteId:note.id},deps);
  const reports=[...db.rows].filter(([k])=>k.startsWith('villageReports/'));
  assert.equal(reports.length,1);
  assert.equal(reports[0][1].targetId,'host');
  assert.equal(JSON.stringify(reports[0][1]).includes('shared content'),false);
  const {resolveGardenReport}=await import('../community-policy.js');
  await resolveGardenReport(db,reports[0][0].split('/')[1],'hide','operator',deps.stamp);
  assert.equal(db.rows.get(`sharedTrees/${id}`).notes.length,0);
  assert.equal(db.rows.get(`sharedTrees/${id}`).activities.some(a=>a.noteId===note.id),false);
  assert.equal(db.rows.has('users/host/sharedTrees/'+id),true);
});
