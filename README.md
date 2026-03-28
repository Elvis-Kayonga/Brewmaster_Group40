# BrewMaster — Coffee Marketplace

A Flutter mobile application connecting smallholder coffee farmers directly with specialty buyers. Built for the ALU Mobile Application Development course, Group 40.

## Features

- **Direct Marketplace** — Farmers list coffee lots; buyers browse, filter, and purchase
- **Map View** — Interactive map showing listing locations with tap-to-preview
- **Secure Payments** — Flutterwave escrow (card, mobile money, USSD) with full transaction history
- **Real-Time Messaging** — Direct farmer-buyer chat with push notifications
- **Market Prices** — Live commodity price feed (Stooq) with chart visualization
- **Voice Assistant** — Speech-to-text input for low-literacy users
- **Multilingual** — English, Kinyarwanda, and Kiswahili (persisted via SharedPreferences)
- **Dark / Light Theme** — Toggleable, persisted across sessions
- **Offline-First** — Firestore local persistence (40 MB cache); syncs on reconnect
- **Farmer Verification** — Badge system with admin-approved verification workflow
- **Saved Lots** — Buyers can save listings for later

## Tech Stack

- **Framework**: Flutter 3.x (Dart 3.10.4)
- **Architecture**: Clean Architecture with BLoC pattern
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Payments**: Flutterwave Standard Checkout
- **Maps**: flutter_map (OpenStreetMap tiles)
- **State**: flutter_bloc + provider (ThemeNotifier, LocaleNotifier)

## Prerequisites

- Flutter SDK 3.x / Dart 3.10.4+
- Android Studio or VS Code with Flutter extension
- Firebase project (see setup below)
- A `.env` file with your API keys (see `.env.example`)

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/Elvis-Kayonga/Brewmaster_Group40.git
cd Brewmaster_Group40
flutter pub get
```

### 2. Firebase configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable: **Authentication** (Email/Password), **Cloud Firestore**, **Firebase Storage**, **Cloud Messaging**
3. Download `google-services.json` → place in `android/app/`
4. The `lib/firebase_options.dart` file is already configured for the project Firebase instance

### 3. Environment variables

Create `.env` in the project root (this file is gitignored):

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
FLUTTERWAVE_PUBLIC_KEY=your_flutterwave_key
```

### 4. Deploy Firestore rules and indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 5. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── config/                  # Theme, locale, routing, localization
│   └── localization/        # AppLocalizations (en / rw / sw)
├── data/
│   ├── repositories/        # Firebase implementations
│   └── services/            # Exchange rate, Cloudinary
├── domain/
│   ├── models/              # CoffeeListing, UserProfile, EscrowTransaction ...
│   └── repositories/        # Abstract repository interfaces
└── presentation/
    ├── blocs/               # BLoC classes (auth, listing, payment, messaging ...)
    ├── screens/             # Full-screen pages
    └── widgets/             # Reusable UI components
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Building a Signed Release APK

The project is configured for release signing via `android/key.properties` (gitignored).

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

For Play Store:

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## Team

| Name | Role | GitHub |
| --- | --- | --- |
| Ryan Apreala | UI/UX · Offline Sync · Integration · Testing | rapreala |
| Elvis Kayonga | Firebase · Auth · Profiles · Verification | Elvis-Kayonga |
| Dan Paul Dushime | Payments · Escrow | DUSHIME Dan Paul |
| Justine Neema | Messaging · Notifications | justine-neema |
| Clarisse | Listings · Search | Clarisse-12 |
| Claudia Adeline | Dashboard · Market Prices | iclaudiaadeline |

## AI Tool Disclosure

This project used Claude (Anthropic) for code generation assistance, debugging, localization drafting, and documentation. All AI-generated output was reviewed and approved by the relevant team member before being committed.

**Reference:** Anthropic. (2025). *Claude* (claude-sonnet-4-6) [Large language model]. [https://claude.ai](https://claude.ai)

## License

Developed for academic purposes — ALU Mobile Application Development, 2026.
