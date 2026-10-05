import test from 'node:test';
import assert from 'node:assert/strict';
import {validGardenGift,liveReactions,newGardenReaction} from '../garden-gifts.js';
test('old clients and curated flowers/reactions valid, unknown values rejected',()=>{
 assert.equal(validGardenGift({}),true);
 assert.equal(validGardenGift({flowerKind:'hydrangea',reaction:'heart'}),true);
 assert.equal(validGardenGift({flowerKind:'bad'}),false);
 assert.equal(validGardenGift({reaction:'custom-text'}),false);
});
test('reaction lifetime is exactly 24 hours and expires at the boundary',()=>{
 const now=Date.parse('2026-10-04T23:58:00Z');const r=newGardenReaction('heart',now);
 assert.equal(Date.parse(r.expiresAt)-now,86400000);
 assert.equal(liveReactions([r],now+86399999).length,1);
 assert.equal(liveReactions([r],now+86400000).length,0);
 assert.deepEqual(liveReactions([null,{kind:'bad',expiresAt:r.expiresAt}, {kind:'heart',expiresAt:'bad'}],now),[]);
 assert.equal(liveReactions(Array(20).fill(r),now).length,12);
});
