# مفقودك — Mafqoodak

Lost-and-found platform for the Grand Mosque (Makkah) and the holy sites: visitors report lost and found items,
sightings and missing people; the system suggests matches automatically; administrators verify ownership and
arrange handover or delivery. **One project:** a website, a mobile app, a REST API and one MySQL database.

This file covers the whole project: the requirements, how the parts fit together and how to run everything.
Each part also has its own README:

| README | Covers |
|---|---|
| [`website/README.md`](website/README.md) | Website + REST API: requirements, local setup, configuration, structure, deployment |
| [`mobile_app/README.md`](mobile_app/README.md) | Flutter app: requirements, choosing the server, running, building APK / iOS |

## Project layout

| Folder | What it is |
|---|---|
| `website/` | PHP website + `api/` (REST API for the app) + `lib/` (shared business rules) + `lang/` & `assets/i18n/` (texts) + `config/lookups.php` (option lists) |
| `mobile_app/` | Flutter app (Android / iOS / web), same features as the website |
| `database/` | SQL setup files; import them in number order |
| `tests/` | Automated end-to-end tests (API and website) |

---

# Part A — Project requirements

## A1. Problem and goal

Millions of visitors come to the Grand Mosque and the holy sites every year, and items are lost and found every
day; children and elderly people also get separated from their families. Reports are scattered between lost-and-
found offices, security staff and word of mouth, so owners and finders rarely meet.

**Goal:** one platform, on the web and on phones, where anyone can report what they lost or found in their own
language, the system links matching reports automatically, and administrators return items to their verified
owners safely.

## A2. Users and roles

| Role | Can do |
|---|---|
| **Guest** (no account) | browse found items and the map, track a report by its number, file an emergency report, download the app |
| **Visitor** (signed in) | everything a guest can, plus file reports, claim items, confirm matches, request delivery, receive notifications, manage the profile |
| **Administrator** | dashboard: statistics, emergencies, all reports, manual matching, ownership verification, handover, shipping, approval of new administrators |
| **Pending administrator** | has signed up as an administrator; cannot sign in until an existing administrator approves the account |

## A3. Functional requirements

Every requirement is available on **both** the website and the mobile app, except FR-23 (website only).

| ID | Requirement |
|---|---|
| **Accounts** | |
| FR-01 | A visitor can create an account with full name, email and password (at least 8 characters). |
| FR-02 | A visitor can sign in with email and password, or with a 4-digit code sent to the Saudi mobile number (`05XXXXXXXX`) saved in their profile. |
| FR-03 | A visitor can edit the profile (name, phone, nationality), change the password and choose the language (Arabic, English, Turkish, Urdu). |
| FR-04 | A person can sign up as an administrator; the account stays pending until an existing administrator approves it. The first administrator is created from the command line. |
| **Reports** | |
| FR-05 | A visitor can report a **lost item**: category, description, date, place (landmark list or a point on the map) and an optional photo. |
| FR-06 | A visitor can report a **found item** the same way, say where the item is now, and add a private **security question** with its answer. |
| FR-07 | A visitor can report a **sighting** (saw the item but did not take it). |
| FR-08 | Anyone, with or without an account, can file an **emergency report** for a missing child or elderly person; administrators see active cases first. |
| FR-09 | A visitor can describe an item **by voice** (speech-to-text dictation); the app also has a voice-first lost report with large text. |
| FR-10 | A visitor can see their reports with status and **cancel** one with a reason. |
| FR-11 | Anyone can **track** a report by its number without signing in (searching → matched → ready → delivered / cancelled). |
| **Finding and matching** | |
| FR-12 | Anyone can browse and search found items, filter them, open details with photos, and see reports on a **map**. |
| FR-13 | The system **compares new reports automatically** and suggests matches with a score from 0 to 100 (see A4). |
| FR-14 | The owner of a lost report confirms a suggested match ("this is mine") or rejects it ("not mine"). |
| FR-15 | An administrator can **match** a lost report to a found item **manually**. |
| **Claims and return** | |
| FR-16 | A visitor can **claim** a found item; if the finder set a security question, the claimant must answer it. |
| FR-17 | An administrator reviews the claim with both answers side by side and **approves or rejects** it (with a reason). |
| FR-18 | An administrator marks an approved item as **handed over**. |
| FR-19 | The owner of an approved claim can request **delivery (shipping)**; administrators update its status, carrier and tracking number. |
| **Notifications and administration** | |
| FR-20 | Visitors receive **notifications** for new matches, claim decisions and delivery updates. |
| FR-21 | Administrators see an **overview**: totals, pending matches, claims under review, average review time, statistics by category and place, and a heat map. |
| FR-22 | Administrators see all reports with the reporter's contact details, and mark missing-person cases as found. |
| FR-23 | The website offers the Android app for download, with its size, date, a QR code and install steps. |

## A4. Business rules

