-- Per-user keys so every account can own the same local ids.
--
-- Each install seeds the same default categories ('cat_food', 'cat_transport',
-- ...). With a global primary key on `id`, a second account syncing its
-- 'cat_food' collides with the first account's row:
--   duplicate key value violates unique constraint "categories_pkey" (23505)
-- Keys are now (user_id, id): ids only need to be unique within one account.
--
-- Safe to run more than once. Run it all in one go (Supabase Studio → SQL
-- Editor → paste → Run).

-- 1. Remove every foreign key from expenses → categories (old or new name),
--    so the categories primary key can be replaced.
alter table public.expenses drop constraint if exists expenses_category_id_fkey;
alter table public.expenses drop constraint if exists expenses_category_fkey;

-- 2. Categories: primary key becomes (user_id, id).
alter table public.categories drop constraint if exists categories_pkey cascade;
alter table public.categories add constraint categories_pkey primary key (user_id, id);

-- 3. Expenses: primary key becomes (user_id, id).
alter table public.expenses drop constraint if exists expenses_pkey cascade;
alter table public.expenses add constraint expenses_pkey primary key (user_id, id);

-- 4. Re-link expenses to their category within the same account.
alter table public.expenses
  add constraint expenses_category_fkey
  foreign key (user_id, category_id)
  references public.categories (user_id, id);

-- 5. Make the REST API (PostgREST) pick up the new keys immediately.
notify pgrst, 'reload schema';

-- Check: both lines below should end in "PRIMARY KEY (user_id, id)".
select conrelid::regclass as "table", conname, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid in ('public.categories'::regclass, 'public.expenses'::regclass)
  and contype in ('p', 'u', 'f');
