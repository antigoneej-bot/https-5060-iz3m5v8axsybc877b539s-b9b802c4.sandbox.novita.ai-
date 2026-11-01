import {randomBytes} from 'node:crypto';
import {readVillageAccess} from './garden-village.js';

const coats = ['ginger','white','tabby','black','tuxedo','calico'];
const idOk = id => typeof id === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(id);
const incoming = (db, guest, host) => db.doc(`users/${guest}/catInvitations/${host}`);
const history = (db, owner, id) => db.doc(`users/${owner}/catVisits/${id}`);
export function catAppearance(value) {
  if (!value || Object.keys(value).some(k => !['coat','stage','name'].includes(k)) ||
      !coats.includes(value.coat) || !Number.isInteger(value.stage) || value.stage < 0 || value.stage > 3 ||
      typeof value.name !== 'string' || !value.name.trim() || [...value.name].length > 20 || /[\x00-\x1f\x7f]/.test(value.name)) throw new Error('invalid-cat-visit');
  return {coat: value.coat, stage: value.stage, name: value.name.trim()};
}
async function access(db, guest, host, tx) {
  if (!idOk(host) || !idOk(guest) || host === guest) throw new Error('invalid-target');
  const a = await readVillageAccess(db, guest, host, tx);
  const b = await readVillageAccess(db, host, guest, tx);
  if (!a.visible || !a.accepted || !b.accepted || !b.alive || b.blocked) throw new Error('cat-visit-unavailable');
  return a;
}
function dto(v) {
  return {id:v.id, hostId:v.hostId, guestId:v.guestId, hostNickname:v.hostNickname ?? null,
    guestNickname:v.guestNickname ?? null, hostCat:v.hostCat,
    ...(v.guestCat ? {guestCat:v.guestCat} : {}), status:v.status,
    createdAt:v.createdAt, expiresAt:v.expiresAt, visitedAt:v.visitedAt ?? null};
}
export async function inviteCatVisit(db, uid, body, {now = Date.now()} = {}) {
  const guest = body.gardenId, cat = catAppearance(body.cat);
  return db.runTransaction(async tx => {
    const a = await access(db, guest, uid, tx);
    const ref = incoming(db,guest,uid), old = (await tx.get(ref)).data();
    const profile = (await tx.get(db.doc(`villageProfiles/${guest}`))).data();
    // A lost response returns the same invitation; no duplicate notices or visits.
    if (old?.status === 'pending' && old.expiresAt > now) {
      if (JSON.stringify(old.hostCat) !== JSON.stringify(cat)) throw new Error('request-conflict');
      return {invitation:dto(old)};
    }
    if (old && now - old.createdAt < 86400000) throw new Error('cat-invite-daily-limit');
    const value = {id:randomBytes(16).toString('hex'),hostId:uid,guestId:guest,
      hostNickname:a.garden.data().nickname ?? null, guestNickname:profile?.nickname ?? null,
      hostCat:cat,status:'pending',createdAt:now,expiresAt:now+7*86400000};
    tx.set(ref,value);
    tx.set(db.doc(`users/${uid}/catInvitationsSent/${guest}`),value);
    return {invitation:dto(value)};
  });
}
export async function respondCatVisit(db, uid, body, {now = Date.now()} = {}) {
  const host = body.gardenId;
  if (typeof body.accept !== 'boolean' || !idOk(body.invitationId)) throw new Error('invalid-cat-visit');
  const cat = body.accept ? catAppearance(body.cat) : null;
  return db.runTransaction(async tx => {
    await access(db,uid,host,tx);
    const ref=incoming(db,uid,host), value=(await tx.get(ref)).data();
    if (!value || value.id !== body.invitationId || value.guestId !== uid || value.hostId !== host) throw new Error('cat-visit-unavailable');
    if (value.status === 'accepted' && body.accept) {
      const old=(await tx.get(history(db,uid,value.id))).data();
      if (!old || JSON.stringify(old.guestCat)!==JSON.stringify(cat)) throw new Error('request-conflict');
      return {visit:dto(old)};
    }
    if (value.status === 'declined' && !body.accept) return {declined:true};
    if (value.status !== 'pending' || value.expiresAt <= now) throw new Error('cat-visit-unavailable');
    const next={...value,status:body.accept?'accepted':'declined'};
    tx.set(ref,next);tx.set(db.doc(`users/${host}/catInvitationsSent/${uid}`),next);
    if (!body.accept) return {declined:true};
    const visit={...next,guestCat:cat,visitedAt:now};
    tx.set(history(db,uid,value.id),visit);tx.set(history(db,host,value.id),visit);
    return {visit:dto(visit)};
  });
}
export async function listCatVisits(db, uid, body, {now = Date.now()} = {}) {
  const [invites,visits,sent] = await Promise.all([
    db.collection(`users/${uid}/catInvitations`).orderBy('createdAt','desc').limit(30).get(),
    db.collection(`users/${uid}/catVisits`).orderBy('visitedAt','desc').limit(30).get(),
    db.collection(`users/${uid}/catInvitationsSent`).orderBy('createdAt','desc').limit(30).get(),
  ]);
  const invitations=[], memories=[];
  for (const doc of invites.docs) {
    const v=doc.data();
    if(v.guestId!==uid || v.status!=='pending' || v.expiresAt<=now) continue;
    try {await access(db,v.guestId,v.hostId);invitations.push(dto(v));} catch(e) {if(e.message!=='cat-visit-unavailable') throw e;}
  }
  for (const doc of visits.docs) {
    const v=doc.data();
    if(![v.hostId,v.guestId].includes(uid)) continue;
    try {await access(db,v.guestId,v.hostId);memories.push(dto(v));} catch(e) {if(e.message!=='cat-visit-unavailable') throw e;}
  }
  return {invitations,memories,sent:sent.docs.map(d=>d.data()).filter(v=>v.hostId===uid && v.status==='pending' && v.expiresAt>now).map(dto)};
}
export async function getCatVisit(db, uid, body, {now=Date.now()}={}) {
  if(!idOk(body.visitId)) throw new Error('invalid-cat-visit');
  return db.runTransaction(async tx=>{
    const v=(await tx.get(history(db,uid,body.visitId))).data();
    if(!v || v.status!=='accepted' || v.guestId!==uid || now-v.visitedAt>30*60000) throw new Error('cat-visit-unavailable');
    await access(db,uid,v.hostId,tx);
    return {visit:dto(v)};
  });
}
export async function cancelCatVisit(db, uid, body) {
  if(!idOk(body.gardenId) || !idOk(body.invitationId)) throw new Error('invalid-cat-visit');
  return db.runTransaction(async tx=>{
    const ref=incoming(db,body.gardenId,uid), v=(await tx.get(ref)).data();
    if(!v || v.hostId!==uid || v.id!==body.invitationId) throw new Error('cat-visit-unavailable');
    if(v.status==='cancelled')return {cancelled:true};
    if(v.status!=='pending')throw new Error('cat-visit-unavailable');
    const next={...v,status:'cancelled'};
    tx.set(ref,next);tx.set(db.doc(`users/${uid}/catInvitationsSent/${body.gardenId}`),next);
    return {cancelled:true};
  });
}
export async function removeCatVisits(db, uid) {
  for(const group of ['catInvitations','catInvitationsSent','catVisits']) {
    const rows=await db.collection(`users/${uid}/${group}`).get();
    for(const doc of rows.docs) {
      const v=doc.data(), other=v.hostId===uid?v.guestId:v.hostId;
      if(idOk(other) && other!==uid) {
        const mirror=group==='catVisits'?history(db,other,doc.id):
          group==='catInvitations'?db.doc(`users/${other}/catInvitationsSent/${uid}`):incoming(db,other,uid);
        await mirror.delete();
      }
      await doc.ref.delete();
    }
  }
}
export const catVisitActions={inviteCatVisit,respondCatVisit,listCatVisits,getCatVisit,cancelCatVisit};
