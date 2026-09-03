# Asterra Fleur — Netlify + Supabase setup

## 1. Supabase
Open your Supabase project → SQL Editor → New query.
Run the complete `supabase_setup.sql` file once.

This creates/repairs:
- `products`
- `deleted_products`
- public `product-images` Storage bucket
- Storage policies
- database RLS policies

## 2. Netlify
Deploy the project root as usual.

This version already contains the correct Supabase project URL and browser-safe publishable key.
If environment variables are required, set the same variables already used by the app in Netlify:
- VITE_SUPABASE_URL
- VITE_SUPABASE_ANON_KEY

## 3. Test
Admin → upload an image → wait for success → refresh.
The image should remain because the file is stored in Supabase Storage and its metadata is stored in Supabase.

## Important
The SQL must be run in the same Supabase project whose URL/key the website uses.


## Important fix in this version
The database uses `storage_path` consistently with the website. Existing `image_path` values are copied to `storage_path`. Uploads are saved in Supabase Storage first and their database row is saved permanently; refreshes load the rows again from Supabase. Delete removes both the Storage file and the database record.


Security: do not add any `sb_secret_...` or `service_role` key to the website. If one was exposed, rotate it in Supabase Dashboard.


## Admin credentials
- Username: `varshuzz`
- Password: `varshu@1234`
- Supabase Auth email: `VarshaNarendrakumar68@gmail.com`

The password must be created/reset for this email in Supabase Authentication → Users.
