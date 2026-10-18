-- Human Resources WWW: database tables and access rules for Supabase.
-- Run this once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- It is safe to run again: it drops and recreates the policies and functions.
--
-- Who sees what
--   Everyone, also without an account: the public part of each worker profile
--     (profession, skills, town, availability). No name, no contact details.
--   Approved employers and admins: also the private part (name, email, phone,
--     work history, certificate numbers).
--   Each person: their own data. Job requests: only the employer and worker involved.
--   Reports: only admins.

create extension if not exists pgcrypto;

-- ---------- tables
create table if not exists public.accounts (
  id uuid primary key references auth.users on delete cascade,
  role text not null check (role in ('worker','employer')),
  created_at timestamptz not null default now()
);

create table if not exists public.admins (
  user_id uuid primary key references auth.users on delete cascade
);

create table if not exists public.employers (
  id uuid primary key references auth.users on delete cascade,
  company jsonb not null default '{}'::jsonb,   -- name, vat, person, email, addr, country
  state jsonb not null default '{}'::jsonb,     -- projects, shortlist, active project (private)
  approved boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.workers (
  id uuid primary key references auth.users on delete cascade,
  num bigint generated always as identity unique,
  data jsonb not null,                          -- public profile: no name or contact details
  verify_status text not null default 'none' check (verify_status in ('none','wait','ok','declined')),
  verify_from timestamptz,
  verify_until date,
  suspended boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint workers_data_size check (pg_column_size(data) < 200000)
);

create table if not exists public.worker_private (
  id uuid primary key references public.workers on delete cascade,
  data jsonb not null,                          -- name, email, phone, history, certificate numbers
  constraint worker_private_size check (pg_column_size(data) < 200000)
);

create table if not exists public.requests (
  id uuid primary key default gen_random_uuid(),
  employer_id uuid not null references public.employers on delete cascade,
  worker_id uuid not null references public.workers on delete cascade,
  data jsonb not null,                          -- company, project, where, start, duration, msg
  status text not null default 'sent' check (status in ('sent','accepted','declined')),
  created_at timestamptz not null default now(),
  unique (employer_id, worker_id),
  constraint requests_data_size check (pg_column_size(data) < 20000)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  employer_id uuid not null references public.employers on delete cascade,
  worker_id uuid not null references public.workers on delete cascade,
  stars int not null check (stars between 1 and 5),
  text text check (length(text) <= 1000),
  company text check (length(company) <= 200),
  created_at timestamptz not null default now(),
  unique (employer_id, worker_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter uuid not null default auth.uid() references auth.users on delete cascade,
  worker_id uuid not null references public.workers on delete cascade,
  reason text not null check (length(reason) <= 200),
  text text check (length(text) <= 2000),
  created_at timestamptz not null default now()
);

-- ---------- helper functions (run with the owner's rights so policies can use them)
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from admins where user_id = auth.uid()) $$;

create or replace function public.is_approved_employer() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from employers where id = auth.uid() and approved) $$;

create or replace function public.can_see_private() returns boolean
language sql stable security definer set search_path = public as
$$ select public.is_admin() or public.is_approved_employer() $$;

-- A person deletes their own account and, through the cascades, all their data.
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as
$$ begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  delete from auth.users where id = auth.uid();
end $$;

-- ---------- guards on columns only an admin may change
create or replace function public.guard_employer() returns trigger
language plpgsql security definer set search_path = public as
$$ begin
  if not public.is_admin() then
    if tg_op = 'INSERT' then new.approved := false;
    elsif new.approved is distinct from old.approved then
      raise exception 'only an admin can approve employers';
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

create or replace function public.guard_worker() returns trigger
language plpgsql security definer set search_path = public as
$$ begin
  if not public.is_admin() then
    if tg_op = 'INSERT' then
      new.suspended := false; new.verify_until := null;
      if new.verify_status not in ('none','wait') then new.verify_status := 'none'; end if;
    else
      if new.suspended is distinct from old.suspended then raise exception 'only an admin can suspend profiles'; end if;
      if new.verify_until is distinct from old.verify_until then raise exception 'only an admin can verify profiles'; end if;
      -- a worker may only ask for verification (or withdraw the request)
      if new.verify_status is distinct from old.verify_status
         and not (new.verify_status in ('wait','none') and old.verify_status in ('none','declined','wait','ok')) then
        raise exception 'only an admin can verify profiles';
      end if;
      if new.verify_status = 'wait' and old.verify_status <> 'wait' then new.verify_from := now(); end if;
      if new.verify_status is distinct from old.verify_status and new.verify_status <> 'ok' then new.verify_until := null; end if;
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

create or replace function public.guard_request() returns trigger
language plpgsql security definer set search_path = public as
$$ begin
  if public.is_admin() then return new; end if;
  if auth.uid() = old.worker_id then
    -- the worker answers: only the status changes, and only from 'sent'
    if new.data is distinct from old.data or new.employer_id <> old.employer_id or new.worker_id <> old.worker_id
       or old.status <> 'sent' or new.status not in ('accepted','declined') then
      raise exception 'a worker can only accept or decline a new request';
    end if;
  elsif auth.uid() = old.employer_id then
    -- the employer may resend: new details, status back to 'sent'
    if new.employer_id <> old.employer_id or new.worker_id <> old.worker_id or new.status <> 'sent' then
      raise exception 'an employer can only resend a request';
    end if;
    new.created_at := now();
  else
    raise exception 'not allowed';
  end if;
  return new;
end $$;

drop trigger if exists guard_employer on public.employers;
create trigger guard_employer before insert or update on public.employers for each row execute function public.guard_employer();
drop trigger if exists guard_worker on public.workers;
create trigger guard_worker before insert or update on public.workers for each row execute function public.guard_worker();
drop trigger if exists guard_request on public.requests;
create trigger guard_request before update on public.requests for each row execute function public.guard_request();

-- ---------- row level security
alter table public.accounts enable row level security;
alter table public.admins enable row level security;
alter table public.employers enable row level security;
alter table public.workers enable row level security;
alter table public.worker_private enable row level security;
alter table public.requests enable row level security;
alter table public.reviews enable row level security;
alter table public.reports enable row level security;

do $$ declare r record; begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public'
    and tablename in ('accounts','admins','employers','workers','worker_private','requests','reviews','reports')
  loop execute format('drop policy %I on public.%I', r.policyname, r.tablename); end loop;
end $$;

-- accounts: each person manages their own; admins read all
create policy accounts_read on public.accounts for select using (id = auth.uid() or public.is_admin());
create policy accounts_insert on public.accounts for insert with check (id = auth.uid());
create policy accounts_update on public.accounts for update using (id = auth.uid()) with check (id = auth.uid());
create policy accounts_delete on public.accounts for delete using (id = auth.uid());

-- admins: nobody reads or writes through the API (add admins in the SQL editor)

-- employers: own row; admins read and approve all
create policy employers_read on public.employers for select using (id = auth.uid() or public.is_admin());
create policy employers_insert on public.employers for insert with check (id = auth.uid());
create policy employers_update on public.employers for update using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());
create policy employers_delete on public.employers for delete using (id = auth.uid());

