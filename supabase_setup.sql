-- ============================================================
-- ASTERRA FLEUR - COMPLETE SUPABASE SETUP
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1. PRODUCTS TABLE
-- ============================================================

create table if not exists public.products (
    id uuid primary key default gen_random_uuid(),
    code text,
    name text,
    category text,
    image_url text,
    image_path text,
    storage_path text,
    created_at timestamptz not null default now()
);

alter table public.products
add column if not exists code text;

alter table public.products
add column if not exists name text;

alter table public.products
add column if not exists category text;

alter table public.products
add column if not exists image_url text;

alter table public.products
add column if not exists image_path text;

alter table public.products
add column if not exists storage_path text;

alter table public.products
add column if not exists created_at timestamptz
not null default now();

-- Fix old image path data
update public.products
set storage_path = image_path
where storage_path is null
and image_path is not null;

update public.products
set image_path = storage_path
where image_path is null
and storage_path is not null;


-- ============================================================
-- 2. DELETED PRODUCTS TABLE
-- ============================================================

create table if not exists public.deleted_products (
    id uuid primary key default gen_random_uuid(),
    original_id uuid,
    code text,
    name text,
    category text,
    image_url text,
    image_path text,
    storage_path text,
    deleted_at timestamptz not null default now()
);

alter table public.deleted_products
add column if not exists original_id uuid;

alter table public.deleted_products
add column if not exists code text;

alter table public.deleted_products
add column if not exists name text;

alter table public.deleted_products
add column if not exists category text;

alter table public.deleted_products
add column if not exists image_url text;

alter table public.deleted_products
add column if not exists image_path text;

alter table public.deleted_products
add column if not exists storage_path text;

alter table public.deleted_products
add column if not exists deleted_at timestamptz
not null default now();


-- ============================================================
-- 3. UNIQUE PRODUCT CODES
-- ============================================================

create unique index if not exists products_code_unique_idx
on public.products(code)
where code is not null;

-- Rebuild the archive-code index safely. Older versions of this project
-- could contain duplicate deleted codes, which would make the unique index
-- creation fail and later cause ON CONFLICT errors.
drop index if exists public.deleted_products_code_unique_idx;

with ranked as (
    select
        ctid,
        row_number() over (partition by code order by deleted_at desc, ctid desc) as rn
    from public.deleted_products
    where code is not null
)
delete from public.deleted_products d
using ranked r
where d.ctid = r.ctid
  and r.rn > 1;

create unique index deleted_products_code_unique_idx
on public.deleted_products(code)
where code is not null;


-- ============================================================
-- 4. PRODUCT CODE GENERATOR
-- ============================================================

create or replace function public.next_product_code(
    p_category text
)
returns text
language plpgsql
security definer
set search_path = public
as $$

declare
    v_prefix text;
    v_num integer;

begin

    -- ADMIN EMAIL
    if lower(coalesce(auth.jwt() ->> 'email', ''))
       <> lower('VarshaNarendrakumar68@gmail.com') then

        raise exception 'Not authorized';

    end if;


    -- CATEGORY PREFIX
    v_prefix :=
        case p_category

            when 'artificial_bokeh'
                then 'AB'

            when 'chocolate_bokeh'
                then 'CB'

            when 'gift_collection'
                then 'GC'

            else null

        end;


    if v_prefix is null then
        raise exception 'Invalid category';
    end if;


    -- FIND NEXT NUMBER
    select greatest(

        case v_prefix

            when 'AB' then 16
            when 'CB' then 17
            when 'GC' then 7
            else 0

        end,

        coalesce(

            (
                select max(
                    (substring(code from 3))::integer
                )

                from public.products

                where code ~ (
                    '^' || v_prefix || '[0-9]+$'
                )
            ),

            0
        ),

        coalesce(

            (
                select max(
                    (substring(code from 3))::integer
                )

                from public.deleted_products

                where code ~ (
                    '^' || v_prefix || '[0-9]+$'
                )
            ),

            0
        )

    ) + 1

    into v_num;


    return v_prefix ||
           lpad(v_num::text, 3, '0');

end;

$$;


grant execute
on function public.next_product_code(text)
to authenticated;


-- ============================================================
-- 5. ENABLE RLS
-- ============================================================

alter table public.products
enable row level security;

alter table public.deleted_products
enable row level security;


-- ============================================================
-- 6. PRODUCTS POLICIES
-- ============================================================

