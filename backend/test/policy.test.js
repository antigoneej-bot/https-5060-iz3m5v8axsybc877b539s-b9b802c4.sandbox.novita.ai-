import test from 'node:test';
import assert from 'node:assert/strict';
import { accountHash, assertOwner, entitlement, validEnvelope } from '../policy.js';
const now=Date.parse('2026-09-13T00:00:00Z');
const active=(state='SUBSCRIPTION_STATE_ACTIVE',expiry='2026-10-13T00:00:00Z',productId='garden_plus_monthly')=>({subscriptionState:state,lineItems:[{productId,expiryTime:expiry}]});
test('active known product with future expiry is granted',()=>assert.equal(entitlement(active(),now).active,true));
test('cancelled renewal retains paid access until expiry',()=>assert.equal(entitlement(active('SUBSCRIPTION_STATE_CANCELED'),now).active,true));
test('expired cancellation is denied',()=>assert.equal(entitlement(active('SUBSCRIPTION_STATE_CANCELED','2026-09-12T00:00:00Z'),now).active,false));
test('pending hold pause and expired states are denied',()=>{
 for(const state of ['SUBSCRIPTION_STATE_PENDING','SUBSCRIPTION_STATE_ON_HOLD','SUBSCRIPTION_STATE_PAUSED','SUBSCRIPTION_STATE_EXPIRED']) assert.equal(entitlement(active(state),now).active,false);
});
test('grace period with current Google expiry is honored',()=>assert.equal(entitlement(active('SUBSCRIPTION_STATE_IN_GRACE_PERIOD'),now).active,true));
test('unknown products and invalid dates cannot grant premium',()=>{
 assert.equal(entitlement(active('SUBSCRIPTION_STATE_ACTIVE','2026-10-13T00:00:00Z','unrelated'),now).active,false);
 assert.equal(entitlement(active('SUBSCRIPTION_STATE_ACTIVE','bad'),now).active,false);
});
test('first purchase must bind to authenticated uid',()=>{
 assert.doesNotThrow(()=>assertOwner({externalAccountIdentifiers:{obfuscatedExternalAccountId:accountHash('a')}},'a'));
 assert.throws(()=>assertOwner({externalAccountIdentifiers:{obfuscatedExternalAccountId:accountHash('b')}},'a'));
});
test('legacy unbound purchases are not silently claimed',()=>assert.throws(()=>assertOwner({},'a'),/migration/));
test('existing token owner cannot be replaced',()=>assert.throws(()=>assertOwner({},'b','a'),/mismatch/));
test('verified legacy ownership can be retained',()=>assert.doesNotThrow(()=>assertOwner({},'a','a')));
const envelope=()=>({format:'maeumnyang-backup',version:1,salt:Buffer.alloc(16).toString('base64'),nonce:Buffer.alloc(12).toString('base64'),mac:Buffer.alloc(16).toString('base64'),ciphertext:'YQ=='});
test('backup accepts only bounded encrypted envelope',()=>{
 assert.equal(validEnvelope(envelope()),true);
 assert.equal(validEnvelope({...envelope(),letterText:'private diary'}),false);
 assert.equal(validEnvelope({...envelope(),salt:'a'}),false);
 assert.equal(validEnvelope({...envelope(),version:2}),false);
 assert.equal(validEnvelope({...envelope(),ciphertext:'a'.repeat(6*1024*1024+1)}),false);
});

test('verified current free-trial phase is distinguished from paid active',()=>{
 const p=active(); p.lineItems[0].offerPhase={freeTrial:{}};
 assert.equal(entitlement(p,now).state,'trial');
 assert.equal(entitlement(p,now).isTrial,true);
 assert.equal(entitlement(active(),now).state,'active');
});
test('trial with renewal cancelled remains accessible until expiry',()=>{
 const p=active('SUBSCRIPTION_STATE_CANCELED'); p.lineItems[0].offerPhase={freeTrial:{}};
 const result=entitlement(p,now);
 assert.equal(result.state,'cancelScheduled'); assert.equal(result.active,true); assert.equal(result.isTrial,true);
});
test('past known subscription is reported expired',()=>{
 assert.equal(entitlement(active('SUBSCRIPTION_STATE_EXPIRED','2026-09-12T00:00:00Z'),now).state,'expired');
});
