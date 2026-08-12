# Bite Size — Project Architecture

## State management: Provider (not GetX)

The existing `core/` layer already uses the ChangeNotifier pattern
(`ThemeService` is a ChangeNotifier singleton). Provider is the thinnest
possible layer over that: controllers stay plain Dart `ChangeNotifier`
classes, testable without a framework, and GetX's parallel routing/DI/snackbar
ecosystem stays out of the codebase. For a 4-screen utility app, simplicity
wins.

Pattern per feature: **Screen (dumb) → Controller (ChangeNotifier) →
Service (Firestore) → Models.**

## Folder structure (feature-first)

```
lib/
├── core/                          # App-wide plumbing (already existed)
│   ├── alerts/                    #   dialogs & toasts
│   ├── constants/                 #   AppConstants, helpers
│   ├── local_db/                  #   shared_preferences wrapper
│   ├── network/                   #   connectivity monitor
│   ├── shared/                    #   reusable widgets (CustomButton, …)
│   └── theme/                     #   AppColors, text styles, ThemeService
│
├── models/                        # Firestore document mirrors (pure data)
│   ├── app_user.dart              #   users/{uid}
│   ├── lunch_session.dart         #   sessions/{yyyy-MM-dd} + SessionStatus
│   ├── lunch_entry.dart           #   sessions/{date}/entries/{uid}
│   ├── extra_order.dart           #   sessions/{date}/extraOrders/{id}
│   └── ledger_transaction.dart    #   transactions/{id} + TransactionType
│
├── services/                      # Data layer — the only files that touch
│   └── firestore_service.dart     # Firestore. Transactions/aggregates here.
│
├── features/                      # One folder per feature, self-contained
│   └── dashboard/
│       ├── controllers/
│       │   └── dashboard_controller.dart
│       ├── screens/
│       │   └── dashboard_screen.dart
│       └── widgets/
│           ├── bite_size_counter.dart
│           ├── deficit_banner.dart
│           ├── roster_tile.dart
│           └── add_entry_sheet.dart
│
└── main.dart                      # Firebase init + providers + theming
```

## Planned features (same shape as `dashboard/`)

- `features/deficit_poll/` — "we're short, order extra?" poll + `ExtraOrder` creation
- `features/ledger/` — runner enters costs, settlement math writes
  `transactions` + balance updates (see docs/firestore_schema.md, "money math")
- `features/auth/` — upgrade anonymous auth to Google sign-in

## Rules of the road

1. Widgets never import `cloud_firestore` — only models/services do.
2. Controllers own subscriptions and cancel them in `dispose()`.
3. Anything used by 2+ features moves to `core/shared/`.
4. Session aggregates are only written inside `FirestoreService` transactions.

## Setup

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure          # generates lib/firebase_options.dart
# then in main.dart:  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
# Firebase console: enable Anonymous auth + create Firestore database
flutter run
```
