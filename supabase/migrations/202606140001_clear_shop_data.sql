begin;

create or replace function public.clear_my_shop_data()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  target_shop_id uuid;
begin
  select shops.id
    into target_shop_id
    from public.shops
   where shops.owner_user_id = (select auth.uid());

  if target_shop_id is null then
    raise exception 'Only a shop owner can clear shop data.';
  end if;

  delete from public.tailoring_app_state
   where shop_id = target_shop_id;
  delete from public.worker_payments
   where shop_id = target_shop_id;
  delete from public.payments
   where shop_id = target_shop_id;
  delete from public.order_item_assignments
   where shop_id = target_shop_id;
  delete from public.order_items
   where shop_id = target_shop_id;
  delete from public.orders
   where shop_id = target_shop_id;
  delete from public.customer_measurements
   where shop_id = target_shop_id;
  delete from public.customers
   where shop_id = target_shop_id;
  delete from public.garment_templates
   where shop_id = target_shop_id;
  delete from public.shop_memberships
   where shop_id = target_shop_id
     and user_id <> (select auth.uid());

  update public.shop_settings
     set print_customer_copy = true,
         print_shop_use_copy = true,
         print_on_assignment = false,
         message_on_order_ready = false,
         message_on_in_stitching = false,
         message_on_order_delivery = false,
         whatsapp_message_template = '',
         updated_at = now()
   where shop_id = target_shop_id;
end;
$$;

revoke all on function public.clear_my_shop_data() from public;
grant execute on function public.clear_my_shop_data() to authenticated;

commit;
