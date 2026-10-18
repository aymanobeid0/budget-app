# Self-Hosting Supabase on VPS with Dokploy

This guide outlines how to deploy Supabase on your VPS using **Dokploy** for the Budget App.

---

## 🚀 Option 1: Dokploy 1-Click Template (Recommended)

Dokploy features an official one-click template for Supabase.

1. In your **Dokploy Dashboard**, open your project.
2. Click **Create Service** $\to$ Select **Template**.
3. Search for **Supabase** and click **Create**.
4. Go to the **Environment** tab:
   - Ensure `GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED` is set to `true` (critical for anonymous guest onboarding).
   - Verify that `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`, and `SERVICE_ROLE_KEY` are populated.
5. In **Domains**:
   - Map your API domain (e.g. `https://supabase.yourdomain.com`) to the **Kong** gateway service (**Port 8000**) and enable Let's Encrypt SSL.
   - (Optional) Map a domain or port for **Studio** (**Port 3000**) to access the dashboard.
6. Click **Deploy**.

---

## 🛠️ Option 2: Docker Compose Service in Dokploy

If you prefer creating a custom **Compose** service directly in Dokploy:

1. In Dokploy, click **Create Service** $\to$ **Compose**.
2. Copy the contents of [`supabase/docker/docker-compose.yml`](file:///d:/budget-app/supabase/docker/docker-compose.yml) into Dokploy's compose editor.
3. Configure your environment variables using [`supabase/docker/.env.example`](file:///d:/budget-app/supabase/docker/.env.example).
4. Click **Deploy**.

---

## 🗄️ Database Schema & RLS Setup

The tables and their row-level security live in `supabase/migrations/`. Every account shares the same tables; RLS on `user_id` keeps each account's rows to itself, so a new account needs no setup on the server.

### Automatically (recommended)

`.github/workflows/supabase-migrations.yml` applies new migration files whenever they reach `main`. The database port isn't public, so the job SSHes into the VPS and runs `psql` inside the database container. One-time setup:

1. On the VPS, check the database container's name with `docker ps` (it is `supabase-db` for the compose file in this repo; the Dokploy template names it differently).
2. Make an SSH key pair for GitHub (`ssh-keygen -t ed25519 -f budget-app-deploy -N ""`) and add `budget-app-deploy.pub` to `~/.ssh/authorized_keys` of a VPS user that can run `docker`.
3. In GitHub → **Settings → Secrets and variables → Actions**, add:
   - Secrets: `SUPABASE_SSH_HOST`, `SUPABASE_SSH_USER`, `SUPABASE_SSH_KEY` (contents of `budget-app-deploy`), and optionally `SUPABASE_SSH_KNOWN_HOSTS` (output of `ssh-keyscan <host>`).
   - Variables (only if not the default): `SUPABASE_DB_CONTAINER` (default `supabase-db`), `SUPABASE_SSH_PORT` (default `22`).
4. **Actions → Supabase migrations → Run workflow**, first with "dry run" ticked to see what is pending, then without.

Applied files are recorded in `supabase_migrations.schema_migrations`, so each runs once. Every migration is written to be safe to run again, so the first run against a server set up by hand is harmless.

### By hand

Run the same script from the VPS (or anywhere `psql` can reach the database):

```bash
PSQL="docker exec -i supabase-db psql -U postgres -d postgres" supabase/apply_migrations.sh
```

Or paste each pending file from `supabase/migrations/` into **Studio → SQL Editor** in filename order.

---

## 🔑 Configured Deployment Credentials

The Dokploy Supabase instance has been deployed and verified:
- **API URL (`SUPABASE_URL`):** `https://api.itlabservice.com`
- **Anonymous Key (`SUPABASE_ANON_KEY`):** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3OTE5OTg1NjQsImV4cCI6MTg5MzQ1NjAwMCwicm9sZSI6ImFub24iLCJpc3MiOiJzdXBhYmFzZSJ9.9eNXKCYAG4MpxmwbdQ1yBg0JTC6R9F_dXrGFIdKsEuI`
- **Studio Dashboard:** `https://api.itlabservice.com/` (HTTP Basic Auth: User `supabase`, Password configured in Dokploy)

### Running the App with Supabase Enabled

All credentials are saved in the root `.env` file (ignored by git, template in `.env.example`).
Run the app using:

```powershell
flutter run --dart-define-from-file=.env
```

Pre-configured run profiles in `.vscode/launch.json` ("Budget App (.env)") and `.idea/runConfigurations/main_dart.xml` automatically pass `--dart-define-from-file=.env` for 1-click execution.

