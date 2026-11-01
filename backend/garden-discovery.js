import {randomBytes} from 'node:crypto';
import {readVillageAccess, publicGardenDto, pageRequest, pageCursor} from './garden-village.js';

const validId = id => typeof id === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(id);
const missingAccountLookup = async () => {throw new Error('temporarily-unavailable');};
const favoriteRef = (db, uid, target) => db.doc(`users/${uid}/favoriteGardens/${target}`);
const permitted = access => access.visible && access.settings.visibility === 'public' && access.settings.discoveryOptIn && access.settings.randomVisitOptIn;
function targetId(uid, body) {
  if (!validId(body.gardenId) || body.gardenId === uid) throw new Error('invalid-target');
  return body.gardenId;
}
const historyIds = data => (Array.isArray(data?.recent) ? data.recent : []).filter(validId).slice(-8);

export async function getPublicVisitGarden(db, uid, body, {accountExists = missingAccountLookup} = {}) {
  const target = targetId(uid, body);
  const access = await readVillageAccess(db, uid, target);
  if (!permitted(access) || !await accountExists(target)) throw new Error('garden-not-found');
  const favorite = await favoriteRef(db, uid, target).get();
  return {garden: {...publicGardenDto(target, access.garden.data()), receiveGifts: access.settings.receiveGifts, neighborStatus: access.relation.data()?.status ?? 'none', isFavorite: favorite.exists}};
}

export async function randomPublicGarden(db, uid, _body = {}, {
  stamp = () => new Date().toISOString(), random = () => randomBytes(6).readUIntBE(0, 6) / 2 ** 48,
  accountExists = missingAccountLookup,
} = {}) {
  const historyRef = db.doc(`users/${uid}/settings/discoveryHistory`);
  for (let attempt = 0; attempt < 3; attempt++) {
    const recent = historyIds((await historyRef.get()).data());
    const pivot = random();
    if (!Number.isFinite(pivot) || pivot < 0 || pivot >= 1) throw new Error('temporarily-unavailable');
    const index = db.collection('gardenDiscovery');
    const fallback = [];
    let chosen;
    // Scan consecutive windows around one random pivot. A rejected window is
    // not an empty pool. Bound work to 96 index entries per transaction attempt.
    let remaining = 96;
    for (const [operator, bound] of [['>=', pivot], ['<', pivot]]) {
      let after;
      while (remaining > 0 && !chosen) {
        let query = index.where('rank', operator, bound)
          .orderBy('rank').orderBy('__name__');
        if (after) query = query.startAfter(after.rank, after.id);
        const size = Math.min(24, remaining);
        const page = await query.limit(size).get();
        if (!page.docs.length) break;
        remaining -= page.docs.length;
        const last = page.docs.at(-1);
        after = {rank: last.data().rank, id: last.id};
        const candidates = [...page.docs];
        for (let i = candidates.length - 1; i > 0; i--) {
          const j = Math.floor(random() * (i + 1));
          [candidates[i], candidates[j]] = [candidates[j], candidates[i]];
        }
        for (const candidate of candidates) {
          if (!validId(candidate.id) || candidate.id === uid || candidate.id === recent.at(-1)) continue;
          const access = await readVillageAccess(db, uid, candidate.id);
          if (!permitted(access) || !await accountExists(candidate.id)) continue;
          if (!recent.includes(candidate.id)) {chosen = candidate.id; break;}
          fallback.push(candidate.id);
        }
        // Reuse a permitted older visit when available instead of scanning the
        // entire pool just to avoid the last eight visits.
        if (chosen || fallback.length || page.docs.length < size) break;
      }
      if (chosen || fallback.length || remaining === 0) break;
    }
    chosen ??= fallback.sort((a, b) => recent.indexOf(a) - recent.indexOf(b))[0];
    if (!chosen) return {garden: null, exhausted: recent.length > 0};
    try {
      // Recheck permissions inside the commit, so a concurrent withdrawal or
      // block cannot authorize a new history entry using a stale candidate.
      return await db.runTransaction(async tx => {
        const [history, access, favorite] = await Promise.all([
          tx.get(historyRef), readVillageAccess(db, uid, chosen, tx), tx.get(favoriteRef(db, uid, chosen)),
        ]);
        const current = historyIds(history.data());
        if (!permitted(access) || current.at(-1) === chosen) throw new Error('discovery-retry');
        tx.set(historyRef, {recent: [...current.filter(id => id !== chosen), chosen].slice(-8), updatedAt: stamp()});
        return {garden: {...publicGardenDto(chosen, access.garden.data()), receiveGifts: access.settings.receiveGifts, neighborStatus: access.relation.data()?.status ?? 'none', isFavorite: favorite.exists}, exhausted: false};
      });
    } catch (error) {if (error.message !== 'discovery-retry') throw error;}
  }
  return {garden: null, exhausted: true};
}

export async function setFavoriteGarden(db, uid, body, {stamp = () => new Date().toISOString(), accountExists = missingAccountLookup} = {}) {
  const target = targetId(uid, body);
  if (typeof body.favorite !== 'boolean') throw new Error('invalid-profile');
  if (body.favorite && !await accountExists(target)) throw new Error('garden-not-found');
  return db.runTransaction(async tx => {
    const ref = favoriteRef(db, uid, target);
    if (!body.favorite) {tx.delete(ref); return {favorite: false};}
    const [access, existing, favorites] = await Promise.all([
      readVillageAccess(db, uid, target, tx), tx.get(ref), tx.get(db.collection(`users/${uid}/favoriteGardens`).limit(201)),
    ]);
    if (!permitted(access)) throw new Error('garden-not-found');
    if (!existing.exists && favorites.docs.length >= 200) throw new Error('favorites-limit');
    if (!existing.exists) tx.set(ref, {createdAt: stamp()});
    return {favorite: true};
  });
}

export async function listFavoriteGardens(db, uid, body = {}, {accountExists = missingAccountLookup} = {}) {
  const {pageSize, after} = pageRequest(body, uid, 'favorites', 12, 24);
  let query = db.collection(`users/${uid}/favoriteGardens`).orderBy('__name__');
  if (after) query = query.startAfter(after.id);
  const page = await query.limit(pageSize + 1).get();
  const gardens = [];
  const unavailableIds = [];
  for (const doc of page.docs.slice(0, pageSize)) {
    if (doc.id === uid) continue;
    const access = await readVillageAccess(db, uid, doc.id);
    if (permitted(access) && await accountExists(doc.id)) gardens.push({...publicGardenDto(doc.id, access.garden.data()), receiveGifts: access.settings.receiveGifts, neighborStatus: access.relation.data()?.status ?? 'none', isFavorite: true});
    else unavailableIds.push(doc.id);
  }
  return {gardens, unavailableIds, nextCursor: page.docs.length > pageSize ? pageCursor(uid, 'favorites', page.docs[pageSize - 1]) : null};
}

export const discoveryActions = {randomPublicGarden, getPublicVisitGarden, setFavoriteGarden, listFavoriteGardens};
