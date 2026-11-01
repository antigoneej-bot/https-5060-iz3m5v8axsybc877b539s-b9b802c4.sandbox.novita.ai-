import {assertOwner, entitlement, tokenHash} from './policy.js';

// RTDN and the foreground verifier share this transaction. A delayed event for
// the replaced token must never revive the old monthly entitlement.
export async function storeVerifiedPurchase(db, uid, token, purchase, stamp) {
  const id = tokenHash(token), ref = db.doc(`purchaseTokens/${id}`);
  const linked = purchase.linkedPurchaseToken;
  if (linked === token) throw new Error('invalid-linked-purchase');
  const oldId = linked ? tokenHash(linked) : null;
  return db.runTransaction(async tx => {
    const current = await tx.get(ref);
    const old = oldId ? await tx.get(db.doc(`purchaseTokens/${oldId}`)) : null;
    if (current.data()?.deleted || old?.data()?.deleted) throw new Error('purchase-owner-mismatch');
    assertOwner(purchase, uid, current.data()?.uid);
    if (old?.exists && old.data().uid !== uid) throw new Error('purchase-owner-mismatch');
    if (old?.data()?.replacedBy && old.data().replacedBy !== id) throw new Error('purchase-owner-mismatch');
    const result = current.data()?.replacedBy
      ? {active: false, state: 'expired', expiresAt: null, productId: null, checkedAt: new Date().toISOString()}
      : entitlement(purchase);
    tx.set(ref, {uid, token, updatedAt: stamp()}, {merge: true});
    tx.set(db.doc(`users/${uid}/entitlements/${id}`), result);
    if (oldId && !current.data()?.replacedBy) {
      tx.set(db.doc(`purchaseTokens/${oldId}`), {uid, token: linked, replacedBy: id, updatedAt: stamp()}, {merge: true});
      tx.set(db.doc(`users/${uid}/entitlements/${oldId}`), {active: false, state: 'expired', productId: null, expiresAt: null, checkedAt: result.checkedAt});
    }
    return result;
  });
}
