import {createHash, randomBytes} from 'node:crypto';
import {accountHash, sanitizeNickname, validatePublicSnapshot, PUBLIC_CHEER_MESSAGE_COUNT} from './policy.js';
import {FLOWERS, liveReactions, newGardenReaction, validGardenGift} from './garden-gifts.js';
import {acceptsGiftAmount, validCheerId} from './cheer-delivery.js';

const VISIBILITIES = ['private', 'neighbors', 'public'];
const REPORT_REASONS = ['inappropriate_name', 'harassment', 'spam', 'other'];
const profileRef = (db, uid) => db.doc(`villageProfiles/${uid}`);
const linkRef = (db, uid, target) => db.doc(`users/${uid}/neighbors/${target}`);
const blockRef = (db, uid, target) => db.doc(`users/${uid}/blockedNeighbors/${target}`);
const hash = values => createHash('sha256').update(JSON.stringify(values)).digest('hex');
export const villageDate = value => value?.toDate?.().toISOString() ?? (typeof value === 'string' ? value : null);

// Versioned owner/action-scoped seek cursors. These are positions, not authority:
// every page repeats the current access checks. Never accept a document path.
function pageRequest(body, uid, kind, fallbackSize, maxSize) {
  const pageSize = body.pageSize === undefined ? fallbackSize : body.pageSize;
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > maxSize) throw new Error('invalid-page-size');
  if (body.cursor === undefined || body.cursor === null) return {pageSize, after: null};
  if (typeof body.cursor !== 'string' || body.cursor.length > 1024 || !/^[A-Za-z0-9_-]+$/.test(body.cursor)) throw new Error('invalid-cursor');
  let after;
  try { after = JSON.parse(Buffer.from(body.cursor, 'base64url').toString('utf8')); } catch { throw new Error('invalid-cursor'); }
  if (!after || after.v !== 1 || after.kind !== kind || after.owner !== accountHash(uid) ||
      !validCheerId(after.id) || Object.keys(after).some(key => !['v', 'kind', 'owner', 'id', 'at'].includes(key))) throw new Error('invalid-cursor');
  if (kind === 'cheers') validateCursorTime(after.at);
  else if (after.at !== undefined) throw new Error('invalid-cursor');
  return {pageSize, after};
}
function pageCursor(uid, kind, doc) {
  const value = {v: 1, kind, owner: accountHash(uid), id: doc.id};
  if (kind === 'cheers') value.at = cursorTime(doc.data().createdAt);
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}
function cursorTime(value) {
  if (value === null) return ['null'];
  if (typeof value === 'string') { const result = ['string', value]; validateCursorTime(result); return result; }
  if (Number.isInteger(value?.seconds) && Number.isInteger(value?.nanoseconds)) return ['timestamp', value.seconds, value.nanoseconds];
  // Legacy test doubles and Date-compatible stored timestamps retain millisecond precision.
  const millis = value?.toDate?.().getTime() ?? (value instanceof Date ? value.getTime() : NaN);
  if (!Number.isFinite(millis)) throw new Error('temporarily-unavailable');
  return ['timestamp', Math.floor(millis / 1000), (millis % 1000 + 1000) % 1000 * 1000000];
}
function validateCursorTime(value) {
  if (!Array.isArray(value)) throw new Error('invalid-cursor');
  if (value[0] === 'null' && value.length === 1) return;
  if (value[0] === 'string' && value.length === 2 && typeof value[1] === 'string' &&
      value[1].length <= 32 && Number.isFinite(Date.parse(value[1])) && new Date(value[1]).toISOString() === value[1]) return;
  if (value[0] === 'timestamp' && value.length === 3 && Number.isInteger(value[1]) &&
      value[1] >= -62135596800 && value[1] <= 253402300799 && Number.isInteger(value[2]) && value[2] >= 0 && value[2] < 1000000000) return;
  throw new Error('invalid-cursor');
}
function cursorTimeValue(value, timestampFromParts) {
  validateCursorTime(value);
  if (value[0] === 'null') return null;
  if (value[0] === 'string') return value[1];
  // Production injects Firestore Timestamp; precision must not round to milliseconds.
  if (!timestampFromParts) throw new Error('temporarily-unavailable');
  return timestampFromParts(value[1], value[2]);
}
function publicationSnapshot(data) {
  if (!data) return null;
  return {seedCounts: data.seedCounts ?? {}, equippedDecorationIds: data.equippedDecorationIds ?? [],
    treeStageIndex: data.treeStageIndex ?? 0, memoryTreeStage: data.memoryTreeStage ?? 0,
    hasCheerFlowers: data.hasCheerFlowers === true, flowerKinds: data.flowerKinds ?? [], layout: data.layout ?? null};
}

