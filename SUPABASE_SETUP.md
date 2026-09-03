# Asterra Fleur — Supabase shared upload setup

This version moves admin uploads/deletes from browser-only storage to Supabase so the same Netlify URL shows the same catalogue to everyone.

## 1. Create the admin login

In Supabase Dashboard:

1. Open **Authentication → Users**.
2. Create a user manually.
3. Email: `VarshaNarendrakumar68@gmail.com`
4. Password: `varshu@1234`
5. Keep email confirmation disabled if your project asks for confirmation.

The website login screen uses username **varshuzz** and this password. The email is the internal Supabase Auth identity.

## 2. Create the database/storage setup

Open **SQL Editor → New query**, paste all of `supabase_setup.sql`, and click **Run**.

This creates:
- `products` table
- `deleted_products` table
- `product-images` storage bucket
- public read policies
- authenticated admin write/delete policies
- automatic AB/CB/GC product-code generator

## 3. Netlify

Upload the `09` folder as the Netlify site. The correct Supabase project URL and publishable key are already wired into `index.html`.

## Important

The publishable/anon key is designed for browser use, but the database/storage policies are what protect writes. Never put a Supabase **service_role/secret key** into the website.


## Important fix in this version
The database uses `storage_path` consistently with the website. Existing `image_path` values are copied to `storage_path`. Uploads are saved in Supabase Storage first and their database row is saved permanently; refreshes load the rows again from Supabase. Delete removes both the Storage file and the database record.


## 4. Important security note

Only the Supabase **publishable** key is included in the browser code. The `sb_secret_...` / `service_role` key must NEVER be placed in `index.html`, Netlify environment variables exposed to client-side code, or any browser JavaScript.

If a secret/service-role key has been exposed publicly, rotate/revoke it in Supabase Dashboard before production use. Never add it to this project.

## 5. Persistence fix

New uploads receive codes after the built-in catalogue (AB017+, CB042+, GC008+). The code generator also considers previously deleted codes, so an upload cannot accidentally collide with a built-in or deleted product.

The upload sequence is:
Browser → Supabase Auth session → Supabase Storage upload → `products` row → public catalogue reload.

On refresh, the page reads `products` from Supabase and builds the image URL from the saved `storage_path`; it does not depend on browser localStorage.


## Important before deploying
- Admin username: `varshuzz`
- Admin password: `varshu@1234`
- Admin email: `VarshaNarendrakumar68@gmail.com`
- The password must be set/reset for this email in Supabase Authentication → Users. It is not stored in this HTML file.
- The browser must use only the publishable key. Never add a `sb_secret_...` or service-role key.
- Make sure the publishable key belongs to the same Supabase project `rirrgnbtarsdjnnynhqt`; a key from another project will not work with this URL.


### Admin settings
The admin panel now stores the admin username and theme colors in `site_settings`. Password changes use Supabase Auth (`auth.updateUser`) and are never stored in the database. Run the complete `supabase_setup.sql` after the update.


### Delete error fix
If an older database reports `there is no unique or exclusion constraint matching the ON CONFLICT specification`, run this SQL file from the beginning. The setup now safely rebuilds the `deleted_products.code` unique index and removes duplicate archived codes first. The website delete flow also no longer depends on `ON CONFLICT`; it removes any old archive row and inserts the deleted code cleanly.
