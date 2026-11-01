import {createHash} from 'node:crypto';

// Server-only, minimal sampling index. Existing publications are never migrated
// into random visits: the new versioned choice must be explicitly saved.
export function syncDiscoveryIndex(tx, db, uid, settings, gardenExists) {
  const ref = db.doc(`gardenDiscovery/${uid}`);
  if (gardenExists && settings.visibility === 'public' && settings.discoveryOptIn && settings.randomVisitOptIn) {
    const rank = Number.parseInt(createHash('sha256').update(uid).digest('hex').slice(0, 12), 16) / 2 ** 48;
    tx.set(ref, {rank, version: 1});
  } else tx.delete(ref);
}
