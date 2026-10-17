# 03: Sync again when the connection comes back

**Status:** resolved
**Blocked by:** none

Today sync runs only at startup and after a change (`unawaited(syncEngine.sync())` in the ledgers). Changes made offline wait until the next change or restart. After a sync ends offline or in error, the engine retries on a backoff (for example 5s, 15s, 1 min, then every 5 min) until one succeeds, and the app also syncs when it returns to the foreground. Retries pause while `AccountService` has background syncs paused for an account switch.

- [x] An offline sync is retried automatically and succeeds once the cloud is reachable (tested with a fake clock and fake cloud)
- [x] Backoff resets after a successful sync; no retry timer runs while synced
- [x] Returning the app to the foreground triggers a sync
- [x] Retries never run during an account switch or sign-out
