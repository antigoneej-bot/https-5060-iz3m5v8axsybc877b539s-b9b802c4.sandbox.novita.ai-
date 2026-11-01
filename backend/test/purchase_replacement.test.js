import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {storeVerifiedPurchase} from '../purchase-replacement.js';
import {accountHash,tokenHash} from '../policy.js';
const purchase = (productId, linkedPurchaseToken) => ({subscriptionState:'SUBSCRIPTION_STATE_ACTIVE', linkedPurchaseToken,
  externalAccountIdentifiers:{obfuscatedExternalAccountId:accountHash('a')},
  lineItems:[{productId, expiryTime:new Date(Date.now()+86400000).toISOString()}]});
const stamp=()=>new Date().toISOString();
test('annual replacement invalidates old monthly token and delayed RTDN cannot revive it', async()=>{
  const db=memoryDb();
  await storeVerifiedPurchase(db,'a','old',purchase('garden_plus_monthly'),stamp);
  const result=await storeVerifiedPurchase(db,'a','new',purchase('garden_plus_yearly','old'),stamp);
  assert.equal(result.active,true); assert.equal(result.productId,'garden_plus_yearly');
  const delayed=await storeVerifiedPurchase(db,'a','old',purchase('garden_plus_monthly'),stamp);
  assert.equal(delayed.active,false);
  assert.equal(db.rows.get(`users/a/entitlements/${tokenHash('new')}`).active,true);
});
test('linked token belonging to a different account cannot be taken over',async()=>{
  const db=memoryDb({[`purchaseTokens/${tokenHash('old')}`]:{uid:'b'}});
  await assert.rejects(storeVerifiedPurchase(db,'a','new',purchase('garden_plus_yearly','old'),stamp),/purchase-owner-mismatch/);
  assert.equal(db.rows.has(`purchaseTokens/${tokenHash('new')}`),false);
});
test('new receipts without an account binding remain rejected',async()=>{
  const p=purchase('garden_plus_yearly');delete p.externalAccountIdentifiers;
  await assert.rejects(storeVerifiedPurchase(memoryDb(),'a','new',p,stamp),/purchase-migration-required/);
});
