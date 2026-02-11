# BrewMaster Coffee Marketplace

A Flutter mobile application that connects smallholder coffee farmers directly with specialty buyers, eliminating intermediaries and providing price transparency, secure payments, and quality verification.

## Features

- **Direct Marketplace**: Connect farmers and buyers without middlemen
- **Offline-First**: Works without internet, syncs when online
- **Secure Payments**: Escrow system with M-Pesa and MTN Mobile Money
- **Price Transparency**: Real-time market prices for fair trading
- **Quality Verification**: Verified farmer badges and quality profiles
- **Low-Literacy Support**: Icon-driven navigation and voice input
- **Messaging**: Direct communication between farmers and buyers

## Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK (3.10.4 or higher)
- Android Studio / VS Code with Flutter extensions
- Firebase account
- FlutterFire CLI

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd brewmaster
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure --project=brewmaster-coffee
```

This will:
- Create a Firebase project (or select existing)
- Register your app with Firebase
- Generate `lib/firebase_options.dart` with your configuration
- Download `google-services.json` for Android

#### Option B: Manual Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Email/Password and Phone)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging
3. Download `google-services.json` and place it in `android/app/`
4. Update `lib/firebase_options.dart` with your Firebase configuration

### 4. Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── presentation/          # UI Layer
│   ├── screens/          # Full-screen pages
│   └── widgets/          # Reusable UI components
├── domain/               # Business Logic Layer
│   ├── models/          # Data models
│   └── validators/      # Input validation
├── data/                # Data Layer
│   ├── services/        # Firebase interactions
│   ├── providers/       # State management
│   └── repositories/    # Data access
├── config/              # App configuration
│   ├── theme.dart       # App theme
│   ├── constants.dart   # Constants
│   └── routes.dart      # Navigation routes
├── utils/               # Helper utilities
└── main.dart            # App entry point
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Generate Coverage Report

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Firebase Services Used

- **Authentication**: User registration and login
- **Cloud Firestore**: Database for users, listings, messages, transactions
- **Firebase Storage**: Image storage for listings and profiles
- **Cloud Messaging**: Push notifications
- **Cloud Functions**: (Future) Payment processing and admin tasks

## Dependencies

### Core
- `flutter`: Cross-platform mobile framework
- `provider`: State management
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Database
- `firebase_storage`: File storage
- `firebase_messaging`: Push notifications

### Utilities
- `image_picker`: Image selection
- `intl`: Internationalization
- `connectivity_plus`: Network connectivity

### Testing
- `faker`: Test data generation
- `mockito`: Mocking for tests
- `build_runner`: Code generation

## Team

- **Developer 1**: Firebase + Authentication + Profiles + Verification + Security
- **Developer 2**: Listings + Search + Discovery
- **Developer 3**: Messaging + Notifications
- **Developer 4**: Payments + Escrow + Compliance
- **Developer 5**: Dashboard + Market Prices + Analytics
- **Developer 6**: UI/UX + Offline Sync + Integration + Testing

## License

This project is developed for academic purposes as part of the Mobile Application Development course.

## Support

For issues and questions, please contact the development team or create an issue in the repository.
