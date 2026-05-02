# PocketLedger

A privacy-first, offline personal finance manager built with Flutter.

## Features
- 💰 Track expenses, income, wallets, loans & budgets
- 🌙 Dark / Light / System theme with Material 3
- 🌍 Multilanguage: English, Hindi, Arabic (RTL support)
- 🔐 PIN lock + biometric authentication
- 📊 Charts & AI-powered insights
- 🔒 AES-encrypted Google Drive backup
- 📷 OCR receipt scanning
- 📤 Export to PDF / Excel / CSV
- 💬 SMS import for auto-categorization
- 👥 Group expense splitting

## Tech Stack
- **Flutter** 3.32 (Dart 3.3)
- **State Management**: Riverpod 2
- **Navigation**: go_router 13
- **Database**: SQLite (sqflite) — 23 tables
- **Theme**: Material 3 with custom Inter font
- **i18n**: flutter_localizations + intl ARB files

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.32
- Android SDK (API 21+) or Xcode 15+

### Setup
```bash
# Clone the repo
git clone <repo-url>
cd pocket_ledger

# Install dependencies
flutter pub get

# Generate l10n
flutter gen-l10n

# Run on device
flutter run
```

### Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Project Structure
```
lib/
├── main.dart                  # Entry point
├── app.dart                   # MaterialApp.router + theme/locale setup
├── core/
│   ├── database/              # SQLite helper + base repository
│   ├── navigation/            # GoRouter config + guards
│   ├── providers/             # appInitProvider, authStateProvider
│   └── theme/                 # AppColors, AppTextStyles, AppTheme
├── features/
│   ├── auth/                  # PIN lock screen + security repository
│   ├── onboarding/            # 5-step onboarding flow
│   ├── dashboard/             # Dashboard shell + home screen
│   ├── expenses/              # Expense CRUD
│   ├── income/                # Income CRUD
│   ├── wallets/               # Wallet management
│   ├── loans/                 # Loan tracking
│   ├── budgets/               # Budget management
│   ├── reports/               # Charts & analytics
│   ├── search/                # Global search
│   ├── contacts/              # Contact management
│   ├── groups/                # Group expense splitting
│   ├── insights/              # AI-powered insights
│   ├── ocr/                   # Receipt scanning
│   └── settings/              # Settings screens
├── l10n/                      # ARB translation files (en, hi, ar)
├── generated/                 # Generated l10n code (do not edit)
└── shared/
    ├── providers/             # theme_provider, locale_provider
    └── widgets/               # Shared UI components
```

## Supported Languages
| Code | Language | Direction |
|------|----------|-----------|
| `en` | English  | LTR       |
| `hi` | Hindi    | LTR       |
| `ar` | Arabic   | RTL       |

## Security
- 6-digit PIN with SHA-256 + per-device salt
- Biometric authentication (fingerprint / Face ID)
- Auto-lock after configurable idle time
- AES-256 encrypted backups
- Keys stored in flutter_secure_storage

## License
MIT
