# مفقودك — Mafqoodak (mobile app)

Flutter app for **Mafqoodak**, the lost-and-found platform for the Grand Mosque (Makkah) and the holy sites.
Visitors report lost and found items, sightings and missing people; the system suggests matches; administrators
verify ownership and arrange handover or delivery. The app has the same features as the website and talks to the
same PHP REST API and MySQL database.

- Version: `1.0.3+4` · Bundle / application ID: `com.mafqoodak.mafqoodak`
- Platforms: Android, iOS (15+), web, Windows
- Languages: Arabic, English, Turkish, Urdu (RTL/LTR switches automatically)

The project requirements (functional and non-functional), server setup, database and the end-to-end tests are
described in the project's main [`README.md`](../README.md); the website and API in
[`website/README.md`](../website/README.md).

## Features

**Visitors**
- Sign up, sign in with email and password, or sign in with a 4-digit code sent to a Saudi phone number (`05XXXXXXXX`)
- Report a lost item, a found item or a sighting, with photo (camera or gallery), date and location
  (landmark list or a point on the map)
- **Emergency report** for missing children and elderly people (no account needed; the field team is alerted)
- **Voice report**: an accessible, voice-first lost report using speech-to-text
- Browse found items as a list or on a map, open details and claim an item
- See suggested matches, follow claims, request delivery (shipping) of a returned item
- Track any report by its number (no account needed): searching → matched → ready → delivered / cancelled
- Notifications, profile, password change and language choice

**Administrators** (dashboard with tabs)
- Overview, Reports, Verification (review ownership claims), Handover, Shipping, Emergencies, Admins
  (approve new admin accounts)
- Manual matching of a lost report to a found item

## Requirements

- Flutter stable (developed with Flutter 3.47, Dart SDK `^3.13.5`)
- Android Studio with an emulator or an Android phone; Xcode on a Mac for iOS
- A running API: either the live server (default) or a local XAMPP server (see the main README)

## Getting started

```
cd mobile_app
flutter pub get
flutter run
```

### Choosing the server

The app finds the API in this order:

1. **Address saved in the app**: long-press the logo on the login screen and enter a domain, an IP or a full URL.
   A domain gets `https`, a local IP gets `http`, and `/Project/api/v1/` is added if missing. "Reset" returns to the
   default.
2. **Build-time address**: `--dart-define=API_BASE_URL=...`
3. **Live server**: `https://mafquduk.dev/Project/api/v1/`

| Target | Command |
|---|---|
| Live server | `flutter run` |
| Android emulator + local XAMPP | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2/Project/api/v1/` |
| Chrome + local XAMPP | `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost/Project/api/v1/` |
| Real phone + XAMPP on the same Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<PC-IP>/Project/api/v1/` |

For a real phone on a local server, use the computer's local IP address and allow Apache through the Windows
firewall. The setting lives in [`lib/core/config/api_config.dart`](lib/core/config/api_config.dart).

## Building

**Android APK** (one file for arm64, 32-bit arm and x86_64; works on Huawei phones without Google services):
```
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
```
The file is written to `build/app/outputs/flutter-apk/app-release.apk`. To publish it on the website's download
page, follow "App download link" in the main README.

**iOS** (needs a Mac with Xcode):
```
flutter build ios --release
```
Then archive in Xcode for TestFlight or the App Store. Without a Mac, run the **iOS build** GitHub workflow
([`.github/workflows/ios-build.yml`](../.github/workflows/ios-build.yml)); it produces an unsigned
`mafqoodak-unsigned.ipa` that Sideloadly or AltStore can install with a free Apple ID.

## Checking the code

```
flutter analyze
```
There are no Flutter unit tests yet; the API and the website are covered by the Python smoke tests in
[`../tests/`](../tests).

## Project structure

```
lib/
├─ main.dart            loads language, session and server address, then runs the app
├─ app.dart             MaterialApp: theme, RTL/LTR, route table, start screen
├─ core/
│  ├─ config/           ApiConfig (API base URL)
│  ├─ network/          ApiClient (JSON + multipart, Bearer token), ApiException
│  ├─ session/          Session (token, role, profile; saved on the device)
│  ├─ l10n/             L10n + strings_ar/en/tr/ur.dart and strings/<area>_strings.dart → t('key')
│  ├─ theme/            AppColors (same colours as the website), app theme
│  ├─ routes/           AppRoutes (named route for every screen)
│  ├─ widgets/          shared widgets: AsyncView, ItemCard, StatusChip, form fields, map and image pickers, voice input
│  └─ utils/            validators
├─ data/
│  ├─ models/           typed API objects (fromJson)
│  └─ repositories/     one method per API endpoint
└─ features/            screens grouped by area:
                        onboarding, auth, home, reports, items, claims, shipping, notifications, profile, admin
```

Layers depend only downwards: **features → data → core**. Screens use repositories (never `ApiClient` directly),
navigate with named routes (never import each other), and take every visible text from `t('key')`.

### Adding or changing text

- Arabic and English: `lib/core/l10n/strings_ar.dart` / `strings_en.dart` (shared keys) and
  `lib/core/l10n/strings/<area>_strings.dart` (one feature area each)
- Turkish and Urdu: `strings_tr.dart` / `strings_ur.dart`
- Option values the server stores in Arabic (categories, landmarks…): `strings/lookup_values.dart`; keep it in sync
  with `website/assets/i18n/values.js`

A missing key falls back to English, then Arabic, then the key itself.

## Packages

| Package | Used for |
|---|---|
| `http` | REST API calls |
| `shared_preferences` | session, language and server address on the device |
| `image_picker` | report and claim photos |
| `flutter_map`, `latlong2` | items map and location picker (OpenStreetMap tiles) |
| `speech_to_text` | voice input and the voice report |
| `intl`, `flutter_localizations` | dates and localisation |

Font: IBM Plex Sans Arabic (SIL Open Font License, [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt)), the same
typeface as the website.

## Permissions

| Platform | Permissions |
|---|---|
| Android | Internet, camera, microphone (`android/app/src/main/AndroidManifest.xml`) |
| iOS | Camera, photo library, microphone and speech recognition texts in `ios/Runner/Info.plist` |

`android:usesCleartextTraffic="true"` is on only so a local `http` XAMPP server can be used for demos. Remove it
when that is no longer needed; the live server uses `https`.