- **Automatic matching** runs whenever a lost or found report is saved. A lost and a found report of the same
  category get a score out of 100: 20 for the category, up to 20 for the place (same landmark, or within 0.5 km;
  10 within 2 km), up to 50 for shared words in the descriptions, and up to 10 for the dates (10 within 3 days, 5
  within 14 days). Pairs scoring **60 or more** are suggested. Suggestions continue until the owner confirms one.
- **Statuses:** lost item `searching → matched → ready → delivered` (or `cancelled`); found item
  `received → matched → ready → delivered`; claim `Under Review → Approved → Delivered` (or `Rejected`); shipping
  `pending → approved → shipped → delivered` (or `rejected`); emergency `active → found`.
- **Phone-code sign-in:** the code is valid for 5 minutes and allows 5 attempts. Until an SMS provider is connected,
  the code is shown on screen (development mode).
- **Photos:** JPEG, PNG, WebP or GIF, up to 5 MB.
- Delivered and cancelled reports are hidden from public browsing; their details stay reachable by link.
- Option lists (categories, landmarks, cancel reasons) are stored in Arabic and translated on screen.

## A5. Non-functional requirements

| Area | Requirement and how it is met |
|---|---|
| **Languages and accessibility** | Arabic, English, Turkish and Urdu for every text on the website, in the app and in server messages; right-to-left and left-to-right layouts; voice reporting; no text written inside program code (all in language files). |
| **Consistency** | The website and the app use the same business rules (`website/lib/services/`) and the same database, so they always behave the same way. The app uses the website's colours and font (IBM Plex Sans Arabic). |
| **Security** | Passwords and phone codes stored as hashes (`password_hash`); database queries with bound parameters; app access with bearer tokens valid 30 days; role checks on every admin page and API route; uploaded files checked by their real type and size; https on the live server. |
| **Portability** | Website works in any current browser on desktop or phone; the app runs on Android (one APK for arm, arm64 and x86_64, including Huawei phones without Google services), iOS 15+, the web and Windows. |
| **Configurability** | The app's server address can be changed inside the app without rebuilding; database settings and debug mode are in one file (`website/db.php`). |
| **Maintainability** | Layered code (pages / API → services → database; in the app: features → data → core); versioned REST API (`website/api`). |
| **Testability** | Automated end-to-end tests: 52 API checks and 92 website checks; static analysis of the app (`flutter analyze`). |
| **Usability** | Guests can report emergencies and track reports without an account; the map and landmark list make places easy to pick. |

## A6. Software and hardware requirements

| To… | You need |
|---|---|
| Run the server | PHP 8.1+ (`mysqli`, `fileinfo`, `mbstring`), MySQL 5.7+ / MariaDB 10.4+, Apache with `mod_rewrite`. On Windows: **XAMPP 8.1**. |
| Use the website | Any current browser, internet access (styles, maps and the QR code load from CDNs). |
| Use the app | Android phone (any recent version), or iPhone with iOS 15+. |
| Develop or build the app | Flutter stable (Dart SDK `^3.13.5`), Android Studio with an emulator or a phone; a Mac with Xcode for iOS builds (or the GitHub iOS workflow). |
| Run the tests | Python 3 (standard library only). |

## A7. Technology

