// Only the authenticated caller's publication status is returned. This is
// deliberately separate from the random neighbour list, which excludes self.
export async function readOwnPublicGardenStatus(db, uid) {
  const snapshot = await db.doc(`publicGardens/${uid}`).get();
  if (!snapshot.exists) return {published: false, nickname: null};
  const nickname = snapshot.data()?.nickname;
  return {
    published: true,
    nickname: typeof nickname === 'string' ? nickname : null,
  };
}
