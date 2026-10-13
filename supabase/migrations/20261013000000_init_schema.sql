-- Categories: user-owned classification labels.
create table if not exists public.categories (
  id          uuid primary key,
  user_id     uuid not null references auth.users (id) on delete cascade default auth.uid(),
  name        text not null,
  icon        text not null,
  color       integer not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- Expenses: amount + category + date (ADR 0002).
create table if not exists public.expenses (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade default auth.uid(),
  amount_minor bigint not null check (amount_minor > 0),
  category_id  uuid not null references public.categories (id),
  spent_on     date not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

create index if not exists expenses_user_spent_on_idx on public.expenses (user_id, spent_on desc);

alter table public.categories enable row level security;
alter table public.expenses   enable row level security;

create policy "own categories" on public.categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own expenses" on public.expenses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
