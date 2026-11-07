import {createHash, randomUUID} from 'node:crypto';
const hash = value => createHash('sha256').update(value).digest('hex');
const categories = new Set(['social', 'booking']);
const validToken = value => typeof value === 'string' && /^[A-Za-z0-9_:.-]{32,4096}$/.test(value);

export async function setPushDevice(db, uid, input, now = Date.now()) {
  if (!validToken(input.token) || typeof input.enabled !== 'boolean' ||
      (input.enabled && (typeof input.social !== 'boolean' || typeof input.booking !== 'boolean'))) throw new Error('invalid-push-settings');
  if (input.bellSound !== undefined && typeof input.bellSound !== 'boolean') throw new Error('invalid-push-settings');
  if (input.language !== undefined && !['ko', 'en'].includes(input.language)) throw new Error('invalid-push-settings');
  const ref = db.doc(`gardenPushDevices/${hash(input.token)}`);
  await db.runTransaction(async tx => {
    const old = await tx.get(ref);
    if (!input.enabled) {
      // A delayed logout must not unregister the same device's newer account.
      if (old.data()?.uid === uid) tx.delete(ref);
      return;
    }
    tx.set(ref, {uid, language: input.language ?? (old.data()?.uid === uid ? old.data()?.language ?? 'ko' : 'ko'), token: input.token, social: input.social, booking: input.booking, ...(typeof input.bellSound === 'boolean' ? {bellSound: input.bellSound} : {}), updatedAt: now, lastBellAt: old.data()?.uid === uid ? (old.data()?.lastBellAt ?? 0) : 0});
  });
  return {registered: input.enabled};
}
export function queuePush(tx, db, id, uid, category, now = Date.now(), details = {}) {
  tx.set(db.doc(`gardenPushJobs/${hash(id)}`), {uid, category, ...details, createdAt: now, expiresAt: now + 86400000, state: 'queued'});
}
export function eventNoticeChanged(before, after) {
  if (!before || before.type !== 'event') return false;
  const view = news => [news.title, news.body, news.period, news.location, news.cost,
    news.eventMode, news.meetingUrl, (news.sessions ?? []).map(s => [s.id, s.startsAt, s.endsAt, s.state === 'canceled'])];
  return JSON.stringify(view(before)) !== JSON.stringify(view(after));
}
export function queueBookingChange(tx, db, newsId, title, now = Date.now()) {
  tx.set(db.collection('gardenPushJobs').doc(), {kind: 'bookingFanout', newsId, title, createdAt: now, expiresAt: now + 86400000, state: 'queued'});
}
export async function listGardenUpdates(db, uid, now = Date.now()) {
  const rows = await db.collection('gardenPushJobs').where('uid', '==', uid).get();
  return {updates: rows.docs.map(d => d.data()).filter(d => d.category === 'booking' && now - d.createdAt < 30 * 86400000)
    .sort((a,b) => b.createdAt-a.createdAt).slice(0,30).map(d => ({title: d.title ?? '예약한 모임',
      notice: d.notice ?? '모임 안내가 변경됐어요.', sessionStartsAt: d.sessionStartsAt ?? null, createdAt: d.createdAt}))};
}
export async function removePushDevices(db, uid) {
  const jobs = await db.collection('gardenPushJobs').where('uid', '==', uid).get();
  for (const job of jobs.docs) await db.recursiveDelete(job.ref);
  const devices = await db.collection('gardenPushDevices').where('uid', '==', uid).get();
  for (const device of devices.docs) await db.runTransaction(async tx => {
    if ((await tx.get(device.ref)).data()?.uid === uid) tx.delete(device.ref);
  });
}
export async function deliverPushJob(db, id, messaging, now = Date.now()) {
  const ref = db.doc(`gardenPushJobs/${id}`), lease = randomUUID();
  const job = await db.runTransaction(async tx => {
    const snap = await tx.get(ref), job = snap.data();
    if (!job || job.state === 'sent' || job.state === 'skipped') return null;
    if (job.expiresAt <= now || (job.attempts ?? 0) >= 10) {tx.update(ref, {state: 'skipped'}); return null;}
    if ((job.leaseUntil ?? 0) > now) throw new Error('push-job-busy');
    tx.update(ref, {lease, leaseUntil: now + 90000, attempts: (job.attempts ?? 0) + 1});
    return job;
  });
  if (!job) return;
  try {
    if (job.kind === 'bookingFanout') {
      let query = db.collection('gardenNewsReservations').where('newsId', '==', job.newsId).orderBy('__name__');
      if (job.cursor) query = query.startAfter(job.cursor);
      const bookings = await query.limit(100).get();
      for (const booking of bookings.docs) {
        const data = booking.data();
        const created = data.createdAt?.toMillis?.() ?? Date.parse(data.createdAt);
        if (!Number.isFinite(created) || created > job.createdAt || !data.uid) continue;
        const child = db.doc(`gardenPushJobs/${hash(`${id}:${data.uid}`)}`);
        await db.runTransaction(async tx => {
          const prior = await tx.get(child);
          if (!prior.exists) tx.set(child, {uid: data.uid, category: 'booking', title: job.title ?? '예약한 모임', sessionStartsAt: data.sessionStartsAt ?? null, notice: '모임 안내가 변경됐어요. 내 신청 내역에서 확인해 주세요.', createdAt: job.createdAt, expiresAt: job.expiresAt, state: 'queued'});
        });
      }
      if (bookings.docs.length === 100) {
        await db.runTransaction(async tx => {
          if ((await tx.get(ref)).data()?.lease === lease) tx.update(ref, {cursor: bookings.docs.at(-1).id, attempts: 0, leaseUntil: 0});
        });
        throw new Error('push-fanout-continue');
      }
    } else if (categories.has(job.category) && typeof job.uid === 'string') {
      const devices = await db.collection('gardenPushDevices').where('uid', '==', job.uid).get();
      let transientFailure = false;
      for (const device of devices.docs) {
        // Fresh read honors an opt-out/account switch while this job was queued.
        const current = (await device.ref.get()).data();
        if (current?.uid !== job.uid || current[job.category] !== true || now - current.updatedAt > 30 * 86400000) continue;
        const receipt = db.doc(`gardenPushJobs/${id}/deliveries/${device.id}`);
        if ((await receipt.get()).exists) continue;
        try {
          const sound = current.bellSound === true && await db.runTransaction(async tx => {
            const fresh = (await tx.get(device.ref)).data();
            if (fresh?.uid !== job.uid || fresh.bellSound !== true || fresh[job.category] !== true || now - (fresh.lastBellAt ?? 0) < 3000) return false;
            tx.update(device.ref, {lastBellAt: now});
            return true;
          });
          await messaging.send({token: current.token,
            notification: pushCopy(job.category, current.language),
            data: {kind: job.category, owner: hash(job.uid), notice: id},
            android: {ttl: Math.max(0, job.expiresAt - now), collapseKey: job.category,
              notification: {channelId: sound ? 'garden_updates_bell_v1' : typeof current.bellSound === 'boolean' ? 'garden_updates_silent_v1' : 'garden_updates', ...(sound ? {sound: 'garden_bell'} : {}), tag: job.category}},
          });
          await receipt.set({sentAt: now});
        } catch (error) {
          if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(error.code)) {
            await db.runTransaction(async tx => {const latest = await tx.get(device.ref);
              if (latest.data()?.uid === job.uid && latest.data()?.token === current.token) tx.delete(device.ref);});
          } else transientFailure = true;
        }
      }
      if (transientFailure) throw new Error('push-delivery-retry');
    }
    await db.runTransaction(async tx => {
      if ((await tx.get(ref)).data()?.lease === lease) tx.update(ref, {state: 'sent', leaseUntil: 0, finishedAt: now});
    });
  } catch (error) {
    await db.runTransaction(async tx => {
      if ((await tx.get(ref)).data()?.lease === lease) tx.update(ref, {leaseUntil: 0});
    });
    throw error;
  }
}

export function pushCopy(category, language) {
  return language === 'en'
    ? {title: 'Mindnyang Garden', body: category === 'social'
      ? 'New encouragement or a gift has arrived in your garden.'
      : 'An event you registered for has changed. Open the app for details.'}
    : {title: '마음냥 정원', body: category === 'social'
      ? '정원에 새로운 응원이나 선물이 도착했어요.'
      : '예약한 모임에 변경 소식이 있어요. 앱에서 확인해 주세요.'};
}
