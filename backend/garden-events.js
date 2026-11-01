import {queuePush, queueBookingChange, eventNoticeChanged} from './push-notifications.js';
import { createHash } from 'node:crypto';
import { URL } from 'node:url';
import { validateGardenNewsInput, sanitizeReservationNote } from './policy.js';
import { isGardenNewsAdmin } from './garden-news-admin.js';

// Only administrative event metadata and explicit booking fields are accepted.
// Journals, emotion scores and care history never belong in these documents.
export class GardenEventError extends Error {
  constructor(code, status = 400) { super(code); this.status = status; }
}
const fail = (code, status) => { throw new GardenEventError(code, status); };
const validId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value);
const text = (value, max) => typeof value === 'string'
  ? value.replace(/[\u0000-\u001f\u007f]/g, '').trim().slice(0, max) || null : null;
const iso = value => {
  if (typeof value !== 'string' || !/T.*(?:Z|[+-]\d{2}:\d{2})$/.test(value)) return null;
  const valueMs = Date.parse(value);
  return Number.isFinite(valueMs) ? new Date(valueMs).toISOString() : null;
};
const safeUrl = value => {
  if (value == null || value === '') return null;
  try {
    if (typeof value !== 'string' || value.length > 1000) return undefined;
    const url = new URL(value);
    return url.protocol === 'https:' && !url.username && !url.password ? url.toString() : undefined;
  } catch { return undefined; }
};
const readDate = value => typeof value === 'string' ? value : value?.toDate?.().toISOString() ?? null;

export function validateEventSessions(raw) {
  if (!Array.isArray(raw) || raw.length > 12) fail('invalid-event-sessions');
  const seen = new Set();
  return raw.map(slot => {
    if (!slot || !validId(slot.id) || seen.has(slot.id)) fail('invalid-event-sessions');
    seen.add(slot.id);
    const startsAt = iso(slot.startsAt), endsAt = iso(slot.endsAt);
    const bookingOpensAt = slot.bookingOpensAt == null ? null : iso(slot.bookingOpensAt);
    const bookingClosesAt = iso(slot.bookingClosesAt ?? slot.startsAt);
    if (!startsAt || !endsAt || !bookingClosesAt ||
        (slot.bookingOpensAt != null && !bookingOpensAt) ||
        Date.parse(endsAt) <= Date.parse(startsAt) ||
        Date.parse(bookingClosesAt) > Date.parse(startsAt) ||
        (bookingOpensAt && Date.parse(bookingOpensAt) >= Date.parse(bookingClosesAt)) ||
        !Number.isInteger(slot.capacity) || slot.capacity < 1 || slot.capacity > 1000 ||
        !['open', 'closed', 'canceled'].includes(slot.state ?? 'open')) fail('invalid-event-sessions');
    return {id: slot.id, label: text(slot.label, 60), startsAt, endsAt,
      bookingOpensAt, bookingClosesAt, capacity: slot.capacity,
      state: slot.state ?? 'open', reservedCount: 0};
  });
}

export function publicGardenNews(id, data, {admin = false} = {}) {
  return {id, title: data.title, body: data.body, emoji: data.emoji, type: data.type,
    status: data.status ?? null, period: data.period ?? null, location: data.location ?? null,
    cost: data.cost ?? null, applyUrl: data.applyUrl ?? null, capacity: data.capacity ?? null,
    reservedCount: data.reservedCount ?? 0, eventMode: data.eventMode ?? null,
    sessions: (data.sessions ?? []).map(slot => ({id: slot.id, label: slot.label ?? null,
      startsAt: slot.startsAt, endsAt: slot.endsAt, bookingOpensAt: slot.bookingOpensAt ?? null,
      bookingClosesAt: slot.bookingClosesAt, capacity: slot.capacity,
      reservedCount: slot.reservedCount ?? 0, state: slot.state ?? 'open'})),
    ...(admin ? {meetingUrl: data.meetingUrl ?? null, deleting: data.deleting === true} : {}),
    createdAt: readDate(data.createdAt), updatedAt: readDate(data.updatedAt)};
}
function reservationView(id, data) {
  return {id, newsId: data.newsId, sessionId: data.sessionId ?? null,
    displayName: data.displayName ?? null, note: data.note ?? null,
    sessionStartsAt: data.sessionStartsAt ?? null,
    createdAt: readDate(data.createdAt)};
}
const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object'
  ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])])) : value;
