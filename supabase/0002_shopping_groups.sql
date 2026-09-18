-- Adds "shopping groups" (a named shopping trip, e.g. "Súper del sábado")
-- so several items can be checked off / added to inventory with one tap.
-- Safe to run once in the Supabase SQL Editor.

create table if not exists checkme_shopping_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

alter table checkme_shopping_items
  add column if not exists group_id uuid references checkme_shopping_groups(id) on delete set null;

-- Same no-login model as the other checkme_* tables: RLS scoped to the
-- anon key, nothing else in this database is touched.
alter table checkme_shopping_groups enable row level security;

drop policy if exists checkme_shopping_groups_anon_access on checkme_shopping_groups;
create policy checkme_shopping_groups_anon_access
  on checkme_shopping_groups
  for all
  to anon, authenticated
  using (true)
  with check (true);