| Part | Technology |
|---|---|
| Mobile app | Flutter (Dart 3), Material 3, `http`, `shared_preferences`, `image_picker`, `flutter_map` (OpenStreetMap), `speech_to_text` |
| Website | PHP 8.1, Bootstrap 5 (RTL), Leaflet maps, vanilla JavaScript |
| API | PHP 8.1, own router, JSON, bearer tokens |
| Database | MariaDB 10.4 (MySQL compatible), 16 tables |
| Server | XAMPP 8.1 (Apache) locally; Apache + PHP 8.3 on the live server (https://mafquduk.dev) |
| Tests | Python 3 end-to-end scripts, `flutter analyze` |

## A8. Architecture

```
 Mobile app ─┐
             ├──►  API (website/api)  ─┐
 Website ────┘                         ├──►  shared business rules  ──►  Database (MySQL)
                                       │      (website/lib/services)
```

---

# Part B — How to run

**Quick start:** set up the server (B1), then open the website, or run the app against it (B2). To try the app
without a local server, download it from https://mafquduk.dev/Project/download.php: it connects to the live server.

## B1. Server and website (Windows + XAMPP 8.1)

1. Install **XAMPP 8.1** (Apache + MariaDB + PHP 8.1) to `C:\xampp`.
2. Make the website available at `http://localhost/Project/`. Either copy `website\` to `C:\xampp\htdocs\Project`,
   or link it (keeps one copy of the code):
   ```
   mklink /J C:\xampp\htdocs\Project "<path to>\final project\website"
   ```
3. Start Apache and MySQL (XAMPP Control Panel).
4. Create the database: open <http://localhost/phpmyadmin>, create **`mafqoodak1`** (collation `utf8mb4_general_ci`),
   then import, in order:
   `database/01_mafqoodak1_schema.sql` → `02_emergency_reports.sql` → `03_fix_users_phone_nullable.sql` → `04_complete_features.sql`
5. Database connection settings: `website/db.php` (default `localhost:3306`, user `root`, no password).
6. **Create the first administrator** (once; later admins sign up and are approved from the dashboard):
   ```
   cd website
   C:\xampp\php\php.exe tools\create_admin.php "Full Name" admin@example.com "StrongPassword"
   ```
7. Optional demo data (deletes everything else in the database):
   `C:\xampp\php\php.exe tools\demo_data.php --reset`
8. Open <http://localhost/Project/index.php>. API health check: <http://localhost/Project/api/v1/health>.

More detail (configuration, folder structure, deploying to a Linux server): [`website/README.md`](website/README.md).

## B2. Mobile app

Requirements: Flutter (stable), Android Studio with an emulator or a phone.

```
cd mobile_app
flutter pub get
flutter run                     # live server → https://mafquduk.dev/Project/api/v1/
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/Project/api/v1/       # emulator + local XAMPP
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost/Project/api/v1/   # browser + local XAMPP
flutter run --dart-define=API_BASE_URL=http://192.168.1.20/Project/api/v1/   # real phone + XAMPP on the same Wi-Fi
```
For a real phone on a local server, use the computer's local IP address and allow Apache through the Windows firewall.
The server can also be changed inside the app: long-press the logo on the login screen (a domain gets https, a
local IP gets http; "Reset" returns to the live server).

Release APK (one file for all phones: arm64, 32-bit arm and x86_64; works on Huawei phones without Google services):
```
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
```

iOS (bundle ID `com.mafqoodak.mafqoodak`, iOS 15+). iOS can only be built on a Mac:
```
flutter build ios --release      # on a Mac with Xcode; then archive in Xcode for TestFlight / App Store
```
Without a Mac, push to GitHub and run the **iOS build** workflow (`.github/workflows/ios-build.yml`). It builds an
unsigned `mafqoodak-unsigned.ipa` (under the run's Artifacts) that Sideloadly or AltStore can install with a free
Apple ID. Camera, photo, microphone and speech permission texts are in `mobile_app/ios/Runner/Info.plist`.

More detail (features, code structure, packages, permissions): [`mobile_app/README.md`](mobile_app/README.md).

## B3. Tests

With XAMPP running (Python 3, standard library only):
```
python tests/api_smoke_test.py      # whole API life cycle (52 checks)
python tests/web_smoke_test.py      # website forms as visitor and admin (92 checks)
cd mobile_app && flutter analyze    # app code check
```
The tests create their own accounts and reports (names start with `smoke` / `websmoke`). Afterwards, restore the
clean demo data with `C:\xampp\php\php.exe website\tools\demo_data.php --reset`.

## B4. Languages and texts

| Where | Files |
|---|---|
| Server messages (website + API) | `website/lang/{ar,en,tr,ur}.php` (the API answers in the app's language; web pages in the language picked in the menu, saved in the `mafqodak_lang` cookie) |
| Website page texts | `website/assets/i18n/{ar,en,ur,tr}.js` (`data-i18n` keys) |
| App texts | `mobile_app/lib/core/l10n/`: Arabic/English in `strings_ar/en.dart` + `strings/*_strings.dart`; Turkish and Urdu (every key) in `strings_tr.dart`, `strings_ur.dart` |
| Option lists (categories, landmarks, …) | `website/config/lookups.php` (stored and sent in Arabic; served to the app by `GET /lookups`) |
| Option list translations | `website/assets/i18n/values.js` and `mobile_app/lib/core/l10n/strings/lookup_values.dart` (same table; keep both in sync when a list changes) |

**App icon:** made from the official logo: Android launcher (with adaptive icon), iOS, web, Windows and the website favicon.

## B5. App download link

The website has a download page: **https://mafquduk.dev/Project/download.php** (link in the navbar and a banner on
the home page). It offers the APK, shows its size and date, a QR code for phones, and install steps.

The APK is not stored in this repository. To publish a new app version:
1. `cd mobile_app` → `flutter build apk --release`
2. Copy `mobile_app/build/app/outputs/flutter-apk/app-release.apk` to `website/download/mafqoodak.apk`
   and update `$appVersion` in `website/download.php` if the version changed.
3. Upload `website/download/mafqoodak.apk` to the server (same path under `/Project/`).

## B6. Before going live

- Set `APP_DEBUG` to `false` in `website/db.php` and give the database user a password.
- The live site is on **https** (https://mafquduk.dev). The app still allows plain http only so a local XAMPP server can be
  used for demos; remove `android:usesCleartextTraffic="true"` from `AndroidManifest.xml` when that's no longer needed.
- Phone-code login: connect an SMS provider in `sms_send()` (`website/lib/services/account_service.php`); until
  then the code is shown on screen (development mode).
- Maps: use a commercial map tile provider instead of the public OpenStreetMap tiles for heavy production use.
