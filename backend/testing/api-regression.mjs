import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const root = new URL('../', import.meta.url).pathname.replace(/\/$/, '');
const {memoryDb} = await import('./memory-db.js');
const db = memoryDb();
const rows = db.rows;
const deleted = db.deleted;
const stamp=()=>({toDate:()=>new Date('2026-10-13T11:00:00Z')});
const auth={
 async verifyIdToken(uid){return {uid,email:uid+'@example.invalid',email_verified:true,auth_time:Date.now()/1000};},
 async deleteUser(){}, async getUser(uid){return {uid};}
};
const context=vm.createContext({console,Buffer,Date,Math,JSON,Map,Set,Object,Number,String,Error,Array,process:{env:{GARDEN_ANDROID_APP_ID:'test-app'}}});
const cache=new Map();
const stubs={
 'firebase-admin/app':{initializeApp:()=>{}},
 'firebase-admin/auth':{getAuth:()=>auth},
 'firebase-admin/app-check':{getAppCheck:()=>({verifyToken:async()=>({appId:'test-app'})})},
 'firebase-admin/firestore':{getFirestore:()=>db,FieldValue:{serverTimestamp:stamp,delete:()=>deleted}},
 'firebase-admin/storage':{getStorage:()=>({bucket:()=>({deleteFiles:async()=>{}})})},
 'firebase-functions/v2/https':{onRequest:(_,fn)=>fn},
 'firebase-functions/v2/pubsub':{onMessagePublished:(_,fn)=>fn},
 'google-auth-library':{GoogleAuth:class{}}
};
async function load(name){
 if(cache.has(name))return cache.get(name);
 let mod;
 if(name.startsWith(root)){
  mod=new vm.SourceTextModule(await fs.readFile(name,'utf8'),{context,identifier:name});
  cache.set(name,mod);
  await mod.link((spec,from)=>load(spec.startsWith('.')?new URL(spec,pathToFileURL(from.identifier)).pathname:spec));
 }else{
  const values=stubs[name]??await import(name);
  mod=new vm.SyntheticModule(Object.keys(values),function(){for(const [key,value]of Object.entries(values))this.setExport(key,value);},{context,identifier:name});
  cache.set(name,mod);
 }
 return mod;
}
const mod=await load(root+'/index.js');
await mod.evaluate();
async function call(uid,body){
 body = {deviceId: "device-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", ...body};
 let result={status:200};
 const req={method:'POST',body,rawBody:Buffer.from(JSON.stringify(body)),get:name=>name==='Authorization'?'Bearer '+uid:'test-appcheck'};
 const res={set(){return this;},status(code){result.status=code;return this;},json(value){result.body=value;return this;}};
 await mod.namespace.gardenApi(req,res);
 return result;
}

const publication={action:'publishGarden',nickname:'Alice garden',snapshot:{
  seedCounts:{pine:1},equippedDecorationIds:[],treeStageIndex:0,
}};
assert.equal((await call('alice',publication)).body.published,true);
// Even if the publishing device loses its response/local cache, a later
// authenticated query recovers the committed server decision.
const ownStatus=await call('alice',{action:'getMyPublicGardenStatus'});
assert.equal(ownStatus.body.published,true);
assert.equal(ownStatus.body.nickname,'Alice garden');
const otherStatus=await call('bob',{action:'getMyPublicGardenStatus',uid:'alice',gardenId:'alice'});
assert.equal(otherStatus.body.published,false);
assert.equal(otherStatus.body.nickname,null);
assert.equal((await call('alice',{action:'unpublishGarden'})).body.published,false);
assert.equal((await call('alice',{action:'unpublishGarden'})).body.published,false);
assert.equal((await call('alice',{action:'getMyPublicGardenStatus'})).body.published,false);
console.log('PASS: publication status is server-authoritative, account-scoped and recoverable after a lost response; stopping publication is idempotent.');

rows.clear();
rows.set('users/bob/receivedCheers/gift1',{giftLightEssence:5,claimed:false});
const oldClient = await call('bob',{action:'claimCheer',id:'gift1'});
assert.equal(oldClient.body.error, 'client-update-required');
const first=await call('bob',{action:'claimCheerV2',id:'gift1'});
const retry=await call('bob',{action:'claimCheerV2',id:'gift1'});
assert.equal(first.status, 200);
assert.equal(first.body.amount, 5);
assert.equal(retry.body.receipt, first.body.receipt);
assert.equal(retry.body.amount, 5);
const inbox=await call('bob',{action:'listMyCheers'});
assert.equal(inbox.body.cheers[0].id, 'gift1');
const ack=await call('bob',{action:'ackCheer',id:'gift1',receipt:first.body.receipt});
assert.equal(ack.body.acknowledged, true);
assert.equal((await call('bob',{action:'claimCheerV2',id:'gift1'})).body.amount, 0);
assert.equal((await call('bob',{action:'claimCheerV2',id:'../gift1'})).status, 400);
console.log('PASS: actual routes replay pending gifts, list them after lost responses, ACK idempotently and reject unsafe old clients.');

rows.clear();
rows.set('publicGardens/bob',{nickname:'test'});
const currency = await call('alice',{action:'sendPublicCheer',gardenId:'bob',messageIndex:0,giftLightEssence:5});
assert.equal(currency.status,403);
assert.equal(currency.body.error,'currency-gifts-unavailable');
assert.equal([...rows.keys()].some(k=>k.startsWith('users/bob/receivedCheers/')), false);
const payload={action:'sendPublicCheer',gardenId:'bob',messageIndex:0,flowerKind:'tulip',reaction:'heart'};
assert.equal((await call('alice',payload)).status,200);
assert.equal((await call('alice',payload)).status,200);
assert.equal([...rows.keys()].filter(k=>k.startsWith('users/bob/receivedCheers/')).length,1);
assert.equal(rows.get('publicGardens/bob').reactions.length,1);
assert.equal((await call('alice',{...payload,messageIndex:1})).status,409);
console.log('PASS: new currency is blocked; flowers/reactions survive; retry sends one flower and one reaction.');

rows.clear();
rows.set('publicGardens/bob',{nickname:'test'});
const {accountHash} = await import('../policy.js');
rows.set(`accountLocks/${accountHash('bob')}`,{deleting:true});
assert.equal((await call('alice',payload)).body.error,'garden-not-found');
assert.equal([...rows.keys()].some(k=>k.startsWith('users/bob/receivedCheers/')),false);
console.log('PASS: sending to a deleting account cannot recreate its received-gift data.');

rows.clear();
rows.set('gardenNews/n1',{reservedCount:2,capacity:2});
rows.set('gardenNewsReservations/n1_alice',{newsId:'n1',uid:'alice',email:'alice@example.invalid',note:'test'});
rows.set('gardenNewsReservations/n1_bob',{newsId:'n1',uid:'bob'});
rows.set('users/alice',{});
rows.set('publicGardens/alice',{});
const removal=await call('alice',{action:'deleteCloudAccount'});
assert.equal(removal.status,200);
assert.equal(rows.has('users/alice'),false);
assert.equal(rows.has('publicGardens/alice'),false);
assert.equal(rows.has('gardenNewsReservations/n1_alice'),false);
assert.equal(rows.has('gardenNewsReservations/n1_bob'),true);
assert.equal(rows.get('gardenNews/n1').reservedCount,1);
console.log('PASS: actual deletion route removes personal reservations and releases the correct seat.');
console.log('Local VM with fake Auth/AppCheck/Firestore/Storage; not real Firebase/device verification.');