const normalizedCode = code => typeof code === 'string' ? code.toUpperCase().replace(/[ -]/g, '') : '';
const validTarget = target => typeof target === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(target);
function requireTarget(uid, target) {
  if (!validTarget(target) || target === uid) throw new Error('invalid-target');
}
export function villageSettings(profile, gardenExists = false) {
  return {
    visibility: VISIBILITIES.includes(profile?.visibility) ? profile.visibility : gardenExists ? 'public' : 'private',
    // A previous publication never silently consents to the new discovery list.
    discoveryOptIn: profile?.discoveryOptIn === true,
    receiveGifts: profile?.receiveGifts !== false,
  };
}
export async function readVillageAccess(db, viewer, target, tx) {
  const get = ref => tx ? tx.get(ref) : ref.get();
  const [garden, profile, relation, outgoingBlock, incomingBlock, lock] = await Promise.all([
    get(db.doc(`publicGardens/${target}`)), get(profileRef(db, target)),
    get(linkRef(db, viewer, target)), get(blockRef(db, viewer, target)),
    get(blockRef(db, target, viewer)), get(db.doc(`accountLocks/${accountHash(target)}`)),
  ]);
  const settings = villageSettings(profile.data(), garden.exists);
  const blocked = outgoingBlock.exists || incomingBlock.exists;
  const alive = !lock.data()?.deleting && !lock.data()?.deleted;
  const accepted = relation.data()?.status === 'accepted';
  return {garden, profile, relation, settings, blocked, alive, accepted,
    visible: alive && !blocked && garden.exists && (viewer === target || settings.visibility === 'public' || (settings.visibility === 'neighbors' && accepted)),
  };
}
export async function blockedBetween(db, left, right, tx) {
  const get = ref => tx ? tx.get(ref) : ref.get();
  const [a, b] = await Promise.all([get(blockRef(db, left, right)), get(blockRef(db, right, left))]);
  return a.exists || b.exists;
}
export function publicGardenDto(id, data) {
  return {gardenId: id, nickname: data.nickname ?? null,
    seedCounts: data.seedCounts ?? {}, equippedDecorationIds: data.equippedDecorationIds ?? [],
    treeStageIndex: data.treeStageIndex ?? 0, layout: data.layout ?? null,
    memoryTreeStage: data.memoryTreeStage ?? 0, hasCheerFlowers: data.hasCheerFlowers === true,
    flowerKinds: data.flowerKinds ?? [], reactions: liveReactions(data.reactions)};
}
export async function getVillageProfile(db, uid, {stamp = () => new Date().toISOString(), codeGenerator = () => randomBytes(6).toString('hex').toUpperCase()} = {}) {
  // Collision retry preserves a stable private invitation code for each account.
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = codeGenerator();
    const result = await db.runTransaction(async tx => {
      const own = await tx.get(profileRef(db, uid));
      const garden = await tx.get(db.doc(`publicGardens/${uid}`));
      if (own.data()?.inviteCode) return {inviteCode: own.data().inviteCode, ...villageSettings(own.data(), garden.exists), nickname: own.data().nickname ?? garden.data()?.nickname ?? null};
      const codeRef = db.doc(`villageInviteCodes/${code}`);
      const existing = await tx.get(codeRef);
      if (existing.exists && existing.data()?.uid !== uid) return null;
      const settings = villageSettings(own.data(), garden.exists);
      const nickname = own.data()?.nickname ?? garden.data()?.nickname ?? null;
      tx.set(profileRef(db, uid), {...settings, inviteCode: code, nickname, updatedAt: stamp()}, {merge: true});
      tx.set(codeRef, {uid});
      return {inviteCode: code, ...settings, nickname};
    });
    if (result) return result;
  }
  throw new Error('temporarily-unavailable');
}
function validatedSettings(body, previous) {
  if ((body.visibility !== undefined && !VISIBILITIES.includes(body.visibility)) ||
      ['discoveryOptIn', 'receiveGifts'].some(key => body[key] !== undefined && typeof body[key] !== 'boolean')) throw new Error('invalid-profile');
  const next = {...previous};
  for (const key of ['visibility', 'discoveryOptIn', 'receiveGifts']) if (body[key] !== undefined) next[key] = body[key];
  if (next.visibility !== 'public') next.discoveryOptIn = false;
  return next;
}
export async function updateVillageProfile(db, uid, body, {stamp}) {
  await getVillageProfile(db, uid, {stamp});
  return db.runTransaction(async tx => {
    const ref = profileRef(db, uid), gardenRef = db.doc(`publicGardens/${uid}`);
    const [own, garden] = await Promise.all([tx.get(ref), tx.get(gardenRef)]);
    const settings = validatedSettings(body, villageSettings(own.data(), garden.exists));
    const nickname = body.nickname === undefined ? own.data()?.nickname ?? garden.data()?.nickname ?? null : sanitizeNickname(body.nickname);
    tx.set(ref, {...settings, nickname, updatedAt: stamp()}, {merge: true});
    if (garden.exists && body.nickname !== undefined) tx.update(gardenRef, {nickname});
    return {inviteCode: own.data().inviteCode, ...settings, nickname};
  });
}
export async function publishVillageGarden(db, uid, body, {stamp}) {
  if ((body.appearanceOnly !== undefined && typeof body.appearanceOnly !== 'boolean') ||
      (body.appearanceOnly === true && ['nickname', 'visibility', 'discoveryOptIn', 'receiveGifts'].some(key => body[key] !== undefined))) throw new Error('invalid-profile');
  if (!validatePublicSnapshot(body.snapshot)) throw new Error('invalid-snapshot');
  const snapshot = body.snapshot;
  const hadProfile = (await profileRef(db, uid).get()).exists;
  await getVillageProfile(db, uid, {stamp});
  await db.runTransaction(async tx => {
    const ref = profileRef(db, uid), gardenRef = db.doc(`publicGardens/${uid}`);
    const [own, oldGarden] = await Promise.all([tx.get(ref), tx.get(gardenRef)]);
    // Legacy publish means public, but never discoverable; an established scope stays intact.
    const defaults = villageSettings(own.data(), oldGarden.exists);
    if (!hadProfile && body.visibility === undefined && body.appearanceOnly !== true) defaults.visibility = 'public';
    const settings = validatedSettings(body, defaults);
    const nickname = body.nickname === undefined ? own.data()?.nickname ?? oldGarden.data()?.nickname ?? null : sanitizeNickname(body.nickname);
    tx.set(ref, {...settings, nickname, updatedAt: stamp()}, {merge: true});
    tx.set(gardenRef, {nickname, seedCounts: snapshot.seedCounts,
      equippedDecorationIds: snapshot.equippedDecorationIds, treeStageIndex: snapshot.treeStageIndex,
      memoryTreeStage: snapshot.memoryTreeStage ?? 0, hasCheerFlowers: snapshot.hasCheerFlowers ?? false,
      flowerKinds: snapshot.flowerKinds ?? [], layout: snapshot.layout ?? null,
      updatedAt: stamp(), rand: Math.random()}, {merge: true});
  });
  // Resolve the server timestamp after commit; only the authenticated owner gets this snapshot.
  return villagePublicationStatus(db, uid);
}
export async function unpublishVillageGarden(db, uid, {stamp}) {
  await db.runTransaction(async tx => {
    tx.set(profileRef(db, uid), {visibility: 'private', discoveryOptIn: false, updatedAt: stamp()}, {merge: true});
    tx.delete(db.doc(`publicGardens/${uid}`));
  });
  return {published: false, nickname: null};
}
export async function villagePublicationStatus(db, uid) {
  const [garden, profile] = await Promise.all([db.doc(`publicGardens/${uid}`).get(), profileRef(db, uid).get()]);
  const settings = villageSettings(profile.data(), garden.exists);
  return {published: garden.exists && settings.visibility !== 'private', nickname: garden.data()?.nickname ?? null, ...settings,
    snapshot: publicationSnapshot(garden.data()), updatedAt: villageDate(garden.data()?.updatedAt)};
}
export async function listDiscoverableGardens(db, uid, body = {}) {
  const {pageSize, after} = pageRequest(body, uid, 'gardens', 12, 24);
  // Stable seek order reaches accounts beyond the original first 80. The scan
  // budget bounds read cost even if most candidates are blocked or unpublished.
  let query = db.collection('villageProfiles').where('discoveryOptIn', '==', true).orderBy('__name__');
  if (after) query = query.startAfter(after.id);
  const candidates = await query.limit(81).get();
  const gardens = [];
  let lastScanned = null, scanned = 0;
  for (const doc of candidates.docs.slice(0, 80)) {
    lastScanned = doc;
    scanned++;
    if (doc.id === uid) continue;
    const access = await readVillageAccess(db, uid, doc.id);
    if (access.visible && access.settings.visibility === 'public' && access.settings.discoveryOptIn) gardens.push({...publicGardenDto(doc.id, access.garden.data()), receiveGifts: access.settings.receiveGifts});
    if (gardens.length === pageSize) break;
  }
  // The extra candidate distinguishes exhaustion from a full scan. Empty pages
  // can still advance past hidden candidates; clients must honor nextCursor.
  return {gardens, nextCursor: lastScanned && scanned < candidates.docs.length ? pageCursor(uid, 'gardens', lastScanned) : null};
}
async function resolveInvite(db, uid, inviteCode) {
  const code = normalizedCode(inviteCode);
  if (!/^[A-F0-9]{12}$/.test(code)) throw new Error('invalid-invite-code');
  const record = await db.doc(`villageInviteCodes/${code}`).get();
  const target = record.data()?.uid;
  if (!validTarget(target) || target === uid) throw new Error('garden-not-found');
  return target;
}
async function neighborCard(db, uid, target) {
  const access = await readVillageAccess(db, uid, target);
  if (access.blocked || !access.alive) return null;
  return {gardenId: target, nickname: access.profile.data()?.nickname ?? access.garden.data()?.nickname ?? null,
    status: access.relation.data()?.status ?? 'none', requestedAt: villageDate(access.relation.data()?.requestedAt),
    canVisit: access.visible};
}
export async function lookupNeighbor(db, uid, body) {
  const target = await resolveInvite(db, uid, body.inviteCode);
  const card = await neighborCard(db, uid, target);
  if (!card) throw new Error('garden-not-found');
  return card;
}
export async function requestNeighbor(db, uid, body, {stamp}) {
  const viaCode = body.inviteCode !== undefined;
  const target = viaCode ? await resolveInvite(db, uid, body.inviteCode) : body.gardenId;
  requireTarget(uid, target);
  await getVillageProfile(db, uid, {stamp});
  return db.runTransaction(async tx => {
    const access = await readVillageAccess(db, uid, target, tx);
    if (!access.alive || access.blocked || (!viaCode && !access.visible)) throw new Error('garden-not-found');
    const existing = access.relation.data();
    if (existing?.status === 'accepted') return {requested: false, status: 'accepted'};
    if (existing?.status === 'outgoing') return {requested: true, status: 'outgoing'};
    if (existing?.status === 'incoming') return {requested: false, status: 'incoming'};
    const requestedAt = stamp();
    tx.set(linkRef(db, uid, target), {status: 'outgoing', requestedAt});
    tx.set(linkRef(db, target, uid), {status: 'incoming', requestedAt});
    return {requested: true, status: 'outgoing'};
  });
}
export async function respondNeighbor(db, uid, body, {stamp}) {
  requireTarget(uid, body.gardenId);
  if (typeof body.accept !== 'boolean') throw new Error('invalid-profile');
  return db.runTransaction(async tx => {
    const access = await readVillageAccess(db, uid, body.gardenId, tx);
    if (!access.alive || access.blocked) throw new Error('garden-not-found');
    const status = access.relation.data()?.status;
    if (status === 'accepted' && body.accept) return {accepted: true};
    if (!status && !body.accept) return {accepted: false};
    if (status !== 'incoming') throw new Error('neighbor-request-not-found');
    if (body.accept) {
      const value = {status: 'accepted', requestedAt: access.relation.data().requestedAt, acceptedAt: stamp()};
      tx.set(linkRef(db, uid, body.gardenId), value);
      tx.set(linkRef(db, body.gardenId, uid), value);
    } else {
      tx.delete(linkRef(db, uid, body.gardenId)); tx.delete(linkRef(db, body.gardenId, uid));
    }
    return {accepted: body.accept};
  });
}
export async function removeNeighbor(db, uid, body) {
  requireTarget(uid, body.gardenId);
  await db.runTransaction(async tx => {
    tx.delete(linkRef(db, uid, body.gardenId)); tx.delete(linkRef(db, body.gardenId, uid));
  });
  return {removed: true};
}
export async function listNeighbors(db, uid) {
  const [links, blocks] = await Promise.all([db.collection(`users/${uid}/neighbors`).limit(200).get(), db.collection(`users/${uid}/blockedNeighbors`).limit(200).get()]);
  const result = {neighbors: [], incoming: [], outgoing: [], blocked: []};
  for (const doc of links.docs) {
    const card = await neighborCard(db, uid, doc.id);
    if (!card) continue;
    const key = {accepted: 'neighbors', incoming: 'incoming', outgoing: 'outgoing'}[card.status];
    if (key) result[key].push(card);
  }
  for (const doc of blocks.docs) result.blocked.push({gardenId: doc.id, nickname: doc.data().nickname ?? null, status: 'blocked', requestedAt: villageDate(doc.data().createdAt)});
  return result;
}
export async function getNeighborGarden(db, uid, body) {
  requireTarget(uid, body.gardenId);
  const access = await readVillageAccess(db, uid, body.gardenId);
  if (!access.visible) throw new Error('garden-not-found');
  return {garden: {...publicGardenDto(body.gardenId, access.garden.data()), receiveGifts: access.settings.receiveGifts}};
}
export async function blockNeighbor(db, uid, body, {stamp}) {
  requireTarget(uid, body.gardenId);
  if (typeof body.blocked !== 'boolean') throw new Error('invalid-profile');
  await db.runTransaction(async tx => {
    const access = await readVillageAccess(db, uid, body.gardenId, tx);
    if (body.blocked) {
      tx.set(blockRef(db, uid, body.gardenId), {targetId: body.gardenId, nickname: access.visible || access.relation.exists ? access.profile.data()?.nickname ?? access.garden.data()?.nickname ?? null : null, createdAt: stamp()});
      tx.delete(linkRef(db, uid, body.gardenId)); tx.delete(linkRef(db, body.gardenId, uid));
    } else tx.delete(blockRef(db, uid, body.gardenId));
  });
  return {blocked: body.blocked};
}
export async function reportGarden(db, uid, body, {stamp}) {
  requireTarget(uid, body.gardenId);
  if (!REPORT_REASONS.includes(body.reason)) throw new Error('invalid-report');
  return db.runTransaction(async tx => {
    const access = await readVillageAccess(db, uid, body.gardenId, tx);
    if (!access.alive || (!access.garden.exists && !access.profile.exists)) throw new Error('garden-not-found');
    // Curated categories only: never copy private diaries or free text to moderation.
    const day = new Date().toISOString().slice(0, 10);
    tx.set(db.doc(`villageReports/${hash([uid, body.gardenId, day, body.reason])}`), {reporterId: uid, targetId: body.gardenId, reason: body.reason, createdAt: stamp(), state: 'pending'});
    return {reported: true};
  });
}
export async function sendVillageCheer(db, uid, body, {stamp, now = Date.now()}) {
  const target = body.gardenId;
  requireTarget(uid, target);
  if (!validGardenGift(body) || !['cheer', 'gift'].includes(body.deliveryKind ?? 'gift')) throw new Error('invalid-garden-gift');
  if (!Number.isInteger(body.messageIndex) || body.messageIndex < 0 || body.messageIndex >= PUBLIC_CHEER_MESSAGE_COUNT) throw new Error('invalid-message');
  if (!acceptsGiftAmount(body.giftLightEssence)) throw new Error('currency-gifts-unavailable');
  const deliveryKind = body.deliveryKind ?? 'gift';
  const flowerKind = deliveryKind === 'gift' ? body.flowerKind ?? 'daisy' : null;
  const reaction = newGardenReaction(body.reaction, now);
  const today = new Date(now + 9 * 60 * 60 * 1000).toISOString().slice(0, 10);
  const fingerprint = JSON.stringify([body.messageIndex, flowerKind, body.reaction ?? null, deliveryKind]);
  const logRef = db.doc(`cheerSentLog/${hash([uid, target, deliveryKind])}`);
  return db.runTransaction(async tx => {
    const access = await readVillageAccess(db, uid, target, tx);
    const [log, legacyLog, sender, senderGarden] = await Promise.all([tx.get(logRef), tx.get(db.doc(`cheerSentLog/${uid}_${target}`)), tx.get(profileRef(db, uid)), tx.get(db.doc(`publicGardens/${uid}`))]);
    if (!access.visible) throw new Error('garden-not-found');
    if (deliveryKind === 'gift' && !access.accepted) throw new Error('neighbor-required');
    if (deliveryKind === 'gift' && !access.settings.receiveGifts) throw new Error('gifts-disabled');
    // A lost response from the pre-village release must not mint another flower after upgrade.
    if (deliveryKind === 'gift' && legacyLog.data()?.date === today) {
      if (legacyLog.data()?.fingerprint === JSON.stringify([body.messageIndex, flowerKind, body.reaction ?? null])) return {sent: true};
      throw new Error('cheer-already-sent-today');
    }
    if (log.data()?.date === today) {
      if (log.data()?.fingerprint === fingerprint) return {sent: true};
      throw new Error('cheer-already-sent-today');
    }
    tx.set(logRef, {date: today, fingerprint, senderId: uid, recipientId: target});
    if (reaction) tx.update(access.garden.ref, {reactions: [...liveReactions(access.garden.data()?.reactions, now), reaction].slice(-12)});
    tx.set(db.collection(`users/${target}/receivedCheers`).doc(), {
      messageIndex: body.messageIndex, giftLightEssence: 0, flowerKind, reaction, deliveryKind,
      senderId: uid, senderNickname: sender.data()?.nickname ?? senderGarden.data()?.nickname ?? null,
      claimed: false, createdAt: stamp(),
    });
    return {sent: true};
  });
}
export async function sendGardenGift(db, uid, body, {stamp}) {
  requireTarget(uid, body.gardenId);
  if (!validCheerId(body.sourceCheerId) || typeof body.requestId !== 'string' || !/^[A-Za-z0-9_-]{16,128}$/.test(body.requestId)) throw new Error('invalid-garden-gift');
  const requestRef = db.doc(`users/${uid}/giftTransfers/${body.requestId}`);
  const sourceRef = db.doc(`users/${uid}/receivedCheers/${body.sourceCheerId}`);
  const fingerprint = hash([body.gardenId, body.sourceCheerId]);
  const destinationId = hash([uid, body.requestId]);
  return db.runTransaction(async tx => {
    const access = await readVillageAccess(db, uid, body.gardenId, tx);
    const [request, source, sender, senderGarden] = await Promise.all([tx.get(requestRef), tx.get(sourceRef), tx.get(profileRef(db, uid)), tx.get(db.doc(`publicGardens/${uid}`))]);
    if (request.exists) {
      if (request.data().fingerprint !== fingerprint) throw new Error('request-conflict');
      return {sent: true, id: request.data().id, sourceCheerId: body.sourceCheerId};
    }
    if (!access.alive || access.blocked || !access.accepted) throw new Error('neighbor-required');
    if (!access.settings.receiveGifts) throw new Error('gifts-disabled');
    if (!source.exists) throw new Error('cheer-not-found');
    const data = source.data();
    if (data.transferred) throw new Error('cheer-transferred');
    if (data.bloomConfirmed) throw new Error('flower-already-planted');
    if (data.deliveryKind === 'cheer' || !FLOWERS.includes(data.flowerKind ?? 'daisy') || (data.giftLightEssence ?? 0) !== 0) throw new Error('invalid-garden-gift');
    const time = stamp();
    tx.update(sourceRef, {transferred: true, transferredAt: time, claimed: true});
    tx.set(db.doc(`users/${body.gardenId}/receivedCheers/${destinationId}`), {
      deliveryKind: 'gift', flowerKind: data.flowerKind ?? 'daisy', giftLightEssence: 0,
      messageIndex: data.messageIndex ?? 0, reaction: null, senderId: uid,
      senderNickname: sender.data()?.nickname ?? senderGarden.data()?.nickname ?? null,
      claimed: false, createdAt: time,
    });
    tx.set(requestRef, {fingerprint, id: destinationId, createdAt: time});
    return {sent: true, id: destinationId, sourceCheerId: body.sourceCheerId};
  });
}
export async function listVillageCheers(db, uid, body = {}, {timestampFromParts} = {}) {
  const {pageSize, after} = pageRequest(body, uid, 'cheers', 80, 80);
  const collection = db.collection(`users/${uid}/receivedCheers`);
  let query = collection.orderBy('createdAt', 'desc').orderBy('__name__', 'desc');
  if (after) query = query.startAfter(cursorTimeValue(after.at, timestampFromParts), after.id);
  const empty = {docs: []};
  const [recent, unclaimed, pending, transferred] = await Promise.all([
    query.limit(pageSize + 1).get(),
    after ? empty : collection.where('claimed', '==', false).limit(80).get(),
    after ? empty : collection.where('deliveryPending', '==', true).limit(30).get(),
    // Keep global transfer tombstones for existing clients and stale devices.
    // These are not visible gifts and never consume the history page budget.
    collection.where('transferred', '==', true).get(),
  ]);
  const ordered = recent.docs.slice(0, pageSize);
  const docs = new Map([...ordered, ...unclaimed.docs, ...pending.docs].map(doc => [doc.id, doc]));
  const retiredIds = transferred.docs.map(doc => doc.id);
  const cheers = [];
  for (const doc of docs.values()) {
    const data = doc.data();
    if (data.transferred) continue;
    let senderGardenId = validTarget(data.senderId) ? data.senderId : null;
    if (senderGardenId && await blockedBetween(db, uid, senderGardenId)) continue;
    if (senderGardenId) {
      const lock = await db.doc(`accountLocks/${accountHash(senderGardenId)}`).get();
      if (lock.data()?.deleting || lock.data()?.deleted) senderGardenId = null;
    }
    cheers.push({id: doc.id, messageIndex: data.messageIndex ?? 0, giftLightEssence: data.giftLightEssence ?? 0,
      flowerKind: data.deliveryKind === 'cheer' ? null : data.flowerKind ?? 'daisy', reaction: liveReactions([data.reaction])[0] ?? null,
      deliveryKind: data.deliveryKind ?? 'gift', senderGardenId,
      senderNickname: senderGardenId ? data.senderNickname ?? null : null,
      claimed: data.claimed === true, bloomConfirmed: data.bloomConfirmed === true,
      plantedFlowerKind: data.bloomConfirmed ? data.plantedFlowerKind ?? data.flowerKind ?? 'daisy' : null,
      createdAt: villageDate(data.createdAt)});
  }
  cheers.sort((a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? '') || b.id.localeCompare(a.id));
  return {cheers, retiredIds, nextCursor: recent.docs.length > pageSize ? pageCursor(uid, 'cheers', ordered.at(-1)) : null};
}
export async function listVillageBlooms(db, uid) {
  const snap = await db.collection(`users/${uid}/flowerBlooms`).orderBy('createdAt', 'desc').limit(30).get();
  const blooms = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.recipientId && await blockedBetween(db, uid, data.recipientId)) continue;
    blooms.push({id: doc.id, flowerKind: data.flowerKind, createdAt: villageDate(data.createdAt)});
  }
  return {blooms};
}
export async function removeVillageAccount(db, uid) {
  const profile = await profileRef(db, uid).get();
  const code = profile.data()?.inviteCode;
  if (typeof code === 'string' && /^[A-F0-9]{12}$/.test(code)) await db.doc(`villageInviteCodes/${code}`).delete();
  const links = await db.collection(`users/${uid}/neighbors`).get();
  for (const doc of links.docs) await linkRef(db, doc.id, uid).delete();
  for (const field of ['senderId', 'recipientId']) {
    const logs = await db.collection('cheerSentLog').where(field, '==', uid).get();
    for (const doc of logs.docs) await doc.ref.delete();
  }
  for (const field of ['reporterId', 'targetId']) {
    const reports = await db.collection('villageReports').where(field, '==', uid).get();
    for (const doc of reports.docs) await doc.ref.delete();
  }
  const received = await db.collectionGroup('receivedCheers').where('senderId', '==', uid).get();
  for (const doc of received.docs) await doc.ref.update({senderId: null, senderNickname: null});
  const blocked = await db.collectionGroup('blockedNeighbors').where('targetId', '==', uid).get();
  for (const doc of blocked.docs) await doc.ref.delete();
  const blooms = await db.collectionGroup('flowerBlooms').where('recipientId', '==', uid).get();
  for (const doc of blooms.docs) await doc.ref.delete();
  await profileRef(db, uid).delete();
}
