import {createHash} from 'node:crypto';
import {accountHash} from './policy.js';

// Shared trees contain only explicitly shared notes. No journal, emotion,
// care history or private plant-memory field is accepted or copied here.
const refFor = (db, id) => db.doc(`sharedTrees/${id}`);
const indexFor = (db, uid, id) => db.doc(`users/${uid}/sharedTrees/${id}`);
export const sharedTreePairRef = (db, a, b) => db.doc(`sharedTreePairs/${digest(...[a, b].sort())}`);
const digest = (...values) => createHash('sha256').update(JSON.stringify(values)).digest('hex');
const safeId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value);
const requestId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{16,100}$/.test(value);
const iso = value => value?.toDate?.().toISOString() ?? (typeof value === 'string' ? value : null);
const clock = deps => deps.now ?? Date.now();
const stamp = deps => deps.stamp?.() ?? new Date(clock(deps)).toISOString();
const koreanDay = deps => new Date(clock(deps) + 9 * 3600000).toISOString().slice(0, 10);
function validDay(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    Number.isFinite(Date.parse(value)) && new Date(value).toISOString().slice(0, 10) === value &&
    value >= '1900-01-01' && value <= '2200-12-31';
}
function text(value, max, required = true) {
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim()) || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(value)) throw new Error('invalid-shared-tree');
  return value.trim();
}
function exactKeys(body, allowed) {
  if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).some(k => k !== 'action' && !allowed.includes(k))) throw new Error('invalid-shared-tree');
}
function treeId(body) {
  if (!safeId(body?.id)) throw new Error('invalid-shared-tree');
  return body.id;
}
async function pairAccess(db, host, guest, tx, revision) {
  const get = ref => tx ? tx.get(ref) : ref.get();
  const [a, b, outBlock, inBlock, hostLock, guestLock, pair] = await Promise.all([
    get(db.doc(`users/${host}/neighbors/${guest}`)), get(db.doc(`users/${guest}/neighbors/${host}`)),
    get(db.doc(`users/${host}/blockedNeighbors/${guest}`)), get(db.doc(`users/${guest}/blockedNeighbors/${host}`)),
    get(db.doc(`accountLocks/${accountHash(host)}`)), get(db.doc(`accountLocks/${accountHash(guest)}`)),
    get(sharedTreePairRef(db, host, guest)),
  ]);
  return (revision === undefined || (pair.data()?.revision ?? 0) === revision) && a.data()?.status === 'accepted' && b.data()?.status === 'accepted' &&
    !outBlock.exists && !inBlock.exists &&
    !hostLock.data()?.deleting && !hostLock.data()?.deleted &&
    !guestLock.data()?.deleting && !guestLock.data()?.deleted;
}
async function authorized(db, uid, id, tx, {active = false} = {}) {
  const snap = await (tx ? tx.get(refFor(db, id)) : refFor(db, id).get());
  const data = snap.data();
  if (!snap.exists || (uid !== data.hostUid && uid !== data.guestUid) ||
      (uid === data.guestUid && !['invited', 'accepted'].includes(data.guestStatus))) throw new Error('shared-tree-not-found');
  // A retained host archive is still subject to current bilateral blocks,
  // neighbor removal and either account's deletion tombstone.
  if (!await pairAccess(db, data.hostUid, data.guestUid, tx, data.relationshipRevision ?? 0)) throw new Error('shared-tree-not-found');
  if (active && (data.status !== 'active' || data.guestStatus !== 'accepted')) throw new Error('shared-tree-invitation-required');
  return data;
}
function activity(data, uid, type, deps, extra = {}) {
  const version = (data.activityVersion ?? 0) + 1;
  return {activityVersion: version, activities: [...data.activities ?? [],
    {version, authorUid: uid, type, createdAt: new Date(clock(deps)).toISOString(), ...extra}].slice(-20)};
}
function visibleActivities(data, uid, accepted) {
  return (data.activities ?? []).filter(a => accepted || a.type === 'invited');
}
function dto(id, data, uid, deps) {
  const accepted = data.guestStatus === 'accepted' || (uid === data.hostUid && data.status === 'archived');
  const day = koreanDay(deps);
  const activities = visibleActivities(data, uid, accepted);
  const seen = data.seenVersions?.[uid] ?? 0;
  return {
    activityVersion: data.activityVersion ?? 0,
    unreadCount: activities.filter(a => a.authorUid !== uid && a.version > seen).length,
    activities: activities.map(a => ({type: a.type, mine: a.authorUid === uid, createdAt: a.createdAt,
      version: a.version, unread: a.authorUid !== uid && a.version > seen})),
    id, name: data.name, anniversaryOn: data.anniversaryOn, style: data.style ?? 'sage',
    hostName: data.hostName ?? null, guestName: data.guestName ?? null,
    myRole: uid === data.hostUid ? 'host' : 'guest', status: data.status,
    guestStatus: data.guestStatus, createdAt: iso(data.createdAt),
    activeDays: accepted ? data.activeDays ?? 0 : 0,
    wateredToday: accepted && data.watered?.[uid] === day,
    myLastWateredOn: accepted ? data.watered?.[uid] ?? null : null,
    neighborLastWateredOn: accepted ? data.watered?.[uid === data.hostUid ? data.guestUid : data.hostUid] ?? null : null,
    notes: accepted ? (data.notes ?? []).map(n => ({id: n.id, text: n.text, mine: n.authorUid === uid,
      authorName: n.authorUid === data.hostUid ? data.hostName ?? null : data.guestName ?? null,
      createdAt: iso(n.createdAt)})) : [],
  };
}

