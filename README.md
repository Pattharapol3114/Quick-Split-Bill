# Quick Split Bill

## Overview
Quick Split Bill is a Flutter application for tracking shared expenses in trips or group activities.
It helps users record bills, split costs among members, and view settlement summaries so everyone can
see who owes whom. The app supports both authenticated usage (via Firebase Auth) and guest mode for
quick usage without account creation.

## Features (MVP)
- Authentication flow with landing, login, and account creation screens.
- Guest mode entry for temporary usage without signing in.
- Group management to create and manage members in a shared expense context.
- Bill and member models to represent expense entries and participants.
- Multi-bill ledger screen for reviewing recorded transactions.
- Settlement summary calculation to simplify balances between members.
- Trip history persistence for reviewing previous sessions.
- Firebase integration for app initialization and authentication state handling.

## Tech Stack
- Framework: Flutter (Dart)
- Backend services: Firebase Core, Firebase Authentication, Firestore rules setup
- Platforms configured: Android, iOS, Web, Windows, macOS, Linux
- State handling approach: Widget-based state and screen-driven navigation (Material 3)
- Local/domain services: custom settlement and trip storage services in `lib/services/`

## Getting Started
### Prerequisites
- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Android Studio or Xcode (for mobile builds)
- Firebase project configured for the target platform(s)

### 1. Clone and install dependencies
```bash
git clone <your-repository-url>
cd quick_split_bill
flutter pub get
```

### 2. Verify Firebase setup
- Ensure `lib/firebase_options.dart` exists and matches your Firebase project.
- Ensure platform config files are in place (already included in this repository):
	- Android: `android/app/google-services.json`
	- iOS: `ios/Runner/GoogleService-Info.plist`

### 3. Run the app
```bash
flutter run
```

### 4. Optional checks
```bash
flutter analyze
flutter test
```

### 5. Build examples
```bash
flutter build apk
flutter build web
```

## Project Structure
```text
lib/
	main.dart                         # App entry point, theme, and auth/guest root flow
	firebase_options.dart             # FlutterFire generated Firebase config
	models/
		bill.dart                       # Bill domain model
		member.dart                     # Member domain model
	screens/
		auth_landing_screen.dart        # Entry choice (login/register/guest)
		login_screen.dart               # User login
		create_account_screen.dart      # User registration
		group_management_screen.dart    # Group and member management
		multi_bill_ledger_screen.dart   # Expense ledger view
		settlement_summary_screen.dart  # Settlement result view
		trip_history_screen.dart        # Historical trip records
		glass_demo_screen.dart          # UI demo/experiment screen
	services/
		settlement_service.dart         # Settlement/business logic
		trip_storage_service.dart       # Trip persistence logic
	widgets/
		glass_card.dart                 # Reusable card UI
		guest_mode_banner.dart          # Guest mode indicator/banner
		vibrant_background.dart         # Reusable decorative background

android/, ios/, web/, windows/, macos/, linux/   # Platform-specific runners and configs
firebase.json, firestore.rules                     # Firebase project and security config
```
