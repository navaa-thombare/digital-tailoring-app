begin;

create extension if not exists pgcrypto;

create type public.shop_member_role as enum (
  'owner',
  'manager',
  'accountant',
  'cutter',
  'maker'
);

create type public.order_status as enum (
  'measurements',
  'in_stitching',
  'ready',
  'delivered',
  'hold',
  'cancelled'
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  mobile text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null unique references auth.users (id),
  name text not null,
  owner_name text not null,
  mobile text not null,
  address text not null default '',
  max_orders_per_day integer not null default 12 check (max_orders_per_day > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shop_memberships (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  roles public.shop_member_role[] not null
    check (cardinality(roles) > 0),
  speciality text,
  is_active boolean not null default true,
  deactivated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (shop_id, user_id)
);

create unique index shop_memberships_one_active_shop_per_user
  on public.shop_memberships (user_id)
  where is_active;

create index shop_memberships_active_shop_idx
  on public.shop_memberships (shop_id, is_active);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  name text not null,
  mobile text not null,
  address text not null default '',
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (shop_id, mobile)
);

create table public.garment_templates (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  name text not null,
  customer_rate integer not null default 0 check (customer_rate >= 0),
  maker_rate integer not null default 0 check (maker_rate >= 0),
  measurement_fields jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (shop_id, name)
);

create table public.customer_measurements (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  customer_id uuid not null references public.customers (id) on delete cascade,
  template_id uuid not null references public.garment_templates (id) on delete cascade,
  values jsonb not null default '{}'::jsonb,
  measured_at timestamptz not null default now(),
  measured_by uuid references public.profiles (id),
  unique (customer_id, template_id)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  order_number text not null,
  customer_id uuid not null references public.customers (id),
  order_date timestamptz not null default now(),
  due_date date not null,
  status public.order_status not null default 'measurements',
  payment_mode text,
  total_amount integer not null default 0 check (total_amount >= 0),
  paid_amount integer not null default 0 check (paid_amount >= 0),
  notes text not null default '',
  is_priority boolean not null default false,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (shop_id, order_number),
  check (paid_amount <= total_amount)
);

create index orders_shop_due_date_idx on public.orders (shop_id, due_date);
create index orders_shop_status_idx on public.orders (shop_id, status);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete cascade,
  template_id uuid references public.garment_templates (id),
  template_name text not null,
  quantity integer not null check (quantity > 0),
  customer_rate integer not null default 0 check (customer_rate >= 0),
  maker_rate integer not null default 0 check (maker_rate >= 0),
  status public.order_status not null default 'measurements',
  measurement_snapshot jsonb not null default '{}'::jsonb,
  measurement_updated_at timestamptz,
  created_at timestamptz not null default now()
);

create index order_items_order_idx on public.order_items (order_id);

create table public.order_item_assignments (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  order_item_id uuid not null references public.order_items (id) on delete cascade,
  unit_number integer not null check (unit_number >= 0),
  worker_user_id uuid not null references public.profiles (id),
  assigned_by uuid not null references public.profiles (id),
  worker_payment_status text,
  assigned_at timestamptz not null default now(),
  unique (order_item_id, unit_number)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete cascade,
  amount integer not null check (amount > 0),
  payment_mode text not null,
  paid_at timestamptz not null default now(),
  received_by uuid not null references public.profiles (id),
  note text
);

create table public.worker_payments (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  worker_user_id uuid not null references public.profiles (id),
  amount integer not null check (amount > 0),
  paid_at timestamptz not null default now(),
  paid_by uuid not null references public.profiles (id),
  note text
);

create table public.shop_settings (
  shop_id uuid primary key references public.shops (id) on delete cascade,
  print_customer_copy boolean not null default true,
  print_shop_use_copy boolean not null default true,
  print_on_assignment boolean not null default false,
  message_on_order_ready boolean not null default false,
  message_on_in_stitching boolean not null default false,
  message_on_order_delivery boolean not null default false,
  whatsapp_message_template text not null default '',
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger shops_set_updated_at before update on public.shops
for each row execute function public.set_updated_at();
create trigger memberships_set_updated_at before update on public.shop_memberships
for each row execute function public.set_updated_at();
create trigger customers_set_updated_at before update on public.customers
for each row execute function public.set_updated_at();
create trigger templates_set_updated_at before update on public.garment_templates
for each row execute function public.set_updated_at();
create trigger orders_set_updated_at before update on public.orders
for each row execute function public.set_updated_at();
create trigger shop_settings_set_updated_at before update on public.shop_settings
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, mobile)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.phone, new.raw_user_meta_data ->> 'mobile')
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    mobile = excluded.mobile,
    updated_at = now();
  return new;
end;
$$;

create trigger auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_active_shop_member(p_shop_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.shop_memberships membership
    where membership.shop_id = p_shop_id
      and membership.user_id = (select auth.uid())
      and membership.is_active
  );
$$;

create or replace function public.has_shop_role(
  p_shop_id uuid,
  p_roles public.shop_member_role[]
)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.shop_memberships membership
    where membership.shop_id = p_shop_id
      and membership.user_id = (select auth.uid())
      and membership.is_active
      and membership.roles && p_roles
  );
$$;

create or replace function public.shares_active_shop(p_user_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.shop_memberships mine
    inner join public.shop_memberships colleague
      on colleague.shop_id = mine.shop_id
     and colleague.is_active
    where mine.user_id = (select auth.uid())
      and mine.is_active
      and colleague.user_id = p_user_id
  );
$$;

