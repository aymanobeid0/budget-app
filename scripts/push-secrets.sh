#!/usr/bin/env bash
# Uploads the release secrets the Android workflow needs to GitHub.
# Run it again only when the signing key or the Supabase settings change:
#   bash scripts/push-secrets.sh
#
# Prints names, never values. Needs `gh auth login` once.
set -euo pipefail
cd "$(dirname "$0")/.."

for f in android/upload-keystore.jks android/key.properties .env; do
  [ -f "$f" ] || { echo "Missing $f" >&2; exit 1; }
done
gh auth status >/dev/null 2>&1 || { echo "Run 'gh auth login' first." >&2; exit 1; }

base64 -w0 android/upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEY_PROPERTIES < android/key.properties

# Only the two public Supabase values: whatever DOTENV holds is built into
# an APK anyone can download from Releases.
dotenv=$(grep -E '^(SUPABASE_URL|SUPABASE_ANON_KEY)=' .env || true)
[ "$(printf '%s\n' "$dotenv" | grep -c .)" -eq 2 ] ||
  { echo ".env needs SUPABASE_URL and SUPABASE_ANON_KEY lines." >&2; exit 1; }
printf '%s\n' "$dotenv" | gh secret set DOTENV

echo "Secrets set:"
gh secret list
