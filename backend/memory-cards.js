import {randomInt, createHash} from 'node:crypto';
import {readVillageAccess} from './garden-village.js';
export const themes=['rain','apple','moon','friends','artist','blossom'];
export const coats=['ginger','white','tabby','black','tuxedo','calico'];
export const cardIds=themes.flatMap(t=>coats.flatMap(c=>[0,1,2].map(f=>`${t}.${c}.${f}`)));
const valid=id=>typeof id==='string'&&cardIds.includes(id);
const ref=(db,uid)=>db.doc(`users/${uid}/memoryCards/state`);
const fresh=()=>({stock:{},display:[],claims:{},hearts:0});
const date=n=>new Date(n+32400000).toISOString().slice(0,10);
async function access(db,tx,a,b){
 if(typeof b!=='string'||!/^[A-Za-z0-9_-]{1,128}$/.test(b)||a===b)throw Error('invalid-target');
 const x=await readVillageAccess(db,a,b,tx),y=await readVillageAccess(db,b,a,tx);
 if(!x.alive||!y.alive||x.blocked||y.blocked||!x.accepted||!y.accepted)throw Error('neighbor-required');
}
export async function getMemoryCards(db,uid){
 const [s,trades]=await Promise.all([ref(db,uid).get(),db.collection(`users/${uid}/cardTrades`).orderBy('createdAt','desc').limit(100).get()]);
 return {cards:s.data()??fresh(),trades:trades.docs.map(d=>({id:d.id,...d.data()})),owner:uid};
}
export async function claimMemoryCard(db,uid,b,{now=Date.now(),pick=randomInt}={}){
 const source=b.source;
 if(!['daily','coloring'].includes(source))throw Error('invalid-card');
 if(source==='coloring'&&(!Array.isArray(b.colors)||b.colors.length!==12||b.colors.some(c=>!Number.isInteger(c)||c<0||c>4294967295)))throw Error('invalid-card');
 const chosen=cardIds[pick(cardIds.length)];
 return db.runTransaction(async tx=>{const s=structuredClone((await tx.get(ref(db,uid))).data()??fresh());
 if(s.claims[source]===date(now))return {cards:s,already:true};
 s.stock[chosen]=(s.stock[chosen]??0)+1;s.claims[source]=date(now);tx.set(ref(db,uid),s);return {cards:s,card:chosen,already:false};});
}
export async function setCardDisplay(db,uid,b){
 if(!Array.isArray(b.cards)||b.cards.length>3||new Set(b.cards).size!==b.cards.length||!b.cards.every(valid))throw Error('invalid-card');
 return db.runTransaction(async tx=>{const s=structuredClone((await tx.get(ref(db,uid))).data()??fresh());if(b.cards.some(id=>!(s.stock[id]>0)))throw Error('card-stock');s.display=b.cards;tx.set(ref(db,uid),s);return {cards:s};});
}
export async function getCardShowcase(db,uid,b){return db.runTransaction(async tx=>{
 await access(db,tx,uid,b.gardenId);
 const s=(await tx.get(ref(db,b.gardenId))).data()??fresh();
 return {display:s.display.filter(id=>s.stock[id]>0),duplicates:Object.keys(s.stock).filter(id=>s.stock[id]>1),hearts:s.hearts};
});}
export async function cheerCardShowcase(db,uid,b,{now=Date.now()}={}){return db.runTransaction(async tx=>{
 await access(db,tx,uid,b.gardenId);
 const receipt=db.doc(`users/${b.gardenId}/cardCheers/${uid}`),r=await tx.get(receipt);
 const s=structuredClone((await tx.get(ref(db,b.gardenId))).data()??fresh());
 if(r.data()?.day!==date(now)){s.hearts++;tx.set(ref(db,b.gardenId),s);tx.set(receipt,{day:date(now)});}
 return {hearts:s.hearts};
});}
export async function offerCardTrade(db,uid,b,{now=Date.now()}={}){
 if(!/^[a-f0-9]{32}$/.test(b.requestId??'')||!valid(b.give)||!valid(b.want)||b.give===b.want)throw Error('invalid-card');
 const id=b.requestId, own=db.doc(`users/${uid}/cardTrades/${id}`);
 const fingerprint=createHash('sha256').update(JSON.stringify([b.gardenId,b.give,b.want])).digest('hex');
 return db.runTransaction(async tx=>{
 await access(db,tx,uid,b.gardenId);
 const old=await tx.get(own),s=structuredClone((await tx.get(ref(db,uid))).data()??fresh());
 const other=(await tx.get(ref(db,b.gardenId))).data()??fresh();
 const pending=await tx.get(db.collection(`users/${uid}/cardTrades`).where('status','==','pending'));
 const mirror=db.doc(`users/${b.gardenId}/cardTrades/${id}`),collision=await tx.get(mirror);
 if(old.exists){if(old.data().fingerprint!==fingerprint)throw Error('request-conflict');return {trade:{id,...old.data()}};}
 if(collision.exists||pending.docs.length>=20)throw Error('card-trade-limit');
 if(!(s.stock[b.give]>1)||!(other.stock[b.want]>1))throw Error('card-stock');
 s.stock[b.give]--;
 const trade={sender:uid,receiver:b.gardenId,give:b.give,want:b.want,status:'pending',createdAt:now,expiresAt:now+7*86400000,fingerprint};
 tx.set(ref(db,uid),s);tx.set(own,trade);tx.set(mirror,trade);return {trade:{id,...trade}};
 });
}
export async function respondCardTrade(db,uid,b,{now=Date.now()}={}){
 if(!/^[a-f0-9]{32}$/.test(b.id??'')||!['accept','decline','cancel'].includes(b.response))throw Error('invalid-card');
 return db.runTransaction(async tx=>{
 const own=db.doc(`users/${uid}/cardTrades/${b.id}`),snap=await tx.get(own);if(!snap.exists)throw Error('card-trade-missing');
 const t=structuredClone(snap.data());
 if(![t.sender,t.receiver].includes(uid)||(b.response==='cancel'?uid!==t.sender:uid!==t.receiver))throw Error('invalid-card');
 if(t.status!=='pending')return {trade:{id:b.id,...t}};
 const accepting=b.response==='accept';
 if(accepting){if(now>=t.expiresAt)throw Error('card-trade-expired');await access(db,tx,t.sender,t.receiver);}
 const a=structuredClone((await tx.get(ref(db,t.sender))).data()??fresh());
 const c=structuredClone((await tx.get(ref(db,t.receiver))).data()??fresh());
 if(accepting){if(!(c.stock[t.want]>1))throw Error('card-stock');c.stock[t.want]--;a.stock[t.want]=(a.stock[t.want]??0)+1;c.stock[t.give]=(c.stock[t.give]??0)+1;t.status='accepted';}
 else{a.stock[t.give]=(a.stock[t.give]??0)+1;t.status=b.response==='cancel'?'cancelled':'declined';}
 t.resolvedAt=now;tx.set(ref(db,t.sender),a);if(accepting)tx.set(ref(db,t.receiver),c);
 tx.set(db.doc(`users/${t.sender}/cardTrades/${b.id}`),t);tx.set(db.doc(`users/${t.receiver}/cardTrades/${b.id}`),t);
 return {trade:{id:b.id,...t}};
 });
}
// Before deleting an account, return escrow to living counterpart owners.
export async function removeMemoryCards(db,uid){
 const pending=await db.collection(`users/${uid}/cardTrades`).where('status','==','pending').get();
 for(const d of pending.docs){const t=d.data();await respondCardTrade(db,uid,{id:d.id,response:uid===t.sender?'cancel':'decline'});}
 const all=await db.collection(`users/${uid}/cardTrades`).get();
 for(const d of all.docs){const t=d.data();await db.doc(`users/${uid===t.sender?t.receiver:t.sender}/cardTrades/${d.id}`).delete();}
}
export const memoryCardActions={getMemoryCards,claimMemoryCard,setCardDisplay,getCardShowcase,cheerCardShowcase,offerCardTrade,respondCardTrade};
