# مفقودك — Mafqoodak (website + API)

PHP website and REST API for **Mafqoodak**, the lost-and-found platform for the Grand Mosque (Makkah) and the holy
sites. Visitors report lost and found items, sightings and missing people; the system suggests matches
automatically; administrators verify ownership and arrange handover or delivery.

This folder holds three things that share one set of business rules:

| Part | Path | Used by |
|---|---|---|
| Website (HTML pages + form handlers) | `*.php` in this folder | browsers |
| REST API v1 | `api/` | the mobile app (and any other client) |
| Shared business rules | `lib/services/`, `functions.php` | both of the above |

The project requirements, the overall architecture and the mobile app are described in the main
[`README.md`](../README.md).

- Live site: <https://mafquduk.dev/Project/> · Languages: Arabic, English, Turkish, Urdu (RTL/LTR)

## Features

**Visitors**
- Sign up, sign in with email and password, or with a 4-digit code sent to a Saudi phone number (`05XXXXXXXX`)
- Report a lost item, a found item or a sighting, with photo, date, nearest landmark or a point on the map
- Security question set by the finder, which the claimant must answer
- **Emergency report** for a missing child or elderly person (no account needed)
- Browse and search found items, see them on a map, open details and claim an item
- Suggested matches ("this is mine" / "not mine"), my reports, cancel a report with a reason
- Track a report by its number without signing in (`track_status.php`)
- Notifications, delivery (shipping) requests, profile, password change, language choice
- App download page with a QR code (`download.php`)

**Administrators** (`admin_dashboard.php`)
- Overview: totals, pending matches, claims under review, average review time, statistics by category and
  location, heat map
- Missing-person cases ("mark as found"), all reports with contact details, manual matching
- Ownership verification (security answers side by side, approve or reject with a reason), handover
- Shipping management (status, carrier, tracking number), approval of new administrator accounts

## Requirements

| | Minimum | Tested with |
|---|---|---|
| PHP | 8.1, extensions `mysqli`, `fileinfo`, `mbstring` | PHP 8.1 (XAMPP), PHP 8.3 (live server) |
| Database | MySQL 5.7+ or MariaDB 10.4+, `utf8mb4` | MariaDB 10.4 (XAMPP) |
| Web server | Apache with `mod_rewrite` and `AllowOverride All` (the API uses `api/.htaccess`) | Apache 2.4 |
| Browser | any current Chrome, Edge, Firefox or Safari (desktop or phone) | |

No Composer or npm packages are needed. Bootstrap 5.3 (RTL), Bootstrap Icons, Leaflet 1.9, QRCode.js and the
IBM Plex Sans Arabic font load from CDNs, so the browser needs internet access for styling, maps and the QR code.

## Running it locally (Windows + XAMPP 8.1)

1. Install **XAMPP 8.1** to `C:\xampp`.
2. Make this folder available at `http://localhost/Project/`. Either copy it to `C:\xampp\htdocs\Project`, or link
   it so there is only one copy of the code (run in an administrator command prompt):
   ```
   mklink /J C:\xampp\htdocs\Project "<path to>\final project\website"
   ```
3. Start Apache and MySQL from the XAMPP Control Panel.
4. Create the database: open <http://localhost/phpmyadmin>, create **`mafqoodak1`** (collation
   `utf8mb4_general_ci`), then import the files in `../database/` in order:
   `01_mafqoodak1_schema.sql` → `02_emergency_reports.sql` → `03_fix_users_phone_nullable.sql` →
   `04_complete_features.sql`
5. Check the connection settings in [`db.php`](db.php) (default `localhost:3306`, database `mafqoodak1`, user
   `root`, no password).
6. Create the first administrator (once; later admins sign up at `register_admin.php` and are approved from the
   dashboard):
   ```
   cd website
   C:\xampp\php\php.exe tools\create_admin.php "Full Name" admin@example.com "StrongPassword"
   ```
7. Optional: load realistic demo data (accounts, reports, matches, claims, deliveries). **This deletes all other
   data in the database:**
   ```
   C:\xampp\php\php.exe tools\demo_data.php --reset
   ```
8. Open <http://localhost/Project/index.php>. API health check: <http://localhost/Project/api/v1/health>.

## Configuration