const digest = value => createHash('sha256').update(JSON.stringify(canonical(value))).digest('hex');
function requireNewsId(value) { if (!validId(value)) fail('invalid-id'); return value; }

export async function saveGardenEvent(db, uid, identity, input, id, {stamp = () => new Date().toISOString(), requestId = null} = {}) {
  if (!isGardenNewsAdmin(identity)) fail('admin-required', 403);
  const parsed = validateGardenNewsInput(input);
  if (!parsed) fail('invalid-news');
  const hasSessions = Object.hasOwn(input, 'sessions');
  const nextSessions = hasSessions ? validateEventSessions(input.sessions) : null;
  if (nextSessions?.length && parsed.type !== 'event') fail('invalid-event-sessions');
  const eventMode = input.eventMode ?? null;
  if (eventMode !== null && !['online', 'offline'].includes(eventMode)) fail('invalid-event-mode');
  const meetingUrl = safeUrl(input.meetingUrl);
  if (meetingUrl === undefined) fail('invalid-event-link');
  if (requestId != null && (!validId(requestId) || id != null)) fail('invalid-request-id');
  // Legacy clients remain supported. Updated clients persist this key before sending.
  const receipt = requestId == null ? null : db.doc(`gardenNewsCreateReceipts/${digest([uid, requestId])}`);
  const fingerprint = digest({parsed, sessions: nextSessions, eventMode, meetingUrl: meetingUrl ?? null});
  const ref = id == null ? db.collection('gardenNews').doc() : db.doc(`gardenNews/${requireNewsId(id)}`);
  let savedId = ref.id;
  await db.runTransaction(async tx => {
    if (receipt) {
      const priorReceipt = await tx.get(receipt);
      if (priorReceipt.exists) {
        if (priorReceipt.data().fingerprint !== fingerprint) fail('request-payload-mismatch', 409);
        const saved = await tx.get(db.doc(`gardenNews/${priorReceipt.data().newsId}`));
        if (!saved.exists || saved.data().deleting) fail('news-not-found', 404);
        savedId = saved.id;
        return;
      }
    }
    const current = id == null ? null : await tx.get(ref);
    if (id != null && !current.exists) fail('news-not-found', 404);
    const prior = current?.data() ?? {};
    if (prior.deleting) fail('news-not-found', 404);
    const oldSessions = prior.sessions ?? [];
    const sessions = nextSessions ?? oldSessions;
    const effectiveMode = Object.hasOwn(input, 'eventMode') ? eventMode : prior.eventMode ?? null;
    if (sessions.length && parsed.type !== 'event') fail('invalid-event-sessions');
    if (sessions.length && !effectiveMode) fail('invalid-event-mode');
    if (hasSessions && nextSessions.length && !oldSessions.length && (prior.reservedCount ?? 0) > 0) {
      fail('event-has-reservations', 409);
    }
    // A legacy booking must remain cancellable and visible after metadata edits.
    if (!oldSessions.length && (prior.reservedCount ?? 0) > 0 &&
        (!sessions.length && (parsed.capacity == null || parsed.capacity < prior.reservedCount))) {
      fail('event-has-reservations', 409);
    }
    for (const old of oldSessions) {
      const next = sessions.find(slot => slot.id === old.id);
      if ((old.reservedCount ?? 0) > 0 && (!next || next.startsAt !== old.startsAt ||
          next.endsAt !== old.endsAt || next.capacity < old.reservedCount)) fail('event-has-reservations', 409);
    }
    const counted = sessions.map(slot => ({...slot,
      reservedCount: oldSessions.find(old => old.id === slot.id)?.reservedCount ?? 0}));
    if (receipt) tx.set(receipt, {newsId: ref.id, fingerprint, createdAt: stamp()});
    if (current?.exists && eventNoticeChanged(prior, {...prior, ...parsed, sessions: counted, eventMode: effectiveMode, meetingUrl: meetingUrl ?? prior.meetingUrl})) queueBookingChange(tx, db, ref.id, parsed.title);
    tx.set(ref, {...parsed, sessions: counted,
      capacity: counted.length ? null : parsed.capacity,
      eventMode: effectiveMode,
      meetingUrl: effectiveMode === 'offline' ? null :
        Object.hasOwn(input, 'meetingUrl') ? meetingUrl : prior.meetingUrl ?? null,
      reservedCount: prior.reservedCount ?? 0, createdBy: prior.createdBy ?? uid,
      createdAt: prior.createdAt ?? stamp(), updatedAt: stamp()});
  });
  return {id: savedId};
}

