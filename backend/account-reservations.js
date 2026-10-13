// Deletion can be retried after any partial batch. Each seat decrement and
// reservation deletion commit together; other participants retain their seats.
export async function removeAccountReservations(db, uid) {
  let removed = 0;
  while (true) {
    const page = await db.collection('gardenNewsReservations')
      .where('uid', '==', uid).limit(50).get();
    if (page.empty) return removed;
    for (const doc of page.docs) {
      await db.runTransaction(async tx => {
        const reservation = await tx.get(doc.ref);
        if (!reservation.exists || reservation.data().uid !== uid) return;
        const newsId = reservation.data().newsId;
        const newsRef = typeof newsId === 'string' && newsId && !newsId.includes('/')
          ? db.doc(`gardenNews/${newsId}`) : null;
        const news = newsRef ? await tx.get(newsRef) : null;
        tx.delete(doc.ref);
        if (news?.exists) {
          tx.update(newsRef, {reservedCount: Math.max(0, (news.data().reservedCount ?? 0) - 1)});
        }
      });
      removed++;
    }
  }
}