create or replace function public.create_my_shop(
  p_name text,
  p_owner_name text,
  p_mobile text,
  p_address text default '',
  p_max_orders_per_day integer default 12
)
returns public.shops
language plpgsql
security definer set search_path = public
as $$
declare
  created_shop public.shops;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required.';
  end if;
  if exists (select 1 from public.shops where owner_user_id = (select auth.uid())) then
    raise exception 'An owner may create only one shop.';
  end if;
  if exists (
    select 1 from public.shop_memberships
    where user_id = (select auth.uid()) and is_active
  ) then
    raise exception 'This user is already active in another shop.';
  end if;

  update public.profiles
     set full_name = p_owner_name, mobile = p_mobile
   where id = (select auth.uid());

  insert into public.shops (
    owner_user_id, name, owner_name, mobile, address, max_orders_per_day
  )
  values (
    (select auth.uid()), p_name, p_owner_name, p_mobile, p_address,
    p_max_orders_per_day
  )
  returning * into created_shop;

  insert into public.shop_memberships (shop_id, user_id, roles)
  values (
    created_shop.id,
    (select auth.uid()),
    array['owner']::public.shop_member_role[]
  );

  insert into public.shop_settings (shop_id) values (created_shop.id);

  return created_shop;
end;
$$;

alter table public.profiles enable row level security;
alter table public.shops enable row level security;
alter table public.shop_memberships enable row level security;
alter table public.customers enable row level security;
alter table public.garment_templates enable row level security;
alter table public.customer_measurements enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_item_assignments enable row level security;
alter table public.payments enable row level security;
alter table public.worker_payments enable row level security;
alter table public.shop_settings enable row level security;

create policy profiles_read_shop_colleagues on public.profiles
for select to authenticated
using (id = (select auth.uid()) or public.shares_active_shop(id));
create policy profiles_update_self on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy shops_read_members on public.shops
for select to authenticated
using (public.is_active_shop_member(id));
create policy shops_update_management on public.shops
for update to authenticated
using (public.has_shop_role(id, array['owner', 'manager']::public.shop_member_role[]))
with check (public.has_shop_role(id, array['owner', 'manager']::public.shop_member_role[]));

create policy memberships_read_shop on public.shop_memberships
for select to authenticated
using (user_id = (select auth.uid()) or public.is_active_shop_member(shop_id));
create policy memberships_insert_owner on public.shop_memberships
for insert to authenticated
with check (public.has_shop_role(shop_id, array['owner']::public.shop_member_role[]));
create policy memberships_update_owner on public.shop_memberships
for update to authenticated
using (public.has_shop_role(shop_id, array['owner']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner']::public.shop_member_role[]));

create policy customers_read_members on public.customers
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy customers_manage_operations on public.customers
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]));

create policy templates_read_members on public.garment_templates
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy templates_manage_management on public.garment_templates
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager']::public.shop_member_role[]));

create policy measurements_read_members on public.customer_measurements
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy measurements_manage_operations on public.customer_measurements
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'cutter']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager', 'cutter']::public.shop_member_role[]));

create policy orders_read_members on public.orders
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy orders_manage_operations on public.orders
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]));

create policy order_items_read_members on public.order_items
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy order_items_manage_operations on public.order_items
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'cutter', 'maker']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager', 'cutter', 'maker']::public.shop_member_role[]));

create policy assignments_read_members on public.order_item_assignments
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy assignments_manage_management on public.order_item_assignments
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager']::public.shop_member_role[]));

create policy payments_read_management on public.payments
for select to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]));
create policy payments_manage_finance on public.payments
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]));

create policy worker_payments_read_management on public.worker_payments
for select to authenticated
using (
  worker_user_id = (select auth.uid())
  or public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[])
);
create policy worker_payments_manage_finance on public.worker_payments
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager', 'accountant']::public.shop_member_role[]));

create policy settings_read_members on public.shop_settings
for select to authenticated using (public.is_active_shop_member(shop_id));
create policy settings_manage_management on public.shop_settings
for all to authenticated
using (public.has_shop_role(shop_id, array['owner', 'manager']::public.shop_member_role[]))
with check (public.has_shop_role(shop_id, array['owner', 'manager']::public.shop_member_role[]));

grant select, update on public.profiles to authenticated;
grant select, update on public.shops to authenticated;
grant select, insert, update on public.shop_memberships to authenticated;
grant select, insert, update, delete on public.customers to authenticated;
grant select, insert, update, delete on public.garment_templates to authenticated;
grant select, insert, update, delete on public.customer_measurements to authenticated;
grant select, insert, update, delete on public.orders to authenticated;
grant select, insert, update, delete on public.order_items to authenticated;
grant select, insert, update, delete on public.order_item_assignments to authenticated;
grant select, insert, update, delete on public.payments to authenticated;
grant select, insert, update, delete on public.worker_payments to authenticated;
grant select, insert, update on public.shop_settings to authenticated;

revoke all on function public.create_my_shop(text, text, text, text, integer) from public;
grant execute on function public.create_my_shop(text, text, text, text, integer) to authenticated;
revoke all on function public.is_active_shop_member(uuid) from public;
grant execute on function public.is_active_shop_member(uuid) to authenticated;
revoke all on function public.has_shop_role(uuid, public.shop_member_role[]) from public;
grant execute on function public.has_shop_role(uuid, public.shop_member_role[]) to authenticated;
revoke all on function public.shares_active_shop(uuid) from public;
grant execute on function public.shares_active_shop(uuid) to authenticated;

commit;