export async function createSharedTree(db, uid, body, deps = {}) {
  exactKeys(body, ['gardenId', 'requestId', 'name', 'anniversaryOn']);
  if (!safeId(body.gardenId) || body.gardenId === uid || !requestId(body.requestId) || !validDay(body.anniversaryOn)) throw new Error('invalid-shared-tree');
  const name = text(body.name, 40);
  const id = digest('tree', uid, body.requestId);
  const fingerprint = digest(body.gardenId, name, body.anniversaryOn);
  const previous = await refFor(db, id).get();
  if (previous.exists) {
    if (previous.data().fingerprint !== fingerprint) throw new Error('request-conflict');
    return getSharedTree(db, uid, {id}, deps);
  }
  if (!deps.hasActiveSubscription || !await deps.hasActiveSubscription(uid)) throw new Error('subscription-required');
  await db.runTransaction(async tx => {
    const existing = await tx.get(refFor(db, id));
    if (existing.exists) {
      if (existing.data().fingerprint !== fingerprint) throw new Error('request-conflict');
      return;
    }
    if (!await pairAccess(db, uid, body.gardenId, tx)) throw new Error('neighbor-required');
    const [host, guest, pair] = await Promise.all([
      tx.get(db.doc(`villageProfiles/${uid}`)), tx.get(db.doc(`villageProfiles/${body.gardenId}`)),
      tx.get(sharedTreePairRef(db, uid, body.gardenId)),
    ]);
    tx.set(refFor(db, id), {hostUid: uid, guestUid: body.gardenId, hostName: host.data()?.nickname ?? null,
      guestName: guest.data()?.nickname ?? null, name, anniversaryOn: body.anniversaryOn,
      relationshipRevision: pair.data()?.revision ?? 0,
      ...activity({}, uid, 'invited', deps), seenVersions: {},
      fingerprint, style: 'sage', guestStatus: 'invited', status: 'invited', createdAt: stamp(deps), notes: [], watered: {}, activeDays: 0});
    tx.set(indexFor(db, uid, id), {id});
    tx.set(indexFor(db, body.gardenId, id), {id});
  });
  return getSharedTree(db, uid, {id}, deps);
}
export async function getSharedTree(db, uid, body, deps = {}) {
  exactKeys(body, ['id']);
  const id = treeId(body);
  const data = await db.runTransaction(tx => authorized(db, uid, id, tx));
  return {tree: dto(id, data, uid, deps)};
}
export async function listSharedTrees(db, uid, body = {}, deps = {}) {
  exactKeys(body, ['cursor']);
  if (body.cursor != null && !safeId(body.cursor)) throw new Error('invalid-shared-tree');
  let query = db.collection(`users/${uid}/sharedTrees`).orderBy('__name__');
  if (body.cursor) query = query.startAfter(body.cursor);
  const snap = await query.limit(21).get();
  const rows = snap.docs.slice(0, 20);
  const trees = [];
  for (const row of rows) {
    try { trees.push((await getSharedTree(db, uid, {id: row.id}, deps)).tree); }
    catch (e) { if (e.message !== 'shared-tree-not-found') throw e; }
  }
  return {trees, nextCursor: snap.docs.length > 20 ? rows.at(-1).id : null};
}
export async function respondSharedTree(db, uid, body, deps = {}) {
  exactKeys(body, ['id', 'accept']);
  const id = treeId(body);
  if (typeof body.accept !== 'boolean') throw new Error('invalid-shared-tree');
  await db.runTransaction(async tx => {
    const snap = await tx.get(refFor(db, id));
    const participant = snap.data();
    if (!snap.exists || uid !== participant.guestUid) throw new Error('shared-tree-invitation-required');
    // A lost decline response may be retried after the index/access was removed.
    if (!body.accept && participant.guestStatus === 'declined') return;
    const data = await authorized(db, uid, id, tx);
    if (data.guestStatus === 'accepted' && body.accept) return;
    if (data.guestStatus !== 'invited') throw new Error('shared-tree-invitation-required');
    tx.update(refFor(db, id), {guestStatus: body.accept ? 'accepted' : 'declined', status: body.accept ? 'active' : 'archived', updatedAt: stamp(deps),
      ...activity(data, uid, body.accept ? 'accepted' : 'declined', deps)});
    if (!body.accept) tx.delete(indexFor(db, uid, id));
  });
  return body.accept ? getSharedTree(db, uid, {id}, deps) : {left: true};
}
export async function waterSharedTree(db, uid, body, deps = {}) {
  exactKeys(body, ['id']);
  const id = treeId(body);
  await db.runTransaction(async tx => {
    const data = await authorized(db, uid, id, tx, {active: true});
    const day = koreanDay(deps);
    if (data.watered?.[uid] === day) return;
    // A day grows once even when both friends water concurrently; no streak loss.
    tx.update(refFor(db, id), {...activity(data, uid, 'watered', deps), watered: {...data.watered, [uid]: day},
      activeDays: (data.activeDays ?? 0) + (data.lastGrowthDay === day ? 0 : 1), lastGrowthDay: day, updatedAt: stamp(deps)});
  });
  return getSharedTree(db, uid, {id}, deps);
}
export async function addSharedTreeNote(db, uid, body, deps = {}) {
  exactKeys(body, ['id', 'requestId', 'text']);
  const id = treeId(body);
  if (!requestId(body.requestId)) throw new Error('invalid-shared-tree');
  let note;
  try { note = text(body.text, 300); } catch { throw new Error('invalid-shared-tree-note'); }
  const noteId = digest(uid, body.requestId);
  const operationRef = db.doc(`sharedTrees/${id}/operations/${noteId}`);
  await db.runTransaction(async tx => {
    const data = await authorized(db, uid, id, tx, {active: true});
    const operation = await tx.get(operationRef);
    if (operation.exists) {
      if (operation.data().fingerprint !== digest(note)) throw new Error('request-conflict');
      return;
    }
    if ((data.notes ?? []).length >= 100) throw new Error('shared-tree-note-limit');
    tx.update(refFor(db, id), {...activity(data, uid, 'note', deps, {noteId}), notes: [...data.notes ?? [], {id: noteId, authorUid: uid, text: note, createdAt: new Date(clock(deps)).toISOString()}], updatedAt: stamp(deps)});
    tx.set(operationRef, {fingerprint: digest(note)});
  });
  return getSharedTree(db, uid, {id}, deps);
}
// Participants retain deletion control over their own words after disconnect.
// This route returns no partner content or tree metadata, even when blocked.
async function ownedTree(db, uid, id, tx) {
  const snap = await (tx ? tx.get(refFor(db, id)) : refFor(db, id).get());
  const data = snap.data();
  if (!snap.exists || ![data.hostUid, data.guestUid].includes(uid)) throw new Error('shared-tree-not-found');
  return data;
}
export async function listMySharedTreeNotes(db, uid, body = {}) {
  exactKeys(body, ['cursor']);
  if (body.cursor != null && !safeId(body.cursor)) throw new Error('invalid-shared-tree');
  const pages = await Promise.all(['hostUid', 'guestUid'].map(field => {
    let query = db.collection('sharedTrees').where(field, '==', uid).orderBy('__name__');
    if (body.cursor) query = query.startAfter(body.cursor);
    return query.limit(21).get();
  }));
  const rows = [...new Map(pages.flatMap(p => p.docs.map(d => [d.id, d]))).values()].sort((a, b) => a.id.localeCompare(b.id));
  const selected = rows.slice(0, 20);
  return {notes: selected.flatMap(row => (row.data().notes ?? []).filter(n => n.authorUid === uid).map(n =>
    ({treeId: row.id, id: n.id, text: n.text, createdAt: iso(n.createdAt)}))),
    nextCursor: rows.length > 20 ? selected.at(-1).id : null};
}
export async function deleteSharedTreeNote(db, uid, body, deps = {}) {
  exactKeys(body, ['id', 'noteId']);
  const id = treeId(body);
  if (!safeId(body.noteId)) throw new Error('invalid-shared-tree-note');
  const visible = await db.runTransaction(async tx => {
    const data = await ownedTree(db, uid, id, tx);
    const note = (data.notes ?? []).find(n => n.id === body.noteId);
    if (note && note.authorUid !== uid) throw new Error('shared-tree-not-found');
    let canRead = false;
    try { await authorized(db, uid, id, tx); canRead = true; }
    catch (e) { if (e.message !== 'shared-tree-not-found') throw e; }
    const next = {...data, notes: (data.notes ?? []).filter(n => n.id !== body.noteId),
      activities: (data.activities ?? []).filter(a => a.noteId !== body.noteId)};
    if (note) tx.update(refFor(db, id), {notes: next.notes, activities: next.activities, updatedAt: stamp(deps)});
    return canRead ? next : null;
  });
  // Preserve the active-tree response consumed by older installed clients.
  // A disconnected author receives only success, without reloading partner data.
  return {deleted: true, ...(visible ? {tree: dto(id, visible, uid, deps)} : {})};
}

