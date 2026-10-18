# Human Resources WWW

A map-based hiring site for construction, energy and wind-turbine technicians.
Workers register free with their skills, certificates and availability.
Employers search the map by trade, skill, distance and availability, and send job requests.

| Folder | What it is |
|--------|------------|
| `site/` | The public website (one page + `config.js`). Published to GitHub Pages at https://humanresourceswww.com. |
| `supabase/schema.sql` | Database tables and access rules for Supabase. |
| `hr-www/` | The earlier test version that runs as a claude.ai page for invited testers. |
| `SETUP.md` | How to go live, step by step. |

## Who sees what

- **Everyone**, without an account: dots on the map and the public part of each worker profile
  (profession, skills, town, availability). No names or contact details.
- **Workers**: their own profile, job requests sent to them, verification status.
- **Employers**: free during launch. After an admin approves the company they see full profiles
  (name, contact details, CV, certificates) and can send job requests and leave reviews.
- **Admins**: verification queue, employer approvals, reports and suspensions.

These rules are enforced by the database (row level security), not only by the page.
