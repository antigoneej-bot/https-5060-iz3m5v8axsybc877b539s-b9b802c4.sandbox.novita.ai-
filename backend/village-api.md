# 냥이 마을 API (2026-10-16)

All actions use the existing POST `gardenApi`, verified Firebase account + Android App Check and account lease/rate limits. Client Firestore access stays denied. These local source changes are not a deployed Firebase service.

## Actions

| Action | Request fields | Response |
|---|---|---|
| getVillageProfile | none | inviteCode, visibility, discoveryOptIn, receiveGifts, nickname |
| updateVillageProfile | optional visibility/private-neighbors-public, discoveryOptIn/bool, receiveGifts/bool, nickname | same profile |
| publishGarden | existing validated snapshot; optional nickname + three privacy settings, OR appearanceOnly:true with none of those fields | published, nickname, visibility, discoveryOptIn, receiveGifts, snapshot, updatedAt |
| getMyPublicGardenStatus | none | published, nickname, visibility, discoveryOptIn, receiveGifts, snapshot, updatedAt |
| unpublishGarden | none | published:false, nickname:null; profile scope becomes private and discovery is off |
| listNeighbors | none | neighbors, incoming, outgoing, blocked (gardenId, nickname, status, requestedAt; active cards include canVisit) |
| lookupNeighbor | inviteCode | gardenId, nickname, status, requestedAt, canVisit; never the private garden snapshot |
| requestNeighbor | inviteCode OR gardenId | requested, status (outgoing/incoming/accepted) |
| respondNeighbor | gardenId, accept/bool | accepted/bool; only the actual incoming recipient can accept |
| removeNeighbor | gardenId | removed:true; symmetric removal, also cancels outgoing requests |
| getNeighborGarden | gardenId | garden: existing sanitized public DTO + receiveGifts |
| listPublicGardens | optional cursor/string, pageSize/integer1..24 (default12) | gardens, nextCursor; only explicitly discoverable public gardens |
| blockNeighbor | gardenId, blocked/bool | blocked/bool; blocking also removes both neighbor edges |
| reportGarden | gardenId, reason | reported:true; reason: inappropriate_name/harassment/spam/other |
| sendPublicCheer | gardenId, messageIndex 0..5, deliveryKind cheer/gift, reaction optional, flowerKind optional | sent:true |
| sendGardenGift | gardenId, sourceCheerId, requestId | sent:true, id, sourceCheerId |
| listMyCheers | optional cursor/string, pageSize/integer1..80 (default80) | cheers, retiredIds, nextCursor |

A new account is private, not discoverable, receiving gifts enabled. Existing old public snapshots remain public to direct permitted visits but are **not** automatically listed in discovery. Explicit public selection alone does not imply discovery consent. Non-public scopes always clear discoveryOptIn. A legacy publish keeps an established private/neighbors/public scope. Explicit `publishGarden visibility:private` atomically stores the sanitized snapshot while returning published:false; neighbors cannot view a private snapshot.

Invite codes are random stable 12-character hex codes in server-only records. A code allows a nickname preview and neighbor request, not access to a private garden or automatic acceptance. Both directions of blocking hide discovery, direct visits, code lookup, incoming/outgoing relationship cards, inbox/flower notices and deny sends/claims/new planting acknowledgments. No account IDs, names, email addresses or contacts are searched by arbitrary text.

## Flowers and reactions

Five gift flowers: daisy, tulip, hydrangea, gypsophila, lavender. Reactions: heart, star, hug, butterfly; these expire after 24 hours.

`deliveryKind:cheer` has no plantable flower (`flowerKind:null` is permitted), may be sent to a visible public garden, and does not require a subscription. `deliveryKind:gift` requires an accepted neighbor and receiveGifts:true. It creates one free daily flower; it does **not** debit local inventory. Each sender/recipient/kind permits one payload per Korea calendar day; retrying the same payload succeeds without duplication. Legacy requests with no deliveryKind mean gift and obey the same neighbor/privacy checks. Currency gifting remains rejected.

`sendGardenGift` moves an **unplanted, untransferred, server-issued received flower**, not a locally reported seed or purchased item. `requestId` must be 16..128 alphanumeric, underscore or hyphen characters, stable across retries. The transaction marks the source retired and creates exactly one target item. A reused request ID for another payload fails request-conflict. A different request ID cannot reuse a transferred source. A concurrent planting confirmation and transfer cannot both commit. Gift transfer works regardless of whether the recipient publishes a garden, provided the accounts are accepted neighbors and receiving is enabled.

`listMyCheers` pages received history, even after a reaction expires, and includes every transferred source ID in retiredIds on every page. The first page additionally preserves the previous bounded unclaimed (80) and pending-delivery (30) recovery queries, including legacy pending records with no createdAt. Those supplements may make the first response larger than pageSize and may recur in later ordered history; merge by item ID. Subsequent pages contain only ordered history. Each item includes id, messageIndex, giftLightEssence, flowerKind, reaction, deliveryKind, senderGardenId, senderNickname, createdAt, claimed, bloomConfirmed and plantedFlowerKind. A pure cheer has no flower. Clients must retire IDs before merging the server inbox. A confirmed historical flower keeps its plantedFlowerKind. `confirmFlowerPlanted` rejects transferred/non-flower items and a forged flower kind, while a prior successful confirmation is idempotent.

