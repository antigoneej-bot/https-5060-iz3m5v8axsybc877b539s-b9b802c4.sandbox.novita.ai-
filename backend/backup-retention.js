// Preserve several recent edits plus older daily recovery points. Frequent
// foreground backups must not erase every previous day's copy in minutes.
export function keepBackupIds(versions) {
  const kept = new Set(versions.slice(0, 5).map(v => v.id));
  const days = new Set(versions.slice(0, 5).map(v => v.day).filter(Boolean));
  for (const version of versions.slice(5)) {
    if (kept.size >= 10) break;
    if (version.day && !days.has(version.day)) {kept.add(version.id); days.add(version.day);}
  }
  for (const version of versions) {
    if (kept.size >= 10) break;
    kept.add(version.id);
  }
  return kept;
}