drop policy if exists "products_select_public"
on public.products;

create policy "products_select_public"

on public.products

for select

to anon, authenticated

using (true);


drop policy if exists "products_insert_admin"
on public.products;

create policy "products_insert_admin"

on public.products

for insert

to authenticated

with check (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


drop policy if exists "products_update_admin"
on public.products;

create policy "products_update_admin"

on public.products

for update

to authenticated

using (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

)

with check (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


drop policy if exists "products_delete_admin"
on public.products;

create policy "products_delete_admin"

on public.products

for delete

to authenticated

using (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


-- ============================================================
-- 7. DELETED PRODUCTS POLICIES
-- ============================================================

drop policy if exists "deleted_products_select_public"
on public.deleted_products;

create policy "deleted_products_select_public"

on public.deleted_products

for select

to anon, authenticated

using (true);


drop policy if exists "deleted_products_insert_admin"
on public.deleted_products;

create policy "deleted_products_insert_admin"

on public.deleted_products

for insert

to authenticated

with check (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


drop policy if exists "deleted_products_update_admin"
on public.deleted_products;

create policy "deleted_products_update_admin"

on public.deleted_products

for update

to authenticated

using (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

)

with check (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


drop policy if exists "deleted_products_delete_admin"
on public.deleted_products;

create policy "deleted_products_delete_admin"

on public.deleted_products

for delete

to authenticated

using (

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


-- ============================================================
-- 8. SITE SETTINGS (THEME + ADMIN USERNAME)
-- ============================================================

create table if not exists public.site_settings (
    key text primary key,
    value text not null,
    updated_at timestamptz not null default now()
);

insert into public.site_settings(key,value) values
    ('username','varshuzz'),
    ('primary','#482061'),
    ('accent','#8d5bc2'),
    ('background','#faf7fc'),
    ('surface','#ffffff')
on conflict (key) do nothing;

alter table public.site_settings enable row level security;

drop policy if exists "site_settings_select_public" on public.site_settings;
create policy "site_settings_select_public" on public.site_settings
for select to anon, authenticated using (true);

drop policy if exists "site_settings_insert_admin" on public.site_settings;
create policy "site_settings_insert_admin" on public.site_settings
for insert to authenticated
with check (lower(coalesce(auth.jwt() ->> 'email','')) = lower('VarshaNarendrakumar68@gmail.com'));

drop policy if exists "site_settings_update_admin" on public.site_settings;
create policy "site_settings_update_admin" on public.site_settings
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = lower('VarshaNarendrakumar68@gmail.com'))
with check (lower(coalesce(auth.jwt() ->> 'email','')) = lower('VarshaNarendrakumar68@gmail.com'));

-- ============================================================
-- 9. STORAGE BUCKET
-- ============================================================

insert into storage.buckets (
    id,
    name,
    public
)

values (
    'product-images',
    'product-images',
    true
)

on conflict (id)

do update set
    public = true;


-- ============================================================
-- 10. STORAGE - PUBLIC READ
-- ============================================================

drop policy if exists "product_images_select_public"
on storage.objects;

create policy "product_images_select_public"

on storage.objects

for select

to anon, authenticated

using (
    bucket_id = 'product-images'
);


-- ============================================================
-- 11. STORAGE - ADMIN UPLOAD
-- ============================================================

drop policy if exists "product_images_insert_admin"
on storage.objects;

create policy "product_images_insert_admin"

on storage.objects

for insert

to authenticated

with check (

    bucket_id = 'product-images'

    and

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


-- ============================================================
-- 12. STORAGE - ADMIN UPDATE
-- ============================================================

drop policy if exists "product_images_update_admin"
on storage.objects;

create policy "product_images_update_admin"

on storage.objects

for update

to authenticated

using (

    bucket_id = 'product-images'

    and

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

)

with check (

    bucket_id = 'product-images'

    and

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


-- ============================================================
-- 13. STORAGE - ADMIN DELETE
-- ============================================================

drop policy if exists "product_images_delete_admin"
on storage.objects;

create policy "product_images_delete_admin"

on storage.objects

for delete

to authenticated

using (

    bucket_id = 'product-images'

    and

    lower(coalesce(auth.jwt() ->> 'email', ''))
    =
    lower('VarshaNarendrakumar68@gmail.com')

);


-- ============================================================
-- DONE
-- ============================================================
