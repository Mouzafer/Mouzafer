# Going live

The public website is in `site/`. Accounts and data are handled by [Supabase](https://supabase.com)
(free plan). The site is hosted free on GitHub Pages at **https://mouzafer.github.io/Mouzafer/**.

## 1. Create the database (Supabase, about 5 minutes)

1. Sign up at supabase.com and create a **new project**. Choose a region in the EU (for example Frankfurt)
   and save the database password somewhere safe.
2. Open **SQL Editor -> New query**, paste all of `supabase/schema.sql`, and press **Run**.
3. Open **Authentication -> URL Configuration**:
   - Site URL: `https://mouzafer.github.io/Mouzafer/`
   - Redirect URLs: add `https://mouzafer.github.io/Mouzafer/`
4. Open **Project Settings -> API** and copy the **Project URL** and the **anon public** key.

## 2. Emails (confirmation and password reset)

Supabase's built-in email only reaches the addresses of your own Supabase team and sends very few
messages per hour, so real users would not get their confirmation emails.
Connect an email service under **Authentication -> Emails -> SMTP Settings**, for example
Resend or Brevo (both have free plans; they ask you to confirm a domain or sender address).

Until that is done you can turn off **Authentication -> Sign In / Providers -> Email -> Confirm email**
so people can register without an email. Password reset still needs the email service.

## 3. Settings file

Fill in `site/config.js`:
- `supabaseUrl` and `supabaseAnonKey` from step 1.4
- `operator`: your name or company, postal address and contact email. The Privacy notice shows them;
  EU law requires this.

## 4. Turn on the website (GitHub, 1 minute)

In the GitHub repository: **Settings -> Pages -> Build and deployment -> Source: GitHub Actions**.
Every change to `site/` is then published automatically. To publish now: **Actions -> Publish website -> Run workflow**.

## 5. Make yourself admin

1. Open the website and create an account with your own email.
2. In Supabase **SQL Editor**, run (with your email):
   ```sql
   insert into admins select id from auth.users where email = 'you@example.com';
   ```
3. Reload the website. You now see **Verification queue**, **Employers** and **Reports**.

## Day-to-day

- **Employers** register free and appear under **Employers**. Approve real companies only:
  approved employers see every worker's name, contact details, CV and certificates.
- **Verification**: workers ask for it in My area; check their certificates and approve or decline.
- **Reports**: employers report wrong profiles; you can suspend them.
- The free Supabase plan pauses a project after a week with no visits. It wakes up again from the
  Supabase dashboard. Upgrade when the site is busy.

## Not built yet

- Email notifications (for example when a worker gets a job request). Workers see requests when they log in.
- Card payments for employers or verification.
- Certificate file uploads (only the file name is kept).
- Translations.
