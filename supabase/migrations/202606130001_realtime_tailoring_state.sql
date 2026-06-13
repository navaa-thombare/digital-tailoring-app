begin;

create table if not exists public.tailoring_app_state (
  shop_id uuid primary key references public.shops (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  revision bigint not null default 0 check (revision >= 0),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

alter table public.tailoring_app_state enable row level security;

create policy tailoring_state_read_members on public.tailoring_app_state
for select to authenticated
using (public.is_active_shop_member(shop_id));

create policy tailoring_state_manage_operations on public.tailoring_app_state
for all to authenticated
using (
  public.has_shop_role(
    shop_id,
    array['owner', 'manager', 'accountant']::public.shop_member_role[]
  )
)
with check (
  public.has_shop_role(
    shop_id,
    array['owner', 'manager', 'accountant']::public.shop_member_role[]
  )
);

grant select, insert, update on public.tailoring_app_state to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'tailoring_app_state'
  ) then
    alter publication supabase_realtime add table public.tailoring_app_state;
  end if;
end;
$$;

commit;
