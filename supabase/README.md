# Supabase Backend

The migrations in `migrations/` create the production data boundary for
Digital Tailoring:

- one shop per owner account
- one active shop membership per worker, with multiple roles in that shop
- customers, templates, measurements, orders, assignments, payments and shop
  settings scoped by `shop_id`
- Row Level Security policies based on the authenticated user's active shop
  membership and roles
- an owner-only `clear_my_shop_data` function for the destructive reset in
  Shop Settings

## Apply The Migration

Use the Supabase SQL Editor to run the migration file, or link the Supabase CLI
to the project and run:

```powershell
supabase db push
```

Before using production authentication, enable Phone Auth in Supabase and
configure an SMS provider. Worker creation must create or invite an Auth user
first; the owner can then insert that user's active membership and selected
roles.

## Policy Boundary

Owners and managers manage shop setup, templates and assignments.
Accountants can manage customers, orders and payments. Cutters can maintain
measurements, and cutters/makers can update order item work state. Any further
assignment-only restrictions should be added as policies before exposing the
worker workflow in production.
