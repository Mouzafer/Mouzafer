# Going live

The public website is in `site/`. Accounts and data are handled by [Supabase](https://supabase.com)
(free plan). The site is hosted free on GitHub Pages at **https://humanresourceswww.com/**.

## 1. Create the database (Supabase, about 5 minutes)

1. Sign up at supabase.com and create a **new project**. Choose a region in the EU (for example Frankfurt)
   and save the database password somewhere safe.
2. Open **SQL Editor -> New query**, paste all of `supabase/schema.sql`, and press **Run**.
3. Open **Authentication -> URL Configuration**:
   - Site URL: `https://humanresourceswww.com/`
   - Redirect URLs: add `https://humanresourceswww.com/` and `https://www.humanresourceswww.com/`
4. Open **Project Settings -> API** and copy the **Project URL** and the **anon public** key.

## 2. Emails (confirmation and password reset)

Supabase sends its emails through **Brevo** (free plan, 300 emails per day), from `info@humanresourceswww.eu`.

- Brevo: sender `info@humanresourceswww.eu` verified; SMTP key named "Supabase" (Brevo -> SMTP & API).
- Supabase -> Authentication -> Emails -> SMTP Settings: host `smtp-relay.brevo.com`, port `587`,
  username = the Brevo SMTP login (`...@smtp-brevo.com`), password = the Brevo SMTP key.
- Supabase -> Authentication -> Sign In / Providers -> Email: **Confirm email** is on.
- The mailbox itself (reading mail) is Namecheap Private Email: https://privateemail.com

If emails stop: check Supabase -> Logs -> Auth for the error, and the Brevo dashboard for blocked or bounced messages.
Never put the SMTP key or any password into this repository.

## 3. Settings file

Fill in `site/config.js`:
- `supabaseUrl` and `supabaseAnonKey` from step 1.4
- `operator`: your name or company, postal address and contact email. The Privacy notice shows them;
  EU law requires this.

## 4. Turn on the website (GitHub and Namecheap)

1. GitHub repository: **Settings -> Pages -> Build and deployment -> Source: GitHub Actions**.
2. Same page, **Custom domain**: `humanresourceswww.com` -> **Save**.
3. Namecheap -> Domain List -> humanresourceswww.com -> **Manage**:
   - **Nameservers**: Namecheap BasicDNS or PremiumDNS (not the hosting nameservers).
   - **Advanced DNS**: delete the parking records, then add
     | Type | Host | Value |
     |------|------|-------|
     | A | @ | 185.199.108.153 |
     | A | @ | 185.199.109.153 |
     | A | @ | 185.199.110.153 |
     | A | @ | 185.199.111.153 |
     | CNAME | www | mouzafer.github.io. |
4. humanresourceswww.eu -> **Advanced DNS** -> add a **URL Redirect Record**: host `@`, value
   `https://humanresourceswww.com`, type Permanent (301). Leave any email (MX) records as they are.
5. After DNS works (minutes to a few hours), tick **Enforce HTTPS** on the GitHub Pages page.
Every change to `site/` is then published automatically. To publish now: **Actions -> Publish website -> Run workflow**.

## 5. Make yourself admin

1. Open the website and create an account with your own email.
2. In Supabase **SQL Editor**, run (with your email):
   ```sql
   insert into admins select id from auth.users where email = 'you@example.com';
   ```
3. Reload the website. You now see **Verification queue**, **Employers** and **Reports**.

## 6. Job-request email alerts

Workers get an email when an employer sends them a job request; employers get one when it is
accepted or declined. Sent through the Brevo API.

1. Brevo -> Settings (gear) -> **SMTP & API** -> **API Keys** tab -> **Generate a new API key**,
   name it `website alerts`, copy the key (it starts with `xkeysib-`; it is shown only once).
2. Supabase -> **SQL Editor** -> New query, paste and run (with your key between the quotes):
   `select vault.create_secret('xkeysib-…', 'brevo_api_key');`
   Never put this key on the website or in GitHub.
3. New query -> paste all of `supabase/email-alerts.sql` -> **Run**.
4. If emails do not arrive: Brevo -> Settings -> **Security** -> **Authorized IPs** must allow the
   request (Brevo emails you about a blocked IP), and in Supabase you can run
   `select status_code, content from net._http_response order by created desc limit 5;`

## Day-to-day

- **Employers** register free and appear under **Employers**. Approve real companies only:
  approved employers see every worker's name, contact details, CV and certificates.
- **Verification**: workers ask for it in My area; check their certificates and approve or decline.
- **Reports**: employers report wrong profiles; you can suspend them.
- The free Supabase plan pauses a project after a week with no visits. It wakes up again from the
  Supabase dashboard. Upgrade when the site is busy.

## Not built yet

- Card payments for employers or verification.
- Certificate file uploads (only the file name is kept).
