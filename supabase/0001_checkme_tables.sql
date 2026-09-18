-- CheckMe tables for a shared Supabase project.
-- Table names are prefixed with "checkme_" so they can't collide with
-- anything already in this database. Safe to run once in the Supabase
-- SQL Editor (Project -> SQL Editor -> New query -> paste -> Run).

create extension if not exists pgcrypto;

create table if not exists checkme_inventory_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  quantity integer not null default 0 check (quantity >= 0),
  category text not null default 'otros' check (category in ('comida', 'limpieza', 'higiene', 'otros')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists checkme_shopping_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  quantity integer not null default 1 check (quantity >= 1),
  category text not null default 'otros' check (category in ('comida', 'limpieza', 'higiene', 'otros')),
  checked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at current on every row update.
create or replace function checkme_set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists checkme_inventory_items_set_updated_at on checkme_inventory_items;
create trigger checkme_inventory_items_set_updated_at
  before update on checkme_inventory_items
  for each row execute function checkme_set_updated_at();

drop trigger if exists checkme_shopping_items_set_updated_at on checkme_shopping_items;
create trigger checkme_shopping_items_set_updated_at
  before update on checkme_shopping_items
  for each row execute function checkme_set_updated_at();

-- The app has no login: every request uses the public "anon" key, so
-- access control lives entirely in these two policies. They only ever
-- touch checkme_* tables -- nothing else in this database is exposed.
alter table checkme_inventory_items enable row level security;
alter table checkme_shopping_items enable row level security;

drop policy if exists checkme_inventory_items_anon_access on checkme_inventory_items;
create policy checkme_inventory_items_anon_access
  on checkme_inventory_items
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists checkme_shopping_items_anon_access on checkme_shopping_items;
create policy checkme_shopping_items_anon_access
  on checkme_shopping_items
  for all
  to anon, authenticated
  using (true)
  with check (true);
