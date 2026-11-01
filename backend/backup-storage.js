// Check the existing configured bucket. Never create a bucket, broaden access,
// or switch to a different bucket when the configured one is unavailable.
export async function requireBackupStorage(storage, uid) {
  try {
    const bucket = storage.bucket();
    // Cleanup already requires objects.list. Check only this verified owner's
    // prefix, without introducing buckets.get or reading file contents.
    await bucket.getFiles({prefix:`backups/${uid}/`, maxResults:1, autoPaginate:false});
    return bucket;
  } catch {
    throw new Error('backup-storage-unavailable');
  }
}
