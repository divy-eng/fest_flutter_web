# KLE Haveri BCA — Independence Day 2026 Fest App

A Flutter mobile/web app for the **KLE Haveri BCA Independence Day 2026** college fest. It lets visitors browse the fest homepage, explore events, register for technical events, and download printable PDF vouchers. Registrations are persisted to a **Supabase** backend.

## Features

- **Homepage** with auto-scrolling gallery, event info (date, venue, live participant count), and action buttons.
- **Events** tab listing technical and cultural events with type-specific actions (Register / Let's start the program).
- **Registration** for technical events via a validated form (name, phone, college, email) persisted to Supabase.
- **Live participant counts** — the homepage stat and per-event "X registered" chips update immediately on registration.
- **PDF vouchers** — download a registration voucher by entering your email; the app fetches the matching record from Supabase and renders a Unicode-safe PDF ticket (bundled Roboto fonts).
- **About / Gallery / Contact** tabs, social links, and map link to the venue.

## Tech Stack

| Layer | Choice |
| --- | --- |
| UI / Framework | Flutter (Material 3-ready widgets) |
| Language | Dart |
| Backend | Supabase (REST API via `http`) |
| Config | `flutter_dotenv` (`assets/.env`) |
| PDF generation | `pdf` + `printing` |
| External links | `url_launcher` |
| Lints | `flutter_lints` |

## Project Structure

```
.
├── lib/
│   └── main.dart              # Entire app: domain model + UI + services
├── assets/
│   ├── .env.example           # Template for environment variables
│   ├── google_fonts/          # Bundled Roboto TTFs for PDF Unicode support
│   └── images/                # Gallery / banner images
├── test/
│   └── widget_test.dart
├── android/  ios/  web/  linux/  macos/  windows/   # Platform shells
├── .gitignore
├── pubspec.yaml
└── README.md
```

The application logic currently lives in a single file (`lib/main.dart`) to keep the demo self-contained, organized into clearly commented sections.

## Architecture

The app demonstrates core object-oriented principles while keeping a clean separation between the domain model and the Flutter UI.

### 1. Abstraction & Interfaces

- `FestEvent` (abstract): base class for all events, exposing the polymorphic contract `getEventDetails()` and `getIcon()`, plus a concrete `locationInfo` getter.
- `Certifiable` (interface): contracts `generateCertificate(...)` and `offersCertificate` for events that issue certificates.

### 2. Mixins (reusable feature injection)

- `SponsorshipRequirement`: reusable budget/sponsorship handling (`budget`, `addSponsorship`, `allocateExpense`) mixed into technical events.

### 3. Encapsulation, Inheritance & Polymorphism

- `TechnicalEvent extends FestEvent with SponsorshipRequirement implements Certifiable`:
  - Encapsulated fields (`_registrationsCount`, `_maxCapacity`) exposed via getters (`registrationsCount`, `hasCapacity`).
  - `registerStudent()` increments the count and a static `totalFestRegistrations`.
  - Standard, named (`codingCompetition`), and factory (`hackathon`) constructors.
  - Polymorphic `getEventDetails()` shows live slot usage.
- `CulturalEvent extends FestEvent implements Certifiable`:
  - Polymorphic `getEventDetails()` reflects stage-preparation status.
  - `offersCertificate == false` (cultural events award trophies).

### 4. UI Layer

`CollegeFestDashboard` (StatefulWidget) owns the state and renders tabs (Home, Events, About, Gallery, Contact). Event cards render polymorphically via the `FestEvent` contract. A single `setState` after registration refreshes the homepage stats, event cards, and voucher availability together.

### 5. Data / Services

- **Supabase REST**: registrations are written with `POST /rest/v1/registrations` and read back with a filtered `GET` (`email_address` + `event_title`).
- **Config**: `SUPABASE_URL` / `SUPABASE_KEY` are read from `assets/.env`.
- **PDF**: `pw.Document` with a `ThemeData.withFont(...)` using bundled Roboto so Unicode text (names, special characters) renders correctly.

## Workflow

### Registration flow

1. User opens **Events**, taps **Register** on a technical event card.
2. A validated dialog collects name, phone, college, and email.
3. The app `POST`s the registration to Supabase; on success (`201`) the event count is incremented via `registerStudent()`.
4. The UI rebuilds: the homepage participant stat, the event card's "X registered" chip, and slot info all update immediately.

### Voucher download flow

1. User taps **Download Voucher** (event card or event detail page).
2. A dialog asks for the email used at registration.
3. The app queries Supabase for the latest matching registration and rebuilds the `RegistrationData` from the database row.
4. A PDF voucher ticket is generated and opened via the system print/save dialog (`Printing.layoutPdf`).

### Prerequisites

- Flutter SDK (stable)
- A Supabase project with a `registrations` table

### Supabase schema (`registrations`)

| Column | Type | Notes |
| --- | --- | --- |
| `student_name` | text | Student's name |
| `phone_number` | text | Contact number |
| `college` | text | College name |
| `email_address` | text | Used to fetch vouchers |
| `event_title` | text | Event title |
| `event_venue` | text | Event venue |
| `event_type` | text | Dart runtime type string |
| `registered_at` | timestamptz | UTC registration timestamp |

Enable the **anon key** with insert/select permissions, or use the service role key locally.

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>

# 2. Install dependencies
flutter pub get

# 3. Configure environment variables
cp assets/.env.example assets/.env
#   -> edit assets/.env and set SUPABASE_URL and SUPABASE_KEY

# 4. Run the app
flutter run

# 5. (Optional) Static analysis
flutter analyze
```

> **Security note:** `assets/.env` is ignored by git. Never commit real Supabase keys. If you accidentally commit secrets, rotate them immediately and purge them from git history.

## Useful Commands

```bash
flutter analyze          # static analysis
flutter test             # run widget tests
flutter build apk        # release APK
flutter build web        # web build
```

## License

Private project — all rights reserved. Contact the KLE Haveri BCA department for reuse.
