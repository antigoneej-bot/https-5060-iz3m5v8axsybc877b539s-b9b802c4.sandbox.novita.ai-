// Run in Cloud Shell with a restricted operator IAM identity.
import {initializeApp} from 'firebase-admin/app';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {resolveGardenReport, restoreCommunityAccess} from './community-policy.js';
const [command, reportId, decision] = process.argv.slice(2);
if (!process.env.GOOGLE_CLOUD_PROJECT) throw new Error('Set GOOGLE_CLOUD_PROJECT explicitly');
initializeApp({projectId: process.env.GOOGLE_CLOUD_PROJECT});
const db = getFirestore();
if (command === 'list') {
  const rows = await db.collection('villageReports').where('state','==','pending').limit(50).get();
  console.log(JSON.stringify(rows.docs.map(d => ({id:d.id, targetId:d.data().targetId, reason:d.data().reason, kind:d.data().kind ?? 'garden', treeId:d.data().treeId ?? null, noteId:d.data().noteId ?? null})),null,2));
} else if (command === 'restore' && process.env.MODERATION_OPERATOR) {
  console.log(await restoreCommunityAccess(db, reportId, process.env.MODERATION_OPERATOR, () => FieldValue.serverTimestamp()));
} else if (command === 'resolve' && process.env.MODERATION_OPERATOR) {
  console.log(await resolveGardenReport(db, reportId, decision, process.env.MODERATION_OPERATOR, () => FieldValue.serverTimestamp()));
} else throw new Error('Use list OR resolve REPORT_ID dismiss|hide|suspend; set MODERATION_OPERATOR for audit attribution');
