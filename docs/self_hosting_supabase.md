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

The schema lives in [`supabase/migrations/`](../supabase/migrations/). It is the only copy, so this guide never repeats its SQL.

Once Supabase is running, open **Supabase Studio** (port 3000 or your studio domain) $\to$ **SQL Editor** $\to$ **New query**, and run **every file in `supabase/migrations/`, oldest first** (the file names start with a timestamp, so sort by name). Paste each whole file and click **Run** before moving to the next.

On a server that is already set up, run only the migrations it is missing. The later files are safe to run again, but `20261013000000_init_schema.sql` is not: run a second time, it fails with `policy "own categories" for table "categories" already exists`.

When a new migration is added to the repo, run it on the server too. Until you do, sync stops at the missing table with an error such as:

```
PostgrestException(message: Could not find the table 'public.income_sources' in the schema cache, code: PGRST205)
```

---

## 🔑 Configured Deployment

The Dokploy Supabase instance runs at:
- **API URL (`SUPABASE_URL`):** `https://api.itlabservice.com`
- **Studio Dashboard:** `https://api.itlabservice.com/` (HTTP Basic Auth: User `supabase`, Password configured in Dokploy)

The anon key (`SUPABASE_ANON_KEY`) is the `ANON_KEY` from the Supabase environment in Dokploy. Copy it from there into your `.env`; it is not kept in the repo.

### Running the App with Supabase Enabled

All credentials are saved in the root `.env` file (ignored by git, template in `.env.example`).
Run the app using:

```powershell
flutter run --dart-define-from-file=.env
```

Pre-configured run profiles in `.vscode/launch.json` ("Budget App (.env)") and `.idea/runConfigurations/main_dart.xml` automatically pass `--dart-define-from-file=.env` for 1-click execution.

