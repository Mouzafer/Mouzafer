-- Human Resources WWW: public list of partner companies.
-- Shows only companies that (1) ticked "Show our company as a partner" and (2) are approved by an admin.
-- Visitors get the company name, country and website, nothing else. Run once in the SQL Editor; safe to run again.
create or replace function public.partners()
returns table(name text, country text, web text)
language sql stable security definer set search_path = public as
$$ select company->>'name', coalesce(company->>'country',''), coalesce(company->>'web','')
   from employers
   where approved and (company->>'partner')::boolean is true and coalesce(company->>'name','') <> ''
   order by lower(company->>'name') $$;
grant execute on function public.partners() to anon, authenticated;
