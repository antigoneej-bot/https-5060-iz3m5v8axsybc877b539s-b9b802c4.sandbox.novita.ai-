import { createHash } from 'node:crypto';
import { FLOWERS } from './garden-gifts.js';
export const bloomReceiptId = (recipient, cheerId) => createHash('sha256').update(JSON.stringify([recipient, cheerId])).digest('hex');
export async function confirmGardenBloom(db, recipient, cheerId, flowerKind, {stamp, accountHash}) {
  if (typeof cheerId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(cheerId) || !FLOWERS.includes(flowerKind)) throw new Error('invalid-bloom');
  return db.runTransaction(async tx => {
    // Caller can confirm only their own received cheer. Sender never comes from a request.
    const ref = db.doc(`users/${recipient}/receivedCheers/${cheerId}`);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new Error('cheer-not-found');
    const cheer = snap.data();
    if (cheer.bloomConfirmed) return {confirmed: true, notified: false};
    const sender = cheer.senderId;
    let canNotify = typeof sender === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(sender) && sender !== recipient;
    if (canNotify) {
      const lock = await tx.get(db.doc(`accountLocks/${accountHash(sender)}`));
      canNotify = !lock.data()?.deleted && !lock.data()?.deleting;
    }
    // Old cheers have no sender, but can still be planted and acknowledged safely.
    tx.update(ref, {bloomConfirmed: true, plantedFlowerKind: flowerKind, plantedAt: stamp()});
    if (canNotify) {
      tx.set(db.doc(`users/${sender}/flowerBlooms/${bloomReceiptId(recipient, cheerId)}`), {
        flowerKind, createdAt: stamp(),
      });
    }
    return {confirmed: true, notified: canNotify};
  });
}