## Pagination and owner publication updates (2026-10-16 follow-up)

Both paged requests accept an omitted/null cursor for refresh and return nextCursor:null only after that scan is exhausted. Pass the opaque nextCursor unchanged for the next request. Cursor format is versioned, action/account scoped, size limited, validated and never grants access; every page repeats current privacy, deletion and bilateral blocking checks. Invalid cursor or pageSize returns HTTP400 (`invalid-cursor` / `invalid-page-size`). Old clients can ignore the added response fields and keep their previous first-page behavior.

- Discovery seeks by document ID ascending and inspects at most80 candidates per call (plus one look-ahead). It returns at mostpageSize visible gardens. A page may be empty with a non-null cursor when all inspected candidates are hidden; show a further-page action rather than treating that as exhaustion. This reaches profiles beyond the former fixed first80. Order is stable traversal, not popularity or a ranking. Refresh includes new profiles inserted before the current position.
- Received history seeks by createdAt DESC and document ID DESC. The timestamp cursor retains seconds/nanoseconds, so equal or submillisecond timestamps neither drop nor repeat items. Cursor records may be deleted without invalidating the seek position. Filters and transferred records still advance the cursor. New incoming items are found by refresh, not injected into an in-progress older-history scan. Claimed/planted historical flowers remain available on later pages with bloomConfirmed/plantedFlowerKind intact.
- Keep retiring `retiredIds` before merging any page. The historical global transfer-tombstone query is deliberately retained for cross-device stale inventory safety and old client compatibility; it is not yet paged. This means history reads are bounded per page, but accounts with extremely many transfers still have a growing tombstone response. A future delta/tombstone migration must preserve the existing no-resurrection guarantee.
- First-page pending/unclaimed recovery is a compatibility fallback, not an inventory completeness claim. Follow history pages to recover older claimed/confirmed flowers on a new installation. Malformed legacy records missing createdAt are not in the ordered history; valid server-written flowers always have createdAt. Existing missing-date unclaimed/pending records retain the first-page fallback.

`getMyPublicGardenStatus` and a successful `publishGarden` now return an **owner-only** allowlisted `snapshot` (seedCounts, equippedDecorationIds, treeStageIndex, memoryTreeStage, hasCheerFlowers, flowerKinds, layout) and resolved server `updatedAt` ISO string. When no stored garden exists, both are null. Private stored snapshots are returned only to their authenticated owner with published:false; visitor DTOs do not change. Diary text, emotions, memorial notes and invitation codes are never included.

To update an already shared appearance without changing settings, send `{action:"publishGarden",snapshot,appearanceOnly:true}` and omit nickname/visibility/discoveryOptIn/receiveGifts. The server preserves the latest nickname and all three privacy settings even if another device has since made the garden private. It never uses the old automatic-public default in appearanceOnly mode. Combining this mode with any setting/name is rejected. Normal publication with omitted nickname also preserves the existing name. The publication response reads back the committed document so updatedAt is a resolved server timestamp rather than a guessed client timestamp.

These queries use the standard automatic collection indexes: villageProfiles.discoveryOptIn ASC with document ID ASC, and receivedCheers.createdAt DESC with document ID DESC (the index's default same-direction ID tie-breaker). No new composite index or secret is introduced. Keep these single-field indexes enabled; if production has index exemptions, restore them before deploying. Reference: https://firebase.google.com/docs/firestore/query-data/index-overview . The supplied collection-group cleanup indexes remain required independently.

## Deployment and moderation

1. Deploy the supplied Firestore indexes **before** updated functions and wait until the three collection-group indexes are ready. They are required for account-deletion cleanup (receivedCheers.senderId, blockedNeighbors.targetId, flowerBlooms.recipientId). Include `"indexes":"backend/firestore.indexes.json"` in the firestore section of firebase.json.
2. Deploy the updated functions for pagination and owner appearance updates, even if the previous village functions are already live. Client-only deployment does not enable these new response/request fields. Keep unchanged deny-all client Firestore rules. Existing Auth/App Check configuration remains required. No credentials, project IDs or secrets were changed.
3. Reports are stored in `villageReports` with curated reasons and state:pending for an authorized operator to review in Firebase/admin tooling. This is a report intake, **not** an implemented automatic moderation system. Do not advertise automatic intervention or guaranteed response times.
4. Test with two actual accounts/devices: code request/accept, private-neighbor-public scope, discovery opt-in, both block directions, one daily reaction/flower, received flower transfer then planting, duplicate retry, receiving disabled, account switch and account deletion. Local Node tests do not verify deployed rules, indexes, App Check or real devices.

Account deletion removes the code/profile, both neighbor edges, recent moderation/log data and external block/flower notices; external received gifts remain but sender identity/name are anonymized. Existing deletion tombstones still prevent concurrent sends/requests/notifications recreating a deleting account. The authenticated server never reads or publishes private letter text or emotional statistics for village features.
