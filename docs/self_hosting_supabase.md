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

Once Supabase is running, open **Supabase Studio** (port 3000 or your studio domain) $\to$ **SQL Editor** $\to$ **New query**, and execute the following SQL to create the tables with Row-Level Security:

```sql
-- Categories: user-owned classification labels
create table if not exists public.categories (
  id          text primary key,
  user_id     uuid not null references auth.users (id) on delete cascade default auth.uid(),
  name        text not null,
  icon        text not null,
  color       bigint not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- Expenses: amount + category + date
create table if not exists public.expenses (
  id           text primary key,
  user_id      uuid not null references auth.users (id) on delete cascade default auth.uid(),
  amount_minor bigint not null check (amount_minor > 0),
  category_id  text not null references public.categories (id),
  spent_on     date not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

create index if not exists expenses_user_spent_on_idx on public.expenses (user_id, spent_on desc);

-- Enable Row Level Security (RLS)
alter table public.categories enable row level security;
alter table public.expenses   enable row level security;

-- Enforce user-scoped access policies
create policy "own categories" on public.categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own expenses" on public.expenses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

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

