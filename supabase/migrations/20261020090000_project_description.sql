-- Business Ledger on Supabase Postgres — projects.description.
--
-- The app's project form has an optional description (≤ 300 characters in
-- the form), which the Firestore model stored and 3/7 left out. Without
-- this column a project upsert from the app fails (PostgREST rejects an
-- unknown column), so creating or editing a project would never sync.
-- Client-writable like the other project columns (the table grant covers
-- every column; RLS is unchanged).

alter table public.projects
  add column if not exists description text not null default ''
    check (length(description) <= 500);
