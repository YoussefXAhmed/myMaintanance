# CarCare Pro — صياناتي

A **premium automotive management platform** built with Flutter. Track vehicle
maintenance, fuel consumption, expenses, documents, insurance and a live
**vehicle health score** — all wrapped in a custom **Liquid Glass** design
system (frosted surfaces, dynamic blur, floating navigation, spring animations).

> Bilingual **Arabic (RTL)** & **English (LTR)** with instant, restart‑free
> language switching. Dark / Light / System themes.

---

## ✨ Features

| Area | What's included |
|------|-----------------|
| **Auth** | Email/Password, Sign Up, Login, Forgot Password, Remember Me, Email Verification, Google & Apple sign‑in, Logout. Runs offline with a local auth fallback when Firebase is disabled. |
| **Onboarding** | 4 premium animated pages with skip / get‑started. |
| **Dashboard** | Tesla‑style hero card, animated **Vehicle Health** ring, mini rings (oil / battery / tyres / insurance), quick stats, quick actions, upcoming reminders. |
| **Vehicles** | Unlimited vehicles, full spec sheet, image, instant switching, primary vehicle. |
| **Maintenance** | 12 tracked items, status grid, **service timeline**, auto‑computed next‑due (km + date), cost & notes. |
| **Fuel** | Fill‑up log, km/L, cost/km, monthly & yearly spend, consumption chart. |
| **Expenses** | 9 categories, monthly/yearly reports, category breakdown pie. |
| **Documents** | License, insurance, inspection, invoices, receipts with expiry tracking. |
| **Analytics** | Animated bar / pie / line charts (fl_chart). |
| **AI Advisor** | Rule‑based recommendation engine with an **OpenAI‑ready** architecture. |
| **Notifications** | Local reminders for maintenance, insurance & license with customisable lead time. |
| **Settings** | Theme, language, notification controls, data export, backup/restore, delete account. |

---

## 🧱 Architecture

Clean architecture with a clear separation of layers:

```
lib/
├── core/            # config, router, formatters, ui catalog
├── features/        # one folder per screen/feature (UI)
├── models/          # immutable data models (JSON + Hive friendly)
├── repositories/    # offline‑first data access (Hive + cloud sync)
├── services/        # auth, firebase, storage, notifications, health, advisor
├── providers/       # Riverpod state (auth, settings, vehicles, data)
├── widgets/         # the Liquid Glass design system
├── themes/          # colors, typography, theme, dimens, motion
└── localization/    # ar/en string tables + delegate
```

**Stack:** Flutter · Riverpod · GoRouter · Hive · Firebase (Auth/Firestore/Storage) ·
flutter_local_notifications · fl_chart · flutter_animate · google_fonts · Material 3.

**Design system:** see [`docs/DESIGN_SYSTEM_API.md`](docs/DESIGN_SYSTEM_API.md).

---

## 🚀 Quick start

This repository contains the complete **`lib/` source, `pubspec.yaml`, assets
structure and docs**. Generate the native platform folders, then run:

```bash
# 1) From the project root, generate android/ ios/ web/ scaffolding
#    (does NOT touch lib/). Use your own bundle id.
flutter create --org com.carcarepro --project-name carcare_pro --platforms=android,ios,web .

# 2) Install dependencies
flutter pub get

# 3) Run (works out of the box in OFFLINE mode — no Firebase required)
flutter run
```

> **Runs with zero configuration.** Firebase is **disabled by default**
> (`AppConfig.enableFirebase == false`), so the app is fully functional offline
> using Hive. Auth, data and reminders all work locally. Enable the cloud when
> you're ready — see below.

### Enable Firebase (optional)
```bash
dart pub global activate flutterfire_cli
flutterfire configure          # regenerates lib/firebase_options.dart
flutter run --dart-define=ENABLE_FIREBASE=true
```
Full steps, Firestore structure and security rules: [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md).

### Enable the OpenAI advisor (optional)
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-...
```
Implement the call in `lib/services/ai_advisor_service.dart` (`OpenAiAdvisor`).

---

## 🎨 Assets & fonts

To keep the project **building with no missing‑asset errors**, it ships
**without binary assets**:

* **Fonts** are fetched at runtime by `google_fonts` (Inter for Latin, Cairo for
  Arabic) — nothing to bundle.
* **Vehicle images** use network URLs with a graceful gradient fallback; all
  other imagery is custom‑painted / Material icons.

The declared asset folders (`assets/images`, `assets/icons`,
`assets/illustrations`) contain `.gitkeep` placeholders. Drop your own assets in
and reference them as usual. To bundle fonts offline instead of `google_fonts`,
add the `.ttf` files and a `fonts:` section to `pubspec.yaml`.

---

## 🏗 Build

Android / iOS configuration, permissions and release builds:
[`docs/BUILD_AND_PLATFORM.md`](docs/BUILD_AND_PLATFORM.md).

```bash
flutter analyze
flutter build apk --release         # Android
flutter build ios --release         # iOS (on macOS)
```

### Dependency versions
The pinned plugin versions target a recent Flutter stable. If `flutter pub get`
reports a version‑solve conflict (e.g. `intl` pinned by your Flutter SDK), run:
```bash
flutter pub upgrade --major-versions
```

---

## 🌍 Localization

All strings live in `lib/localization/app_strings.dart` (`en` + `ar` maps).
Access with `context.tr('key')` or `context.l10n.t('key', params: {...})`.
Switch language live from **Settings** — no restart, full RTL mirroring.

---

## 📦 Offline‑first data

Every write goes to **Hive** immediately and is best‑effort mirrored to
**Firestore** when Firebase is enabled and the user is signed in. On login,
cloud data is pulled to seed a new device. The app is fully usable with no
network connection.