export async function leaveSharedTree(db, uid, body, deps = {}) {
  exactKeys(body, ['id']);
  const id = treeId(body);
  await db.runTransaction(async tx => {
    const data = await ownedTree(db, uid, id, tx);
    // Only an actual former participant can retry; no public existence oracle.
    if (data.status === 'archived') return;
    // Leaving is a privacy action and remains possible after unlink/block.
    tx.update(refFor(db, id), {status: 'archived', guestStatus: uid === data.hostUid ? 'revoked' : 'left', updatedAt: stamp(deps)});
    tx.delete(indexFor(db, data.guestUid, id));
  });
  return {left: true};
}
export async function markSharedTreeSeen(db, uid, body, deps = {}) {
  exactKeys(body, ['id', 'version']);
  const id = treeId(body);
  if (!Number.isSafeInteger(body.version) || body.version < 0) throw new Error('invalid-shared-tree');
  await db.runTransaction(async tx => {
    const data = await authorized(db, uid, id, tx);
    // Mark only what was actually displayed, never a newer concurrent arrival.
    const seen = Math.max(data.seenVersions?.[uid] ?? 0, Math.min(body.version, data.activityVersion ?? 0));
    tx.update(refFor(db, id), {seenVersions: {...data.seenVersions, [uid]: seen}});
  });
  return {seen: true};
}

