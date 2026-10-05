export const FLOWERS = ['daisy','tulip','hydrangea','gypsophila','lavender'];
export const REACTIONS = ['heart','star','hug','butterfly'];
export function validGardenGift(body) {
  return (body.flowerKind === undefined || FLOWERS.includes(body.flowerKind)) &&
    (body.reaction === undefined || body.reaction === null || REACTIONS.includes(body.reaction));
}
export function liveReactions(items, now = Date.now()) {
  return (Array.isArray(items) ? items : []).filter(r => REACTIONS.includes(r?.kind) && Number.isFinite(Date.parse(r.expiresAt)) && Date.parse(r.expiresAt) > now).slice(-12);
}
export function newGardenReaction(kind, now = Date.now()) {
  if (!REACTIONS.includes(kind)) return null;
  return {kind, expiresAt: new Date(now + 24 * 60 * 60 * 1000).toISOString()};
}