export async function reserveGardenEvent(db, uid, identity, input, {now = Date.now, stamp = () => new Date().toISOString()} = {}) {
  const newsId = requireNewsId(input.newsId);
  const newsRef = db.doc(`gardenNews/${newsId}`);
  const bookingRef = db.doc(`gardenNewsReservations/${newsId}_${uid}`);
  return db.runTransaction(async tx => {
    const news = await tx.get(newsRef), booking = await tx.get(bookingRef);
    if (!news.exists) fail('news-not-found', 404);
    const data = news.data(), sessions = data.sessions ?? [];
    if (data.deleting === true) fail('reservation-closed', 403);
    const selected = sessions.length ? sessions.find(slot => slot.id === input.sessionId) : null;
    if (sessions.length && !selected) fail('event-session-required');
    if (!sessions.length && input.sessionId != null) fail('invalid-event-session');
    if (booking.exists) {
      if ((booking.data().sessionId ?? null) !== (selected?.id ?? null)) fail('already-reserved', 409);
      return {reserved: true, reservation: reservationView(bookingRef.id, booking.data()),
        news: publicGardenNews(newsId, data)};
    }
    if (data.status === 'closed' || data.deleting === true) fail('reservation-closed', 403);
    if (selected) {
      if (selected.state !== 'open' || now() >= Date.parse(selected.bookingClosesAt) ||
          now() >= Date.parse(selected.startsAt)) fail('reservation-closed', 403);
      if (selected.bookingOpensAt && now() < Date.parse(selected.bookingOpensAt)) fail('reservation-not-open', 403);
      if ((selected.reservedCount ?? 0) >= selected.capacity) fail('reservation-full', 409);
    } else {
      if (data.capacity == null) fail('reservation-not-available', 403);
      if ((data.reservedCount ?? 0) >= data.capacity) fail('reservation-full', 409);
    }
    const reservation = {newsId, uid, sessionId: selected?.id ?? null,
      sessionStartsAt: selected?.startsAt ?? null,
      email: identity.email_verified === true ? identity.email ?? null : null,
      displayName: text(input.displayName, 40), note: sanitizeReservationNote(input.note), createdAt: stamp()};
    const update = {reservedCount: (data.reservedCount ?? 0) + 1};
    if (selected) update.sessions = sessions.map(slot => slot.id === selected.id
      ? {...slot, reservedCount: (slot.reservedCount ?? 0) + 1} : slot);
    tx.set(bookingRef, reservation); tx.update(newsRef, update);
    return {reserved: true, reservation: reservationView(bookingRef.id, reservation),
      news: publicGardenNews(newsId, {...data, ...update})};
  });
}

export function releaseEventSeat(data, sessionId) {
  return {reservedCount: Math.max(0, (data.reservedCount ?? 0) - 1),
    ...(sessionId && Array.isArray(data.sessions) ? {sessions: data.sessions.map(slot => slot.id === sessionId
      ? {...slot, reservedCount: Math.max(0, (slot.reservedCount ?? 0) - 1)} : slot)} : {})};
}
export async function cancelGardenEvent(db, uid, input) {
  const newsId = requireNewsId(input.newsId), newsRef = db.doc(`gardenNews/${newsId}`);
  const bookingRef = db.doc(`gardenNewsReservations/${newsId}_${uid}`);
  return db.runTransaction(async tx => {
    const news = await tx.get(newsRef), booking = await tx.get(bookingRef);
    if (!booking.exists) return {canceled: true, news: news.exists ? publicGardenNews(newsId, news.data()) : null};
    const update = news.exists ? releaseEventSeat(news.data(), booking.data().sessionId) : null;
    tx.delete(bookingRef);
    if (update) tx.update(newsRef, update);
    return {canceled: true, news: update ? publicGardenNews(newsId, {...news.data(), ...update}) : null};
  });
}

