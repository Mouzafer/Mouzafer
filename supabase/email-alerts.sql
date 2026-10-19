-- Human Resources WWW: email alerts for job requests, sent through Brevo.
--   * A worker gets an email when an employer sends (or re-sends) a job request.
--   * An employer gets an email when the worker accepts or declines it.
--
-- Before running this, store your Brevo API key once (SQL Editor, separate query):
--   select vault.create_secret('xkeysib-…your key…', 'brevo_api_key');
-- The key stays encrypted in Supabase; it is never in this file or on the website.
--
-- Then run this whole file in the SQL Editor. It is safe to run again.

create extension if not exists pg_net with schema extensions;

-- make user text safe inside an HTML email
create or replace function public.html_esc(t text) returns text
language sql immutable set search_path = public as
$$ select replace(replace(replace(replace(replace(coalesce(t,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),'''','&#39;') $$;

-- send one email through the Brevo API (in the background; never blocks or breaks the request)
create or replace function public.send_mail(to_email text, subject text, html text) returns void
language plpgsql security definer set search_path = public, extensions as
$$ declare k text;
begin
  select decrypted_secret into k from vault.decrypted_secrets where name = 'brevo_api_key' limit 1;
  if k is null or coalesce(to_email,'') = '' then return; end if;
  perform net.http_post(
    url := 'https://api.brevo.com/v3/smtp/email',
    headers := jsonb_build_object('api-key', k, 'content-type', 'application/json', 'accept', 'application/json'),
    body := jsonb_build_object(
      'sender', jsonb_build_object('name', 'Human Resources WWW', 'email', 'info@humanresourceswww.eu'),
      'to', jsonb_build_array(jsonb_build_object('email', to_email)),
      'subject', subject,
      'htmlContent', html));
exception when others then
  raise warning 'send_mail failed: %', sqlerrm;
end $$;

-- nobody may call send_mail from the website (it would let anyone send email)
revoke execute on function public.send_mail(text,text,text) from public, anon, authenticated;

create or replace function public.mail_page(title text, body text) returns text
language sql immutable set search_path = public as
$$ select '<div style="font-family:Arial,sans-serif;font-size:15px;line-height:1.5;color:#123B7A;max-width:560px">'
  || '<p style="font-size:18px;font-weight:bold;margin:0 0 12px">' || title || '</p>' || body
  || '<p style="margin:20px 0"><a href="https://humanresourceswww.com/" style="background:#1F7AE0;color:#fff;padding:10px 18px;border-radius:8px;text-decoration:none;font-weight:bold">Open Human Resources WWW</a></p>'
  || '<p style="font-size:12px;color:#667">You get this email because you have an account on humanresourceswww.com. '
  || 'Questions: info@humanresourceswww.eu</p></div>' $$;

create or replace function public.notify_request() returns trigger
language plpgsql security definer set search_path = public as
$$ declare
  d jsonb := new.data; e text; co text; prof text; num bigint; rows text; verb text;
begin
  -- to the worker: new request, or a re-send (at most one email per hour per request)
  if tg_op = 'INSERT' or (new.status = 'sent' and (old.status <> 'sent' or old.created_at < now() - interval '1 hour')) then
    select email into e from auth.users where id = new.worker_id;
    select company->>'name' into co from employers where id = new.employer_id;
    co := coalesce(nullif(co,''), 'An employer');
    rows := '<p style="margin:0 0 12px">' || html_esc(co) || ' would like to hire you. Log in to accept or decline.</p><table style="border-collapse:collapse">'
      || '<tr><td style="padding:3px 14px 3px 0;color:#667">Project</td><td>' || html_esc(d->>'project') || '</td></tr>'
      || '<tr><td style="padding:3px 14px 3px 0;color:#667">Where</td><td>' || html_esc(d->>'where') || '</td></tr>'
      || '<tr><td style="padding:3px 14px 3px 0;color:#667">Start</td><td>' || html_esc(d->>'start') || '</td></tr>'
      || '<tr><td style="padding:3px 14px 3px 0;color:#667">Duration</td><td>' || html_esc(d->>'duration') || '</td></tr>'
      || '<tr><td style="padding:3px 14px 3px 0;color:#667">Work mode</td><td>'
      || case d->>'mode' when 'remote' then 'Home office' when 'hybrid' then 'Hybrid' else 'On site' end
      || case when (d->>'training')::boolean then ', training on the job' else '' end || '</td></tr>'
      || case when coalesce(d->>'msg','') <> '' then '<tr><td style="padding:3px 14px 3px 0;color:#667;vertical-align:top">Message</td><td>' || html_esc(d->>'msg') || '</td></tr>' else '' end
      || '</table>';
    perform send_mail(e, 'New job request from ' || left(co, 80), mail_page('You have a new job request', rows));

  -- to the employer: the worker answered
  elsif tg_op = 'UPDATE' and old.status = 'sent' and new.status in ('accepted','declined') then
    select email into e from auth.users where id = new.employer_id;
    select data->>'prof', w.num into prof, num from workers w where w.id = new.worker_id;
    verb := case new.status when 'accepted' then 'accepted' else 'declined' end;
    rows := '<p style="margin:0 0 12px">Worker no. ' || num || ' (' || html_esc(coalesce(prof,'worker')) || ') has <b>' || verb
      || '</b> your job request for "' || html_esc(d->>'project') || '".</p>'
      || case when new.status = 'accepted' then '<p style="margin:0 0 12px">Log in and open Requests to see their contact details and agree the next steps.</p>'
              else '<p style="margin:0 0 12px">You can search the map for other people with the same skills.</p>' end;
    perform send_mail(e, 'Your job request was ' || verb, mail_page('Job request ' || verb, rows));
  end if;
  return null;
exception when others then
  raise warning 'notify_request failed: %', sqlerrm;
  return null;
end $$;

revoke execute on function public.notify_request() from public, anon, authenticated;

drop trigger if exists notify_request on public.requests;
create trigger notify_request after insert or update on public.requests
  for each row execute function public.notify_request();
