export const FLOWERS = ['daisy','tulip','hydrangea','gypsophila','lavender'];
export const REACTIONS = ['heart','star','hug','butterfly'];
export function validGardenGift(body) {
  return (body.flowerKind === undefined || (body.deliveryKind === 'cheer' && body.flowerKind === null) || FLOWERS.includes(body.flowerKind)) &&
    (body.reaction === undefined || body.reaction === null || REACTIONS.includes(body.reaction));
}
export function liveReactions(items, now = Date.now()) {
  return (Array.isArray(items) ? items : []).filter(r => REACTIONS.includes(r?.kind) && typeof r.expiresAt === 'string' && r.expiresAt.length <= 64 && Number.isFinite(Date.parse(r.expiresAt)) && Date.parse(r.expiresAt) > now).slice(-12).map(r => ({kind: r.kind, expiresAt: r.expiresAt}));
}
export function newGardenReaction(kind, now = Date.now()) {
  if (!REACTIONS.includes(kind)) return null;
  return {kind, expiresAt: new Date(now + 24 * 60 * 60 * 1000).toISOString()};
}
