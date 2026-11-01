import {createHash} from 'node:crypto';
import {readVillageAccess} from './garden-village.js';
export const ORCHARD = Object.freeze({apple:{price:0,sale:5},persimmon:{price:50,sale:6},tuna:{price:70,sale:7},chicken:{price:90,sale:8},kibble:{price:110,sale:9}});
const DAY=86400000, CYCLE=7*DAY;
const ref=(db,uid)=>db.doc(`users/${uid}/orchard/state`);
const fresh=now=>({coins:0,trees:{apple:{startedAt:now,care:0,lastWaterDay:null,cycle:0}},stock:{},gifts:[],fed:0});
const day=now=>new Date(now+9*3600000).toISOString().slice(0,10);
function view(s,now){return {...s,serverNow:now,trees:Object.fromEntries(Object.entries(s.trees).map(([k,t])=>{
 const progress=Math.min(1,Math.max(0,(now-t.startedAt+t.care*12*3600000)/CYCLE));
 return [k,{...t,progress,ready:progress>=1,yield:10+4*t.care,canWater:t.care<5&&t.lastWaterDay!==day(now),stage:Math.min(4,Math.floor(progress*5))}];
}))};}
export async function getOrchard(db,uid,body,{now=Date.now()}={}) {
 return db.runTransaction(async tx=>{let s=(await tx.get(ref(db,uid))).data();if(!s){s=fresh(now);tx.set(ref(db,uid),s);}return {orchard:view(s,now)};});
}
export async function mutateOrchard(db,uid,body,{now=Date.now()}={}) {
 const {requestId,op,kind,quantity=1,gardenId=null}=body;
 if(typeof requestId!=='string'|| !/^[a-f0-9]{32}$/.test(requestId)|| !['buy','water','harvest','sell','gift','feed'].includes(op)||typeof kind!=='string'||!Object.hasOwn(ORCHARD,kind)||!Number.isSafeInteger(quantity)||quantity<1||quantity>999||(['buy','water','harvest','feed'].includes(op)&&quantity!==1))throw new Error('invalid-orchard');
 if(op==='gift'&&(typeof gardenId!=='string'|| !/^[A-Za-z0-9_-]{1,128}$/.test(gardenId)||gardenId===uid))throw new Error('invalid-target');
 if(op==='feed'&&!['tuna','chicken','kibble'].includes(kind))throw new Error('invalid-orchard');
 const fingerprint=createHash('sha256').update(JSON.stringify({op,kind,quantity,gardenId})).digest('hex');
 const receipt=db.doc(`users/${uid}/orchardRequests/${requestId}`);
 return db.runTransaction(async tx=>{
 const [old,snap]=await Promise.all([tx.get(receipt),tx.get(ref(db,uid))]);
 const s=structuredClone(snap.data()??fresh(now));
 if(old.exists){if(old.data().fingerprint!==fingerprint)throw new Error('request-conflict');return {orchard:view(s,now),result:old.data().result};}
 let receiver, nickname;
 if(op==='gift'){
  const a=await readVillageAccess(db,uid,gardenId,tx),b=await readVillageAccess(db,gardenId,uid,tx);
  if(!a.alive||!b.alive||a.blocked||b.blocked||!a.accepted||!b.accepted)throw new Error('neighbor-required');
  if(!a.settings.receiveGifts)throw new Error('gifts-disabled');
  receiver=structuredClone((await tx.get(ref(db,gardenId))).data()??fresh(now));
  nickname=(await tx.get(db.doc(`villageProfiles/${uid}`))).data()?.nickname??'이웃';
 }
 const tree=s.trees[kind], spec=ORCHARD[kind]; let result={op,kind,quantity};
 if(op==='buy'){
  if(tree)throw new Error('orchard-owned');if(s.coins<spec.price)throw new Error('orchard-coins');
  s.coins-=spec.price;s.trees[kind]={startedAt:now,care:0,lastWaterDay:null,cycle:0};
 }else if(op==='water'){
  if(!tree)throw new Error('invalid-orchard');if(tree.care>=5||tree.lastWaterDay===day(now))throw new Error('orchard-watered');
  tree.care++;tree.lastWaterDay=day(now);
 }else if(op==='harvest'){
  if(!tree||!view(s,now).trees[kind].ready)throw new Error('orchard-not-ready');
  result.quantity=10+4*tree.care;s.stock[kind]=(s.stock[kind]??0)+result.quantity;
  s.trees[kind]={startedAt:now,care:0,lastWaterDay:tree.lastWaterDay,cycle:tree.cycle+1};
 }else{
  if((s.stock[kind]??0)<quantity)throw new Error('orchard-stock');s.stock[kind]-=quantity;
  if(op==='sell'){s.coins+=quantity*spec.sale;result.coins=quantity*spec.sale;}
  if(op==='feed')s.fed++;
  if(op==='gift'){
   receiver.stock[kind]=(receiver.stock[kind]??0)+quantity;
   receiver.gifts=[{kind,quantity,senderName:nickname,receivedAt:now},...receiver.gifts].slice(0,30);
  }
 }
 if(s.coins>1000000000||Object.values(s.stock).some(n=>n>1000000)||receiver&&Object.values(receiver.stock).some(n=>n>1000000))throw new Error('orchard-full');
 tx.set(ref(db,uid),s);if(receiver)tx.set(ref(db,gardenId),receiver);
 tx.set(receipt,{fingerprint,result,createdAt:now});
 return {orchard:view(s,now),result};
 });
}
export const orchardActions={getOrchard,mutateOrchard};
