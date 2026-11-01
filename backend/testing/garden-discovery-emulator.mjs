import assert from 'node:assert/strict';
import fs from 'node:fs';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import * as village from '../garden-village.js';
import {randomPublicGarden, getPublicVisitGarden, setFavoriteGarden, listFavoriteGardens} from '../garden-discovery.js';

const project='demo-mindnyang-discovery', host='127.0.0.1:8185';
assert.equal(process.env.FIRESTORE_EMULATOR_HOST,host,'Only the isolated local emulator is allowed');
const app=initializeApp({projectId:project},'discovery-emulator-tests'),db=getFirestore(app);
const results=[];
const deps={stamp:()=>FieldValue.serverTimestamp(),random:()=>0,accountExists:async()=>true};
const snapshot={seedCounts:{pine:3},equippedDecorationIds:['bench'],treeStageIndex:1,memoryTreeStage:2,
 layout:{version:1,spaces:1,positions:{'decor:bench':[.5,.8]}},publicCat:{coat:'calico',stage:2}};
try{
 const reset=await fetch(`http://${host}/emulator/v1/projects/${project}/databases/(default)/documents`,{method:'DELETE'});assert.equal(reset.status,200);
 await db.doc('publicGardens/legacy').set({...snapshot,nickname:'legacy',email:'SECRET_EMAIL',letters:['SECRET_LETTER']});
 await db.doc('villageProfiles/legacy').set({visibility:'public',discoveryOptIn:true});
 assert.equal((await randomPublicGarden(db,'viewer',{},deps)).garden,null);
 results.push({check:'existing-public-consent-does-not-enroll-in-random',passed:true});
 for(const id of ['bob','carol','dave'])await village.publishVillageGarden(db,id,{snapshot,nickname:id,visibility:'public',discoveryOptIn:true,randomVisitOptIn:true},deps);
 const index=await db.collection('gardenDiscovery').get();assert.equal(index.size,3);for(const d of index.docs)assert.deepEqual(Object.keys(d.data()).sort(),['rank','version']);
 const recent=[];for(let i=0;i<6;i++)recent.push((await randomPublicGarden(db,'viewer',{},deps)).garden.gardenId);
 assert.equal(new Set(recent.slice(0,3)).size,3);for(let i=1;i<recent.length;i++)assert.notEqual(recent[i],recent[i-1]);
 assert.equal((await db.collection('users/viewer/neighbors').get()).size,0);
 results.push({check:'real-firestore-rank-range-wrap-recent-history-and-read-only-visits',passed:true});
 await setFavoriteGarden(db,'viewer',{gardenId:'bob',favorite:true},deps);
 assert.equal((await getPublicVisitGarden(db,'viewer',{gardenId:'bob'},deps)).garden.isFavorite,true);
 await village.updateVillageProfile(db,'bob',{visibility:'private'},deps);
 assert.equal((await db.doc('gardenDiscovery/bob').get()).exists,false);
 await assert.rejects(getPublicVisitGarden(db,'viewer',{gardenId:'bob'},deps),/garden-not-found/);
 const hidden=await listFavoriteGardens(db,'viewer',{},deps);assert.equal(hidden.gardens.length,0);assert.deepEqual(hidden.unavailableIds,['bob']);
 await setFavoriteGarden(db,'viewer',{gardenId:'bob',favorite:false},deps);
 results.push({check:'real-firestore-consent-withdrawal-favorites-and-removal',passed:true});
 await village.blockNeighbor(db,'carol',{gardenId:'viewer',blocked:true},deps);
 await assert.rejects(getPublicVisitGarden(db,'viewer',{gardenId:'carol'},deps),/garden-not-found/);
 await assert.rejects(village.sendVillageCheer(db,'viewer',{gardenId:'carol',messageIndex:0,deliveryKind:'cheer',reaction:'heart'},deps),/garden-not-found/);
 results.push({check:'incoming-block-denies-visit-and-cheer',passed:true});
 const send={gardenId:'dave',messageIndex:0,deliveryKind:'cheer',reaction:'heart'};
 await Promise.all(Array.from({length:5},()=>village.sendVillageCheer(db,'viewer',send,deps)));
 assert.equal((await db.collection('users/dave/receivedCheers').get()).size,1);
 assert.equal((await db.doc('publicGardens/dave').get()).data().reactions.length,1);
 results.push({check:'concurrent-real-firestore-cheer-retries-create-one-delivery-and-one-reaction',passed:true});
 await db.doc('publicGardens/dave').set({email:'SECRET_EMAIL',privateMemories:[{date:'SECRET_DATE',text:'SECRET_NOTE'}],publicCat:{coat:'black',stage:1,name:'SECRET_CAT'}},{merge:true});
 assert.equal(JSON.stringify(await getPublicVisitGarden(db,'viewer',{gardenId:'dave'},deps)).includes('SECRET'),false);
 for(const collection of ['gardenDiscovery','publicGardens','villageProfiles','users']){
  const response=await fetch(`http://${host}/v1/projects/${project}/databases/(default)/documents/${collection}?pageSize=1`);
  assert.equal(response.status,403,collection);
 }
 const forbiddenWrite=await fetch(`http://${host}/v1/projects/${project}/databases/(default)/documents/gardenDiscovery/attacker`,{method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({fields:{rank:{doubleValue:.5}}})});assert.equal(forbiddenWrite.status,403);
 results.push({check:'private-payload-whitelist-and-deny-all-direct-client-read-write-rules',passed:true});
 console.log(JSON.stringify({project,host,productionContacted:false,results},null,2));
 if(process.env.DISCOVERY_TEST_OUTPUT)fs.writeFileSync(process.env.DISCOVERY_TEST_OUTPUT,JSON.stringify({project,host,productionContacted:false,results},null,2));
}finally{await db.terminate();await deleteApp(app);}
