// Server-owned consent and moderation; private records are never altered.
export const COMMUNITY_VERSION = '2026-10-31';
// Account access and private backup recovery must not depend on opting into
// public/community participation, including for old clients and suspended users.
const privateAccountActions = new Set(['status', 'verify', 'backup',
  'listBackups', 'downloadBackup', 'deleteCloudAccount']);
const writes = new Set(['publishGarden', 'updateVillageProfile', 'createSharedTree',
  'addSharedTreeNote', 'inviteCatVisit', 'respondCatVisit', 'requestNeighbor',
  'sendPublicCheer', 'sendGardenGift', 'setCardDisplay', 'offerCardTrade']);
export async function enforceCommunityPolicy(db, uid, action) {
  if (privateAccountActions.has(action)) return;
  if (!writes.has(action)) return;
  const policy = (await db.doc(`users/${uid}/settings/community`).get()).data();
  if (policy?.suspended === true) throw new Error('community-suspended');
  if (policy?.version !== COMMUNITY_VERSION) throw new Error('community-consent-required');
}
export async function acceptCommunityPolicy(db, uid, version, stamp) {
  if (version !== COMMUNITY_VERSION) throw new Error('community-consent-required');
  await db.doc(`users/${uid}/settings/community`).set({version, acceptedAt: stamp()}, {merge: true});
  return {version};
}
// Called only by the trusted operator CLI using IAM credentials, never a client UID.
export async function resolveGardenReport(db, reportId, decision, operator, stamp) {
  if (!/^[a-f0-9]{64}$/.test(reportId) || !['dismiss', 'hide', 'suspend'].includes(decision) || !operator)
    throw new Error('invalid-moderation');
  return db.runTransaction(async tx => {
    const reportRef = db.doc(`villageReports/${reportId}`);
    const report = await tx.get(reportRef);
    if (!report.exists) throw new Error('report-not-found');
    if (report.data().state !== 'pending') return {alreadyResolved: true};
    const uid = report.data().targetId;
    if (typeof uid !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) throw new Error('invalid-moderation');
    let tree;
    if (report.data().kind === 'shared-note') {
      if (![report.data().treeId, report.data().noteId].every(v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(v))) throw new Error('invalid-moderation');
      tree = await tx.get(db.doc(`sharedTrees/${report.data().treeId}`));
    }
    if (decision !== 'dismiss' && tree?.exists) {
      const noteId = report.data().noteId;
      const note = (tree.data().notes ?? []).find(n => n.id === noteId);
      if (note && note.authorUid !== uid) throw new Error('invalid-moderation');
      tx.update(tree.ref, {notes:(tree.data().notes ?? []).filter(n => n.id !== noteId),
        activities:(tree.data().activities ?? []).filter(a => a.noteId !== noteId), updatedAt:stamp()});
    }
    if (decision === 'suspend' || (decision === 'hide' && !tree)) {
      tx.set(db.doc(`villageProfiles/${uid}`), {visibility: 'private', discoveryOptIn: false, randomVisitOptIn: false}, {merge:true});
      tx.delete(db.doc(`publicGardens/${uid}`));
      tx.delete(db.doc(`gardenDiscovery/${uid}`));
    }
    if (decision === 'suspend') tx.set(db.doc(`users/${uid}/settings/community`), {suspended: true}, {merge:true});
    tx.update(reportRef, {state: 'resolved', decision, reviewedBy: operator, reviewedAt: stamp()});
    return {resolved: true};
  });
}

export async function restoreCommunityAccess(db, uid, operator, stamp) {
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(uid) || !operator) throw new Error('invalid-moderation');
  // No automatic re-publication: owner chooses visibility again after restoration.
  await db.doc(`users/${uid}/settings/community`).set({suspended:false,
    restoredBy:operator, restoredAt:stamp()}, {merge:true});
  return {restored:true};
}
