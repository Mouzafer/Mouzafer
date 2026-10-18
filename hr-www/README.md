# Human Resources WWW

A map-based hiring site for construction, energy and wind-turbine technicians.
Workers register for free with their skills, certificates and availability.
Employers search the map by trade, skill, distance and availability, and send job requests.

Live test version (private, shared by invitation):
https://claude.ai/artifact/3sxvUoTYuiuwK9nAgNK26i

## How it runs

`index.html` is a single file. It is published as a claude.ai page, which provides:

- **Sign-in** through the visitor's claude.ai account (no separate password).
- **A shared database** for worker profiles, job requests, reviews, reports and admin decisions.

Opened outside claude.ai, the page still shows the map with example profiles, but nobody can sign in or save.

## Accounts

| Account  | Who                         | Can do |
|----------|-----------------------------|--------|
| Worker   | Anyone invited who chooses "I'm looking for work" | Create a profile, set availability, accept or decline job requests, order verification |
| Employer | Anyone invited who chooses "I'm hiring" | Company details, plans, projects, shortlist, job requests, reviews, reports |
| Admin    | The page owner              | Verification queue, reports, suspending profiles, "View as" any account type |

Testers need **Contributor** access (Share menu) to register and save.

## Database layout

| Path | Contents | Who writes |
|------|----------|------------|
| `accounts/<id>` | Account type | The person themselves |
| `workers/<id>` | Worker profile | The worker themselves |
| `requests/<employer>-<worker>` | Job request and its answer | Employer and worker |
| `reviews/<auto>` | Reviews after a job | Employers |
| `reports/<id>` | Reports about profiles | The reporter; only the admin reads them |
| `admin/state` | Verifications and suspensions | Admin only |
| `data/users/<id>/app` | Employer's company, projects, shortlist, plan | Private to that person |

## Before a public launch

- Move worker contact details behind a server so the paywall cannot be bypassed.
- Real payments for employer plans and worker verification.
- Email and password sign-up for people without a claude.ai account.
- Translations (Greek, Bulgarian, Turkish) and a full place search for any town.