export const gardenNewsActions = new Set(['listGardenNews', 'getGardenNews', 'adminCreateGardenNews',
  'adminUpdateGardenNews', 'adminDeleteGardenNews', 'adminListGardenNewsReservations',
  'reserveGardenNews', 'cancelGardenNewsReservation', 'myGardenNewsReservations', 'getGardenEventAccess']);

export async function handleGardenNewsAction(db, uid, identity, action, input, deps = {}) {
  if (!gardenNewsActions.has(action)) return null;
  const admin = isGardenNewsAdmin(identity);
  if (action.startsWith('admin') && !admin) fail('admin-required', 403);
  if (action === 'listGardenNews') {
    const snap = await db.collection('gardenNews').orderBy('createdAt', 'desc').limit(50).get();
    return {news: snap.docs.filter(doc => admin || !doc.data().deleting).map(doc => publicGardenNews(doc.id, doc.data(), {admin}))};
  }
  if (action === 'getGardenNews' || action === 'getGardenEventAccess') {
    const newsId = requireNewsId(input.newsId), news = await db.doc(`gardenNews/${newsId}`).get();
    if (!news.exists || (news.data().deleting && (!admin || action === 'getGardenEventAccess'))) fail('news-not-found', 404);
    if (action === 'getGardenNews') return {news: publicGardenNews(newsId, news.data(), {admin})};
    const reservation = await db.doc(`gardenNewsReservations/${newsId}_${uid}`).get();
    if (!admin && !reservation.exists) fail('reservation-required', 403);
    const selected = (news.data().sessions ?? []).find(slot => slot.id === reservation.data()?.sessionId);
    if (selected?.state === 'canceled') fail('event-canceled', 403);
    return {meetingUrl: news.data().meetingUrl ?? null};
  }
  if (action === 'adminCreateGardenNews' || action === 'adminUpdateGardenNews') {
    return saveGardenEvent(db, uid, identity, input.news, action === 'adminCreateGardenNews' ? null : requireNewsId(input.id), {...deps, requestId: input.requestId ?? null});
  }
  if (action === 'adminDeleteGardenNews') {
    const newsId = requireNewsId(input.id), ref = db.doc(`gardenNews/${newsId}`);
    // Close before cleanup so no new booking can commit during deletion.
    await db.runTransaction(async tx => { const old = await tx.get(ref);
      if (old.exists) tx.update(ref, {deleting: true, status: 'closed'}); });
    while (true) {
      const page = await db.collection('gardenNewsReservations').where('newsId', '==', newsId).limit(100).get();
      if (page.empty) break;
      const noticeTitle = (await ref.get()).data()?.title ?? '예약한 모임';
      for (const doc of page.docs) await db.runTransaction(async tx => {
        const booking = await tx.get(doc.ref);
        if (!booking.exists) return;
        queuePush(tx, db, `cancel:${doc.id}`, booking.data().uid, 'booking', Date.now(), {title: noticeTitle, sessionStartsAt: booking.data().sessionStartsAt ?? null, notice: '운영자가 모임 공지를 삭제했어요. 신청이 취소됐어요.'});
        tx.delete(doc.ref);
      });
    }
    await ref.delete(); return {deleted: true};
  }
  if (action === 'adminListGardenNewsReservations') {
    const newsId = requireNewsId(input.newsId);
    const snap = await db.collection('gardenNewsReservations').where('newsId', '==', newsId).get();
    return {reservations: snap.docs.map(doc => ({...reservationView(doc.id, doc.data()), email: doc.data().email ?? null}))
      .sort((a, b) => (a.sessionStartsAt ?? '').localeCompare(b.sessionStartsAt ?? '') ||
        (a.createdAt ?? '').localeCompare(b.createdAt ?? ''))};
  }
  if (action === 'reserveGardenNews') return reserveGardenEvent(db, uid, identity, input, deps);
  if (action === 'cancelGardenNewsReservation') return cancelGardenEvent(db, uid, input);
  const snap = await db.collection('gardenNewsReservations').where('uid', '==', uid).get();
  const reservations = await Promise.all(snap.docs.map(async doc => {
    const reservation = reservationView(doc.id, doc.data());
    const news = await db.doc(`gardenNews/${reservation.newsId}`).get();
    const available = news.exists && !news.data().deleting;
    return {...reservation, eventUnavailable: !available,
      news: available ? publicGardenNews(news.id, news.data()) : null};
  }));
  return {newsIds: reservations.map(row => row.newsId), reservations};
}