export async function setSharedTreeStyle(db, uid, body, deps = {}) {
  exactKeys(body, ['id', 'style']);
  const id = treeId(body);
  if (!['sage', 'blossom', 'moonlight'].includes(body.style)) throw new Error('invalid-shared-tree');
  const current = await authorized(db, uid, id);
  if (current.hostUid !== uid) throw new Error('shared-tree-not-found');
  if (!deps.hasActiveSubscription || !await deps.hasActiveSubscription(uid)) throw new Error('subscription-required');
  await db.runTransaction(async tx => {
    const data = await authorized(db, uid, id, tx);
    if (data.hostUid !== uid) throw new Error('shared-tree-not-found');
    tx.update(refFor(db, id), {style: body.style, updatedAt: stamp(deps)});
  });
  return getSharedTree(db, uid, {id}, deps);
}

// An account-deletion tombstone blocks access before cleanup starts. Remove
// shared content and indexes, including declined/left invitations, on deletion.
export async function removeSharedTreeAccount(db, uid) {
  const queries = await Promise.all(['hostUid', 'guestUid'].map(field => db.collection('sharedTrees').where(field, '==', uid).get()));
  const found = new Map(queries.flatMap(q => q.docs.map(d => [d.id, d])));
  for (const [id, doc] of found) {
    const data = doc.data();
    await indexFor(db, data.hostUid, id).delete();
    await indexFor(db, data.guestUid, id).delete();
    await db.recursiveDelete(doc.ref);
  }
}
export async function reportSharedTreeNote(db, uid, body, deps = {}) {
  exactKeys(body, ['id', 'noteId']);
  const id = treeId(body);
  if (!safeId(body.noteId)) throw new Error('invalid-shared-tree-note');
  return db.runTransaction(async tx => {
    const data = await authorized(db, uid, id, tx);
    const note = (data.notes ?? []).find(n => n.id === body.noteId);
    if (!note || note.authorUid === uid) throw new Error('invalid-shared-tree-note');
    const ref = db.doc(`villageReports/${digest('shared-note', uid, id, body.noteId)}`);
    const existing = await tx.get(ref);
    if (!existing.exists) tx.set(ref, {reporterId:uid, targetId:note.authorUid,
      kind:'shared-note', treeId:id, noteId:body.noteId, reason:'shared_note',
      createdAt:stamp(deps), state:'pending'});
    return {reported:true};
  });
}

export const sharedTreeActions = {reportSharedTreeNote,createSharedTree, listSharedTrees, getSharedTree, respondSharedTree, waterSharedTree,
  addSharedTreeNote, deleteSharedTreeNote, listMySharedTreeNotes, leaveSharedTree, markSharedTreeSeen, setSharedTreeStyle};
