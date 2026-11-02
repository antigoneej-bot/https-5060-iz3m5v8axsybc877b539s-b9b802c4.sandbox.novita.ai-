import test from 'node:test';
import assert from 'node:assert/strict';
import { KNOWN_DECORATION_IDS, validatePublicSnapshot } from '../policy.js';
test('six new garden items can be published with existing items and positions', () => {
 const ids = ['daisy_pot','tulip_pot','sunflower_pot','cat_cushion','moon_lamp','bird_house'];
 assert.equal(KNOWN_DECORATION_IDS.size, 19);
 for (const id of ids) {
  assert.equal(validatePublicSnapshot({seedCounts:{pine:3},equippedDecorationIds:['bench',id],
    treeStageIndex:1,layout:{version:1,spaces:1,positions:{['decor:'+id]:[.5,.59]}}}),true);
 }
 assert.equal(validatePublicSnapshot({seedCounts:{},equippedDecorationIds:['arbitrary-item'],treeStageIndex:0}),false);
});
