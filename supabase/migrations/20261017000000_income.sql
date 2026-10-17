-- Income and Income Sources (ADR 0006), mirroring categories and expenses.
--
-- Same per-user keys as 20261016000000_per_user_keys.sql from the start:
-- every install seeds the same preset ids ('src_salary', ...), so ids only
-- need to be unique within one account.
--
-- Safe to run more than once.

-- Income Sources: where money comes from. Never shared with categories.
create table if not exists public.income_sources (
  id          text not null,
  user_id     uuid not null references auth.users (id) on delete cascade default auth.uid(),
  name        text not null,
  icon        text not null,
  color       bigint not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint income_sources_pkey primary key (user_id, id)
);

-- Income: amount + Income Source + paid-on date.
create table if not exists public.income (
  id           text not null,
  user_id      uuid not null references auth.users (id) on delete cascade default auth.uid(),
  amount_minor bigint not null check (amount_minor > 0),
  source_id    text not null,
  paid_on      date not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  constraint income_pkey primary key (user_id, id),
  constraint income_source_fkey foreign key (user_id, source_id)
    references public.income_sources (user_id, id)
);

create index if not exists income_user_paid_on_idx on public.income (user_id, paid_on desc);

alter table public.income_sources enable row level security;
alter table public.income         enable row level security;

drop policy if exists "own income sources" on public.income_sources;
create policy "own income sources" on public.income_sources
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own income" on public.income;
create policy "own income" on public.income
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Make the REST API (PostgREST) pick up the new tables immediately.
notify pgrst, 'reload schema';
