import test from 'node:test';import assert from 'node:assert/strict';
import {premiumFeatureAccess} from '../premium-test-access.js';
test('only explicit server test switch opens paid features without fabricating purchase status',async()=>{let calls=0;const verifiedStatus=async()=>{calls++;return {active:false};};assert.equal(await premiumFeatureAccess('a',{testSetting:'true',verifiedStatus}),true);assert.equal(calls,0);});
test('normal release settings use verified active subscription only',async()=>{for(const testSetting of [undefined,'false','TRUE','1',true]){assert.equal(await premiumFeatureAccess('a',{testSetting,verifiedStatus:async()=>({active:false})}),false);assert.equal(await premiumFeatureAccess('a',{testSetting,verifiedStatus:async()=>({active:true})}),true);}});
test('verification errors are not converted to paid access',async()=>{await assert.rejects(premiumFeatureAccess('a',{testSetting:'false',verifiedStatus:async()=>{throw Error('offline');}}),/offline/);});

test('production ignores stale global testing unlock',async()=>{
 assert.equal(await premiumFeatureAccess('a',{production:true,testSetting:'true',verifiedStatus:async()=>({active:false})}),false);
 assert.equal(await premiumFeatureAccess('a',{production:true,testSetting:'true',verifiedStatus:async()=>({active:true})}),true);
});
