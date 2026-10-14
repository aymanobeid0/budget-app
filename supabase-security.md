# Supabase VPS Hardening & Security Guide

This document outlines the security architecture and hardening steps to ensure your self-hosted Supabase deployment on Dokploy is completely locked down, preventing unauthorized access from scanners, bots, or malicious actors.

---

## 1. 🚨 Immediate Priority: Secret Rotation

Any production secrets that were previously displayed or transmitted in plain text (`JWT_SECRET`, `POSTGRES_PASSWORD`, `DASHBOARD_PASSWORD`, `SECRET_KEY_BASE`, `VAULT_ENC_KEY`) must be rotated immediately in Dokploy.

> [!WARNING]
> Anyone possessing your `JWT_SECRET` can forge arbitrary `service_role` tokens to bypass PostgreSQL Row-Level Security entirely.

1. In your **Dokploy Dashboard**, navigate to your Supabase project $\to$ **Environment Variables**.
2. Generate fresh, cryptographically random values (32+ characters) for:
   - `JWT_SECRET`
   - `POSTGRES_PASSWORD`
   - `DASHBOARD_PASSWORD`
   - `SECRET_KEY_BASE`
   - `VAULT_ENC_KEY`
3. Generate new `ANON_KEY` and `SERVICE_ROLE_KEY` signed with the new `JWT_SECRET`.
4. Redeploy the Supabase stack in Dokploy.
5. Update your local Flutter `.vscode/launch.json` and `.idea/runConfigurations/main_dart.xml` with the new `ANON_KEY`.

---

## 2. 🛡️ Network Isolation (Docker Port Security)

By default, Docker Compose can expose ports to `0.0.0.0`, making internal services directly accessible across the public internet.

### Requirements:
- **Only Port 8000 (Envoy API Gateway) should be mapped** to the host or router for HTTPS traffic.
- **Never expose internal service ports** to the public internet:
  - Database (`db`: port `5432` / `supavisor`: port `6543`)
  - GoTrue Auth (`auth`: port `9999`)
  - PostgREST (`rest`: port `3000`)
  - PostgreSQL Meta (`meta`: port `8080`)
  - Edge Runtime (`functions`: port `9000`)

### Verification in `docker-compose.yml`:
Ensure that internal services use `expose:` instead of `ports:`:
```yaml
# ✅ SECURE: accessible only to sibling containers on internal bridge network
services:
  db:
    expose:
      - 5432
  auth:
    expose:
      - 9999
  rest:
    expose:
      - 3000

# ⛔ INSECURE: Do not bind internal ports directly to host
# ports:
#   - "5432:5432"
```

---

## 3. 🔒 Lockdown Supabase Studio Dashboard

Currently, navigating to `https://api.itlabservice.com/` displays the basic auth prompt for Supabase Studio. You should hide it completely from public internet scans.

### Option A: Access via Secure SSH Tunnel (Recommended)
Remove the public domain routing for Studio entirely. When you need to access the database or dashboard, tunnel directly over encrypted SSH:
```bash
ssh -L 3000:localhost:3000 root@YOUR_VPS_IP
```
Then navigate to `http://localhost:3000` in your local browser. To the outside world, the dashboard port does not exist.

### Option B: IP Whitelisting in Dokploy / Traefik
If you prefer web dashboard access, configure Dokploy/Traefik middleware to allow traffic on the root path `/` **only from your personal/office IP address**:
```yaml
# Traefik IP Whitelist Middleware Example
ipWhiteList:
  sourceRange:
    - "YOUR_HOME_IP/32"
```
All unauthorized IP addresses will immediately receive `403 Forbidden`.

---

## 4. 🔑 Restrict API to "App-Only" Access

To prevent external scrapers, bots, and curl callers from interacting with `/rest/v1/*` or `/auth/v1/*`:

### Step 1: Add a Secret App Gateway Header
Configure Envoy or your reverse proxy to require an application token header (e.g. `X-App-Secret`) before forwarding traffic to PostgREST or GoTrue. If the header is missing or incorrect, Envoy drops the request with `403 Forbidden`.

### Step 2: Pass Header in Flutter App
Configure your Flutter client to attach the custom secret header automatically on all API calls:
```dart
await Supabase.initialize(
  url: AppConfig.supabaseUrl,
  publishableKey: AppConfig.supabaseAnonKey,
  headers: {
    'X-App-Secret': 'YOUR_CONFIGURED_GATEWAY_SECRET',
  },
);
```

---

## 5. ☁️ Cloudflare WAF, Bot Protection & Rate Limiting

Point your domain DNS (`api.itlabservice.com`) through **Cloudflare** with Proxy enabled (Orange Cloud):

1. **Origin IP Masking:** Cloudflare masks your VPS IP address; port scanners cannot attack your VPS directly.
2. **Bot Fight Mode:** Automatically drops traffic from automated attack toolkits, scrapers, and malicious botnets.
3. **Rate Limiting Rule on Auth:**
   - Path: `/auth/v1/signup*` and `/auth/v1/token*`
   - Limit: Max 10 requests per minute per IP.
   - Prevents bots from creating thousands of fake anonymous accounts or attempting brute-force attacks.
4. **WAF Rule (Require Mobile User-Agent / Custom Header):**
   - Block incoming requests that lack standard client headers.

---

## 6. 🧱 VPS Host Firewall (UFW)

Enforce strict host-level firewall rules on your VPS operating system:

```bash
# Set baseline firewall policy: drop incoming by default
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow only essential ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (for Let's Encrypt renewal)
sudo ufw allow 443/tcp   # HTTPS

# Enable firewall
sudo ufw enable
```

Check firewall status:
```bash
sudo ufw status verbose
```

---

## 7. 🗄️ PostgreSQL Row-Level Security (RLS)

PostgreSQL Row-Level Security is your final defense line. Even if an attacker extracts your public `ANON_KEY` by decompiling the client application, RLS guarantees that:
- Unauthenticated requests can read `0` rows.
- Authenticated requests can **only** read and write rows where `user_id = auth.uid()`.
- Users cannot access, view, or alter any other user's categories or expenses.

### Verification Queries:
Run in Supabase Studio SQL Editor to verify RLS is active:

```sql
-- Confirm RLS is enabled on all app tables
select tablename, rowsecurity 
from pg_tables 
where schemaname = 'public';

-- Confirm policies are enforced
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
from pg_policies 
where schemaname = 'public';
```
