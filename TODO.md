# To do later

Updated on 19 Oct 2026. Ask Claude in this project to continue with any of these.

## Still to do

1. **Test the job-request emails** – a test company (approved by admin) sends a job request to a
   test worker; the worker should get "New job request from …" within a minute (check spam), and
   the company gets "Your job request was accepted" after the worker accepts.
   If nothing arrives, run in Supabase SQL Editor and send Claude the result:
   `select status_code, content from net._http_response order by created desc limit 5;`
2. **Google Search Console** – check that Sitemaps shows "Erfolgreich" (1–3 days after 19 Oct),
   then share the link in trade groups (Facebook, LinkedIn, WhatsApp).
3. **CAPTCHA on sign-up** (Cloudflare Turnstile) against fake accounts.
4. **Supabase Pro** (about $25/month): daily backups, no pausing. Decided: stay on Free for now.
   Upgrade at about 50–100 real registrations, before advertising the site, or when it earns money.
   Until then: open the site at least once a week so the free project is not paused.

Smaller items:
- Brevo -> SMTP & API -> API Keys: keep only one "website alerts" key (delete an older one).
- Brevo API key "website alerts" stops working after 90 days without use. If alerts stop: make a new
  key (Restricted, Transactional email = All) and store it in Supabase SQL Editor:
  `select vault.update_secret((select id from vault.secrets where name='brevo_api_key'), 'NEW-KEY');`
  Do not save the key anywhere else.
- Cancel the two unneeded Stellar Web Hosting plans at Namecheap.
- Namecheap Private Email trial ends 18 Nov 2026, then renews yearly (mailbox for reading mail).
- Before charging money: move hosting from GitHub Pages to a host that allows commercial use
  (e.g. Cloudflare Pages). Same files, same address; only the DNS records in Namecheap change.
- Advertising and income (plan together with the hosting move): sponsor banners or "featured" spots
  sold directly to industry companies (first: about two training centres; later workwear/safety shops,
  agencies, crew travel). No Google ads, no tracking, so no cookie banner needed. Privacy notice and
  terms already mention sponsor ads. Later options: paid employer plans, featured job posts, paid verification.
- Around 1,000–2,000 workers: change the map to load only the people in the visible area / search
  from the database (today every visitor downloads all public profiles). Ask Claude to do this.
- Visitor statistics: Cloudflare Web Analytics (free, no cookies) – send Claude the site token.
- Have a lawyer/accountant check the privacy notice and whether a licence is needed before charging money.

## Done

- 19 Oct 2026: Google Search Console – domain verified (TXT record), sitemap submitted, indexing requested.
- 19 Oct 2026: Brevo domain humanresourceswww.eu "Authenticated" and "Branded".
- 19 Oct 2026: all four GitHub A records (185.199.108–111.153) set for humanresourceswww.com.
- 19 Oct 2026: job-request email alerts switched on (supabase/email-alerts.sql, Brevo key in Supabase Vault).
- 19 Oct 2026: B2B option for workers, Contact us page and footer, privacy notice (no home
  addresses, all service providers, data in Ireland/EU, sponsor ads).