| Setting | Where | Default |
|---|---|---|
| Database host, port, name, user, password | `db.php` | `localhost`, `3306`, `mafqoodak1`, `root`, empty |
| Debug messages (`APP_DEBUG`) | `db.php` | `true`; set to `false` on a public server |
| Time zone | `db.php` | `Asia/Riyadh` |
| Lowest score for a suggested match (`MATCH_THRESHOLD`) | `functions.php` | `60` out of 100 |
| Phone-code expiry / attempts (`OTP_TTL_SECONDS`, `OTP_MAX_ATTEMPTS`) | `lib/services/account_service.php` | 300 s / 5 |
| SMS provider for phone codes (`sms_send()`) | `lib/services/account_service.php` | none: the code is shown on screen |
| Option lists (categories, landmarks, cancel reasons…) | `config/lookups.php` | |
| App version shown on the download page (`$appVersion`) | `download.php` | |

Uploaded photos are saved in `assets/uploads/` (JPEG, PNG, WebP or GIF, up to 5 MB). On Linux this folder must
be writable by the web server user (for example `www-data`).

## Folder structure

```
website/
├─ index.php, items.php, item.php, map.php, ...   pages (HTML)
├─ process_*.php, *_action.php, manual_match.php   form handlers (POST → service → redirect)
├─ db.php                 database connection and APP_DEBUG
├─ auth.php               session helpers (signed-in user / admin checks)
├─ functions.php          shared helpers, image upload, automatic matching
├─ lib/
│  ├─ bootstrap.php       loads helpers, errors, messages and services
│  ├─ errors.php          UserError, AuthError, NotFoundError, ...
│  ├─ i18n.php            msg('key') in the current language
│  └─ services/           business rules shared by the website and the API:
│                         account, report, item, claim, shipping, notification, admin, lookup
├─ api/
│  ├─ index.php           entry point for /api/v1/... (CORS, errors → JSON)
│  ├─ .htaccess           sends every /api/ request to index.php, passes the Authorization header
│  ├─ core/               router, HTTP helpers, bearer-token auth
│  └─ routes/             account, reports, items, claims, shipping, notifications, admin
├─ config/lookups.php     option lists (stored and sent in Arabic)
├─ lang/{ar,en,tr,ur}.php server messages (website and API)
├─ assets/
│  ├─ css/style.css, js/app.js
│  ├─ i18n/{ar,en,tr,ur}.js  page texts (data-i18n keys); values.js translates option values
│  ├─ images/, uploads/
├─ partials/              shared head, navbar and footer
├─ download/            Android app (mafqoodak.apk, not in git) served by download.php
└─ tools/                 command-line only: create_admin.php, demo_data.php
```

## Main pages

| Page | Who | Purpose |
|---|---|---|
| `index.php` | everyone | home page, quick actions, app banner |
| `login.php`, `register.php`, `register_admin.php` | everyone | sign in (password or phone code), sign up, admin sign-up |
| `report_lost.php`, `report_found.php` | signed-in visitor | new lost / found / sighting report |
| `report_emergency.php` | everyone | missing child or elderly person |
| `items.php`, `item.php`, `map.php` | everyone | browse, details and claim, map of reports |
| `track_status.php` | everyone | track a report by its number |
| `user_dashboard.php` | signed-in visitor | my reports, suggested matches, my claims, cancel a report |
| `shipping_request.php` | signed-in visitor | delivery request for an approved claim |
| `notifications.php`, `profile.php` | signed-in visitor | notifications, profile and password |
| `admin_dashboard.php` | administrator | all admin tabs listed under Features |
| `download.php` | everyone | app download with QR code |

## How a request flows

```
Browser form ──► process_*.php ──┐
                                 ├──► lib/services/*.php ──► MySQL (mafqoodak1)
Mobile app ───► api/v1/... ──────┘
```

Pages and API routes contain no business rules of their own: both call the same service functions, so the website
and the app always behave the same way. Services throw typed errors (`UserError`, `AuthError`, …); the website
shows them as messages and the API turns them into HTTP status codes (`422`, `401`, …).

## Testing

With Apache and MySQL running (Python 3, standard library only), from the project root:
```
python tests/web_smoke_test.py      # website forms as visitor and admin (92 checks)
python tests/api_smoke_test.py      # whole API life cycle (52 checks)
```
The tests add their own accounts and reports. Afterwards, reset to the demo data with
`C:\xampp\php\php.exe website\tools\demo_data.php --reset`.

## Deploying to a Linux server

1. Upload this folder to the web root (the live server uses `/var/www/html/Project`, Apache + PHP 8.3).
2. Import the four SQL files and edit `db.php` on the server: real database user and password, `APP_DEBUG` set
   to `false`. When updating an existing server, don't overwrite its `db.php` or `assets/uploads/`.
3. Enable `mod_rewrite` and `AllowOverride All` for the folder, make `assets/uploads/` writable by `www-data`,
   and serve the site over https.
4. Check `/Project/index.php`, `/Project/api/v1/health` and `/Project/download.php`.
