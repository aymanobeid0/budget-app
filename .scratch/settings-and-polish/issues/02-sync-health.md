# 02: See whether your data is synced

**Status:** ready-for-agent
**Blocked by:** none

The `SyncEngine` already tracks `SyncState` (`lib/core/sync/sync_status.dart`), but nothing shows it. Settings shows the current sync state next to "Sync now" (synced, syncing, offline, error, or "not connected" when there is no Supabase), and Home shows a small, quiet indicator only when something needs attention (offline or error), so the user knows their data is safe on the phone but not yet in their account.

- [ ] Settings shows the live sync state and updates while a sync runs
- [ ] Home shows an indicator only while offline or after a failed sync, and it clears after a successful sync
- [ ] With no Supabase configured, Settings says data is kept on this phone only
