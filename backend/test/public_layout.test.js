import test from 'node:test';
import assert from 'node:assert/strict';
import {validatePublicSnapshot,validatePublicLayout} from '../policy.js';
const layout = {version:1,spaces:3,positions:{'seed:pine':[.2,.6],'decor:bench':[.8,.8]}};
const snapshot = {seedCounts:{pine:3},equippedDecorationIds:['bench'],treeStageIndex:1};
test('old snapshots and explicit expanded layout remain valid',()=>{
 assert.equal(validatePublicSnapshot(snapshot),true);
 assert.equal(validatePublicSnapshot({...snapshot,layout}),true);
});
test('public snapshots reject private content and unknown fields',()=>{
 assert.equal(validatePublicSnapshot({...snapshot,letter:'secret'}),false);
 assert.equal(validatePublicLayout({...layout,note:'private'}),false);
 assert.equal(validatePublicLayout({...layout,positions:{'private:note':[.5,.6]}}),false);
});
test('layout rejects locked zones, malformed points and out-of-bounds coordinates',()=>{
 assert.equal(validatePublicLayout({...layout,spaces:1}),false);
 for(const point of [[NaN,.6],[Infinity,.6],[.5,.99],[.01,.7],['.5',.6],[.5]])
   assert.equal(validatePublicLayout({...layout,positions:{'seed:pine':point}}),false);
 assert.equal(validatePublicLayout({...layout,spaces:4}),false);
});
test('keepsakes expose appearance only, never records or response counts',()=>{
 assert.equal(validatePublicSnapshot({...snapshot,memoryTreeStage:3,hasCheerFlowers:true}),true);
 for(const value of [-1,5,1.5,'3',null]) assert.equal(validatePublicSnapshot({...snapshot,memoryTreeStage:value}),false);
 for(const value of [3,'true',{},null]) assert.equal(validatePublicSnapshot({...snapshot,hasCheerFlowers:value}),false);
 for(const key of ['memoryDays','letters','cheers','senderUid','cheerCount']) assert.equal(validatePublicSnapshot({...snapshot,[key]:1}),false);
});
