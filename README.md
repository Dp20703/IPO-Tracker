# IPO Tracker

A personal, offline-first Flutter app for tracking IPO applications across multiple Demat accounts — built for individuals and families who apply for IPOs from more than one account and need a single place to see what was applied for, where, and what the allotment outcome was.

> **Privacy by design.** All data lives in a local SQLite database on your device. Nothing is uploaded anywhere. No broker credentials, UPI PINs, OTPs, or passwords are ever requested or stored. See [Privacy & Security](#privacy--security).

---

## Table of Contents

- [Who This Is For](#who-this-is-for)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Data & Backup](#data--backup)
- [Privacy & Security](#privacy--security)
- [Roadmap](#roadmap)
- [Known Limitations](#known-limitations)
- [Attribution](#attribution)
- [License](#license)

---

## Who This Is For

| Use case | How IPO Tracker helps |
|---|---|
| **An individual investor** with one Demat account who applies for several IPOs a month | Replaces a mental checklist or scattered notes with one dashboard: what's open, what's closing, what's pending allotment. |
| **A family coordinator** managing applications across their own, a spouse's, and parents' Demat accounts | The Account × IPO matrix shows, per IPO, exactly which family accounts applied and what each one's allotment status is — no more asking "did Dad apply for this one?" |
| **A frequent SME/Mainboard IPO applicant** tracking allotment odds over time | Statistics screen calculates allotment success rate automatically across every tracked application. |
| **Someone who wants IPO dates without digging through broker apps or news sites** | Optional one-tap sync pulls the live IPO calendar (dates, price band, GMP) from a public API or a CSV import — no manual typing required. |
| **Anyone wary of sharing financial identity data with yet another app** | The app is fully usable offline with zero network calls. Sync is opt-in and only ever reads public market data — it never transmits PAN, Demat, or application details anywhere. |

---

## Features

### Accounts
- Store multiple Demat account profiles (holder name, nickname, PAN, DP ID, Client ID, broker)
- PAN format validation and uniqueness check
- PAN masked everywhere by default; full PAN only shown after an explicit confirmation tap

### IPO Management
- Track Current / Upcoming / Closed IPOs with a dedicated board-type filter (Mainboard / SME, independently toggleable) and a status filter, plus sorting (closing soon, opening soon, name, recently added)
- Manual entry, bulk CSV/pasted-text import (with per-row validation preview), or one-tap sync from the IPO Guru API
- Grey Market Premium (GMP) shown as a clearly labeled, unverified figure — manual entry or auto-filled from sync, never presented as advice

### Application Tracking
- Per-account, per-IPO application status, lots applied, allotment status, and shares allotted
- Account × IPO matrix with a live progress bar ("8/12 accounts applied")
- All Applications screen with multi-criteria filtering, exportable as CSV

### Reporting
- Dashboard with current/upcoming counts, applied applications, and pending allotments
- Pending Actions list (closes today, allotment pending, listing today)
- IPO History and Important Dates screens
- Statistics screen: total IPOs, total applications, allotment success rate

### Data Portability
- Full JSON backup (all accounts, IPOs, applications, registrars) shareable via the OS share sheet
- Safe, non-destructive restore — existing data is never overwritten, only merged

### Registrar Shortcuts
- Store registrar names/links and open the *official* registrar site to check allotment yourself — the app never scrapes, automates, or bypasses CAPTCHA on any registrar site

---

## Screenshots

*(Add screenshots here — Home dashboard, IPO list with filters, Account × IPO matrix, Statistics.)*

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart, null-safe), Material 3 |
| State management | [`provider`](https://pub.dev/packages/provider) |
| Local database | [`sqflite`](https://pub.dev/packages/sqflite) (SQLite) |
| Secure storage | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) — API key only |
| Networking | [`http`](https://pub.dev/packages/http) |
| File share / export | [`share_plus`](https://pub.dev/packages/share_plus) |
| File import | [`file_picker`](https://pub.dev/packages/file_picker) |
| Settings | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| External links | [`url_launcher`](https://pub.dev/packages/url_launcher) |
| Dates | [`intl`](https://pub.dev/packages/intl) |

No backend, no Firebase, no analytics, no ads.

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, Provider wiring, routing
├── models/                      # Account, Ipo, IpoApplication, Registrar
├── database/
│   └── database_helper.dart     # SQLite schema, CRUD, migrations
├── providers/                   # AccountProvider, IpoProvider,
│                                 # ApplicationProvider, RegistrarProvider
├── services/
│   ├── ipo_sync_service.dart    # IPO Guru API client
│   ├── sheet_sync_service.dart  # Public CSV / Google Sheet sync (optional)
│   ├── backup_service.dart      # JSON export/import
│   ├── api_key_store.dart       # Secure storage for the API key
│   └── shared_list_settings.dart
├── screens/
│   ├── splash/
│   ├── home/
│   ├── accounts/                # List, add/edit, detail
│   ├── ipos/                    # List+filters, add/edit, detail, import
│   ├── applications/            # Detail, all-applications + CSV export
│   └── more/                    # Settings, backup, statistics, history,
│                                 # important dates, registrar links
├── widgets/                     # Reusable cards, dialogs, empty states
├── theme/
│   └── app_theme.dart           # Light/dark Material 3 theme
└── utils/                       # Validators, date parsing, CSV parsing,
                                  # constants
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio (with the Flutter and Dart plugins) or VS Code
- An Android device/emulator (iOS project files are present but untested)

### Setup

```bash
git clone <this-repo>
cd ipo_tracker
flutter pub get
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

The output is at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Configuration

Everything below is **optional** — the app is fully usable with 100% manual entry and no configuration at all.

### IPO Guru API sync (optional)
1. Request a free API key by emailing **ipoguru.in@gmail.com** (see their [developer API page](https://www.ipoguru.in/ipo-gmp-details-developer-api)).
2. In the app: **More → IPO Data Sync** → paste the key → Save.
3. On the IPOs tab, use the sync menu to pull the live calendar. Free tier: 10 requests/day.

### Shared IPO list (optional, no API key needed per install)
Point the app at a public CSV URL (e.g. a Google Sheet published to the web) that you maintain centrally, so every install of the app can sync from the same source without each person needing their own API key. See `lib/services/sheet_sync_service.dart`.

---

## Data & Backup

All data is stored locally in SQLite, private to the app (standard Android app-sandbox behavior). **Uninstalling the app permanently deletes this data** — there is no cloud backup.

Use **More → Backup & Restore** to:
- **Export** everything to a single JSON file, shareable via Drive, email, etc.
- **Restore** from that file later — on the same device or a new one. Restoring never overwrites or deletes existing data; matching records (by PAN, or by company+dates for IPOs) are skipped rather than duplicated.

**Back up before uninstalling, updating via a differently-signed APK, or switching devices.**

---

## Privacy & Security

This app was built against an explicit set of constraints, enforced throughout:

- ❌ Never stores broker passwords, login credentials, UPI PINs, OTPs, or bank/card details
- ❌ Never transmits PAN or Demat details to any external site
- ❌ Never scrapes websites or automates/bypasses CAPTCHA
- ❌ No automated IPO applications — this is a tracker, not a trading bot
- ✅ PAN numbers masked in all list views; full PAN requires explicit confirmation
- ✅ Fully functional offline; any network access (API sync, allotment check link) is user-initiated
- ✅ The IPO Guru API key is stored in platform secure storage (Android Keystore-backed), not the regular database

"Check Allotment Status" opens the **official registrar's own website** in your browser — you enter your own PAN there yourself, same as checking manually.

---

## Roadmap

Not yet built, roughly in priority order:

- [ ] App lock (PIN/biometric) via `local_auth`
- [ ] Local notifications for closing/allotment/listing dates (`flutter_local_notifications`)
- [ ] Statistics charts (currently numeric cards only)
- [ ] Manual dark-mode toggle (currently follows system setting)
- [ ] Multi-select/bulk actions on the IPO list
- [ ] iOS launcher icon parity (Android icon is already custom; iOS still uses the default)

---

## Known Limitations

- Registrar contact info (name/link) is **not** included in IPO Guru's free-tier API response — fill it in manually per IPO, or upgrade to their Basic plan.
- GMP figures are unofficial market rumour, sourced from IPO Guru's `gmp` field or typed in manually — never treat as verified data or investment advice.
- No automated allotment checking exists or is planned — registrar sites intentionally block this via CAPTCHA, and bypassing that is out of scope for this project.
- Single-device only; there is no multi-device sync (use Backup & Restore to move data between devices).

---

## Attribution

IPO calendar and GMP data, where synced, is provided by [IPO Guru](https://www.ipoguru.in/). Not affiliated with or endorsed by IPO Guru, NSE, BSE, or any registrar or broker named in the app.

---

## License

Personal / internal-use project. No open-source license has been applied — add one here if you intend to distribute or open-source this project.