-- workers (public part): everyone reads profiles that are not suspended
create policy workers_read on public.workers for select using (not suspended or id = auth.uid() or public.is_admin());
create policy workers_insert on public.workers for insert with check (id = auth.uid());
create policy workers_update on public.workers for update using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());
create policy workers_delete on public.workers for delete using (id = auth.uid());

-- worker_private: the worker, approved employers and admins
create policy wpriv_read on public.worker_private for select using (id = auth.uid() or public.can_see_private());
create policy wpriv_insert on public.worker_private for insert with check (id = auth.uid());
create policy wpriv_update on public.worker_private for update using (id = auth.uid()) with check (id = auth.uid());
create policy wpriv_delete on public.worker_private for delete using (id = auth.uid());

-- requests: the two people involved; only approved employers send
create policy requests_read on public.requests for select using (employer_id = auth.uid() or worker_id = auth.uid() or public.is_admin());
create policy requests_insert on public.requests for insert with check (employer_id = auth.uid() and public.is_approved_employer() and status = 'sent');
create policy requests_update on public.requests for update using (employer_id = auth.uid() or worker_id = auth.uid() or public.is_admin());
create policy requests_delete on public.requests for delete using (employer_id = auth.uid() or public.is_admin());

-- reviews: everyone reads; an employer reviews a worker who accepted their request
create policy reviews_read on public.reviews for select using (true);
create policy reviews_insert on public.reviews for insert with check (
  employer_id = auth.uid() and exists (
    select 1 from public.requests r where r.employer_id = auth.uid() and r.worker_id = reviews.worker_id and r.status = 'accepted'));
create policy reviews_delete on public.reviews for delete using (employer_id = auth.uid() or public.is_admin());

-- reports: any signed-in person sends one; only admins read and close them
create policy reports_insert on public.reports for insert with check (auth.uid() is not null and reporter = auth.uid());
create policy reports_read on public.reports for select using (public.is_admin() or reporter = auth.uid());
create policy reports_delete on public.reports for delete using (public.is_admin());

-- ---------- API access
grant usage on schema public to anon, authenticated;
grant select on public.workers, public.reviews to anon;
grant select, insert, update, delete on public.accounts, public.employers, public.workers, public.worker_private,
  public.requests, public.reviews, public.reports to authenticated;
revoke all on public.admins from anon, authenticated;
grant execute on function public.is_admin(), public.is_approved_employer(), public.can_see_private() to anon, authenticated;
grant execute on function public.delete_my_account() to authenticated;
revoke execute on function public.delete_my_account() from anon, public;
