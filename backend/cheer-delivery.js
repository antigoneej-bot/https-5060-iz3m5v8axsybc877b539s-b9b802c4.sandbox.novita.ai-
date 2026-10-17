import {randomUUID} from 'node:crypto';
import {MAX_CHEER_GIFT_LIGHT_ESSENCE} from './policy.js';

export function validCheerId(id) {
  return typeof id === 'string' && /^[a-zA-Z0-9_-]{1,128}$/.test(id);
}

// Until currency is server-owned, clients may send flowers/reactions only.
export function acceptsGiftAmount(amount) {
  return amount === undefined || amount === 0;
}

// Persist a replayable receipt before returning. ACK only follows a durable
// client write of BOTH the receipt and currency in one garden snapshot.
export async function beginCheerDelivery(db, uid, id, {legacy = false, deviceId} = {}) {
  if (!validCheerId(id)) throw new Error('invalid-id');
  const ref = db.doc(`users/${uid}/receivedCheers/${id}`);
  const receipt = randomUUID();
  return db.runTransaction(async tx => {
    const doc = await tx.get(ref);
    if (!doc.exists) throw new Error('cheer-not-found');
    const data = doc.data();
    if (data.transferred) throw new Error('cheer-transferred');
    if (typeof data.senderId === 'string') {
      const [blocked, blockedBy] = await Promise.all([
        tx.get(db.doc(`users/${uid}/blockedNeighbors/${data.senderId}`)),
        tx.get(db.doc(`users/${data.senderId}/blockedNeighbors/${uid}`)),
      ]);
      if (blocked.exists || blockedBy.exists) throw new Error('cheer-not-found');
    }
    if (data.deliveryPending === true) {
      if (legacy) throw new Error('client-update-required');
      if (!deviceId || data.deliveryDeviceId !== deviceId) throw new Error('delivery-other-device');
      return {claimed: true, amount: data.deliveryAmount, receipt: data.deliveryReceipt};
    }
    // Legacy claims have no proof of delivery: never guess and double credit.
    if (data.claimed === true) return {claimed: true, amount: 0, receipt: null};
    const amount = data.giftLightEssence ?? 0;
    if (!Number.isInteger(amount) || amount < 0 || amount > MAX_CHEER_GIFT_LIGHT_ESSENCE) {
      throw new Error('invalid-garden-gift');
    }
    if (legacy && amount > 0) throw new Error('client-update-required');
    if (amount === 0) {
      tx.update(ref, {claimed: true});
      return {claimed: true, amount: 0, receipt: null};
    }
    if (typeof deviceId !== 'string' || !/^[a-zA-Z0-9_-]{32,128}$/.test(deviceId)) {
      throw new Error('invalid-delivery-device');
    }
    tx.update(ref, {claimed: true, deliveryPending: true,
      deliveryAmount: amount, deliveryReceipt: receipt, deliveryDeviceId: deviceId});
    return {claimed: true, amount, receipt};
  });
}

export async function acknowledgeCheerDelivery(db, uid, id, receipt, deviceId) {
  if (!validCheerId(id) || !validCheerId(receipt)) throw new Error('invalid-id');
  const ref = db.doc(`users/${uid}/receivedCheers/${id}`);
  return db.runTransaction(async tx => {
    const doc = await tx.get(ref);
    if (!doc.exists) throw new Error('cheer-not-found');
    if (doc.data().deliveryReceipt !== receipt) throw new Error('invalid-delivery-receipt');
    if (!deviceId || doc.data().deliveryDeviceId !== deviceId) throw new Error('delivery-other-device');
    tx.update(ref, {deliveryPending: false});
    return {acknowledged: true};
  });
}
