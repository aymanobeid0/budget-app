# Accounts (username + password)

The app works without an account (as a **guest**). You can create an account from **Settings → Account** to keep your data safe across reinstalls and to switch between accounts.

## How it works
- **Guest**: an anonymous Supabase user. Data syncs, but it can't be recovered after the app is deleted.
- **Username → email**: Supabase Auth signs in with an email, so `ayman` becomes `ayman@budgetapp.local`. No email is ever sent. The domain is `AccountService.emailDomain`.
- **Password**: 6 or more characters (the Supabase default minimum).

| Action | What happens |
|---|---|
| Create account (as a guest) | Signs up, then re-uploads everything on this phone under the new account. |
| Create account (while signed in) | Backs up the current account, then starts the new account empty. |
| Sign in / Switch account | Backs up the current account (signed in only), signs in, clears this phone, then downloads the account's data. |
| Sign out | Backs up, clears this phone, continues as a new guest. |

Safety rules:
- If the current account's latest changes can't be uploaded, a switch or sign-out is **refused** and nothing changes.
- A guest signing into an existing account is warned that the guest's expenses will be replaced.
- If the download fails right after a sign-in, default categories are **not** re-seeded (so they can't overwrite the account's own categories). The download is retried on the next app start.
- Background syncs are paused during these flows, so one account's rows can't be pushed into another account.

Code: `lib/features/account/` (`AccountService` holds the rules; tests are in `test/features/account/account_service_test.dart`).

## Server requirements (self-hosted Supabase)
Already set in `supabase/docker/docker-compose.yml`:
- `GOTRUE_DISABLE_SIGNUP: "false"`: sign-ups allowed
- `GOTRUE_MAILER_AUTOCONFIRM: "true"`: no confirmation email (required for usernames)
- `GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED: "true"`: guest mode

**Apply the migrations** in `supabase/migrations/` to the server; `20261016000000_per_user_keys.sql` changes the primary keys to `(user_id, id)` so several accounts can each own the default categories (`cat_food`, …). Without it, the second account's sync is rejected. See "Database Schema & RLS Setup" in `docs/self_hosting_supabase.md`: the `Supabase migrations` GitHub workflow applies them on merge to `main`.
