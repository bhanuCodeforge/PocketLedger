# PocketLedger — Developer Guide

Personal Finance Manager built with Flutter. This guide covers everything from first-time setup to Google Play production deployment.

---

## Table of Contents

1. [Project Setup](#1-project-setup)
2. [Running the Project Locally](#2-running-the-project-locally)
3. [Testing Guide](#3-testing-guide)
4. [Production Build Process](#4-production-build-process)
5. [Android Release](#5-android-release)
6. [Google Play Store Deployment](#6-google-play-store-deployment)
7. [CI/CD Automation](#7-cicd-automation)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Project Setup

### Required Software

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.41.x (stable) | Install via Puro (recommended) |
| Dart SDK | >= 3.3.0 | Bundled with Flutter |
| Java JDK | 17 | Microsoft JDK 17 tested |
| Android Studio | Ladybug+ | For emulator / SDK manager |
| Android SDK | API 36 | compileSdk and targetSdk |
| Android NDK | 28.2.13676358 | Required by native plugins |
| Gradle | 8.11.1 | via wrapper — do not install separately |
| AGP | 8.9.1 | Android Gradle Plugin |
| Kotlin | 2.1.0 | |
| Git | Any recent | |

### Installing Flutter via Puro (Windows)

Puro is a Flutter version manager. It avoids PATH conflicts and lets you switch Flutter versions per-project.

```powershell
# Install Puro via winget
winget install pingbird.Puro

# Restart your terminal, then:
puro create stable stable     # create an environment named "stable" using Flutter stable channel
puro use stable               # activate it globally
flutter --version             # verify: Flutter 3.41.x
```

If you already have Flutter installed via another method, skip Puro and add Flutter's `bin` folder to PATH directly.

### Installing the JDK

Download **Microsoft Build of OpenJDK 17** from:
https://learn.microsoft.com/en-us/java/openjdk/download

Set the environment variable:

```powershell
# PowerShell — add to your profile for persistence
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.15.6-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
java -version   # verify: openjdk 17
```

### Setting Up the Android SDK

**Option A — Android Studio (recommended)**

1. Download and install Android Studio.
2. Open SDK Manager (`Tools > SDK Manager`).
3. Install:
   - **SDK Platform**: Android 16 (API 36)
   - **SDK Build-Tools**: 35.0.0
   - **NDK (Side by Side)**: 28.2.13676358
   - **Android Emulator**

**Option B — Command-line only**

```powershell
# Set SDK location (example using D:\AndroidSdk)
$env:ANDROID_HOME     = "D:\AndroidSdk"
$env:ANDROID_SDK_ROOT = "D:\AndroidSdk"
$env:PATH = "D:\AndroidSdk\cmdline-tools\latest\bin;D:\AndroidSdk\platform-tools;D:\AndroidSdk\emulator;$env:PATH"

# Install required packages
sdkmanager "platform-tools"
sdkmanager "platforms;android-36"
sdkmanager "build-tools;35.0.0"
sdkmanager "ndk;28.2.13676358"
sdkmanager "emulator"
sdkmanager "system-images;android-36;google_apis;x86_64"

# Accept licenses
sdkmanager --licenses
```

### Environment Variables (Windows)

Set these permanently in **System Properties > Environment Variables** or in your PowerShell profile (`$PROFILE`):

```powershell
$env:JAVA_HOME         = "C:\Program Files\Microsoft\jdk-17.0.15.6-hotspot"
$env:ANDROID_HOME      = "D:\AndroidSdk"          # adjust to your SDK path
$env:ANDROID_SDK_ROOT  = "D:\AndroidSdk"
$env:ANDROID_AVD_HOME  = "D:\AndroidAVD"          # store AVDs on a spacious drive
$env:GRADLE_USER_HOME  = "D:\GradleCache"         # keep Gradle cache off C:
$env:TEMP              = "D:\FlutterTemp"
$env:TMP               = "D:\FlutterTemp"

# PATH additions
$env:PATH = "C:\Users\<you>\.puro\envs\stable\flutter\bin;" +
            "$env:JAVA_HOME\bin;" +
            "$env:ANDROID_HOME\platform-tools;" +
            "$env:ANDROID_HOME\emulator;" +
            "$env:ANDROID_HOME\cmdline-tools\latest\bin;" +
            $env:PATH
```

> **Windows Disk Space Warning**: The Gradle cache, Flutter pub cache, and Android SDKs combined can exceed 20 GB. Redirect caches to a drive with at least 30 GB free. C: is often too small on development laptops.

### Windows-Specific Prerequisites

**Developer Mode** — required for symlink support (Flutter build creates symlinks):

```
Settings > Privacy & Security > For developers > Developer Mode > ON
```

**Windows Defender exclusions** — Gradle's atomic transform-cache rename fails when Defender holds file locks on newly downloaded JARs. Add these paths as exclusions:

```
Windows Security > Virus & threat protection > Exclusions > Add a folder:
  D:\GradleCache
  D:\AndroidSdk
  D:\PocketLedger
  C:\Users\<you>\.puro
```

### Cloning the Repository

```bash
git clone https://github.com/<org>/PocketLedger.git
cd PocketLedger
```

### Installing Dependencies

```bash
flutter pub get
```

This downloads all packages listed in [pubspec.yaml](pubspec.yaml). Key dependencies:

| Category | Package | Version |
|---|---|---|
| State management | flutter_riverpod | ^2.5.1 |
| Navigation | go_router | ^13.2.0 |
| Database | sqflite + sqflite_common_ffi | ^2.3.3 |
| Security | flutter_secure_storage, local_auth, encrypt | latest |
| Notifications | flutter_local_notifications | ^17.2.2 |
| Charts | fl_chart | ^0.68.0 |
| Export | share_plus, pdf, excel, csv | latest |
| OCR | google_mlkit_text_recognition | ^0.13.0 |
| Background tasks | workmanager | ^0.5.2 |
| i18n | intl, flutter_localizations | ^0.20.2 |

### Generating Code

Several packages require code generation (Riverpod providers, localizations):

```bash
# Generate Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Generate localizations (runs automatically on flutter pub get if flutter.generate: true)
flutter gen-l10n
```

### Configuration Files

**`android/local.properties`** — not committed to git, must be created manually on each machine:

```properties
flutter.minSdkVersion=21
sdk.dir=D:\\AndroidSdk
flutter.sdk=C:\\Users\\<you>\\.puro\\envs\\stable\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

**`android/gradle.properties`** — committed, tuned for Windows stability:

```properties
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
org.gradle.daemon=false
org.gradle.parallel=false
org.gradle.workers.max=1
org.gradle.vfs.watch=false
kotlin.jvm.target.validation.mode=warning
```

> `org.gradle.daemon=false`, `parallel=false`, and `workers.max=1` prevent Gradle's transform-cache race condition on Windows. On Linux/macOS CI you can remove these restrictions for faster builds.

### Running `flutter doctor`

```bash
flutter doctor -v
```

All checkmarks except Chrome/Web are required. Expected output:

```
[✓] Flutter (Channel stable, 3.41.x)
[✓] Android toolchain (Android SDK 36, NDK 28.2.13676358)
[✓] Android Studio
[✓] Connected device (emulator or physical)
[!] Chrome – not required for this project
```

Accept Android licenses if prompted:

```bash
flutter doctor --android-licenses
# Answer 'y' to all prompts
```

---

## 2. Running the Project Locally

### Setting Up an Android Emulator

```bash
# Create an AVD (Pixel 6, Android 16 API 36)
avdmanager create avd \
  -n PocketLedger_AVD \
  -k "system-images;android-36;google_apis;x86_64" \
  -d "pixel_6"

# Start the emulator
emulator -avd PocketLedger_AVD -no-snapshot-load
```

On Windows, store the AVD on a large drive by setting `ANDROID_AVD_HOME` before creating it:

```powershell
$env:ANDROID_AVD_HOME = "D:\AndroidAVD"
# Then re-create the AVD so userdata is stored there
```

### Starting the Development Build

```bash
# List available devices
flutter devices

# Run on connected device (debug mode, hot reload enabled)
flutter run

# Run on a specific device
flutter run -d emulator-5554

# Run with verbose logging
flutter run -v
```

Hot reload shortcut while running: press `r`. Hot restart: press `R`. Quit: press `q`.

### Physical Device Testing

1. Enable **Developer Options** on your Android phone:
   - Settings > About phone > tap Build number 7 times
2. Enable **USB Debugging** in Developer Options.
3. Connect via USB cable.
4. Authorize the computer when prompted on the device.
5. Verify: `adb devices` — device should show as `device` (not `unauthorized`).
6. Run: `flutter run`

For wireless debugging (Android 11+):

```bash
adb tcpip 5555
adb connect <device-ip>:5555
flutter run
```

### Debugging Steps

**Flutter DevTools** — full-featured debugger, widget inspector, performance profiler:

```bash
flutter run --debug
# DevTools URL is printed in the terminal
# Or launch separately: flutter pub global activate devtools && flutter devtools
```

**In VS Code**:
- Install the Flutter extension.
- Press `F5` to launch with the debugger attached.
- Use the Widget Inspector panel for layout debugging.

**In Android Studio**:
- Open the `android/` folder as a Gradle project for native debugging.
- Use `Run > Debug 'main.dart'` for Flutter debugging.

**Log output**:

```bash
# Flutter logs only
flutter logs

# Android system logs filtered to the app
adb logcat -s flutter PocketLedger
```

---

## 3. Testing Guide

> The project currently has no test files. The sections below describe the intended test structure to implement.

### Directory Structure

```
test/
  unit/
    core/
      currency_formatter_test.dart
      database_helper_test.dart
    features/
      expenses/
        expense_repository_test.dart
      budgets/
        budget_repository_test.dart
      loans/
        loan_repository_test.dart
  widget/
    dashboard_screen_test.dart
    expenses_screen_test.dart
integration_test/
  expense_flow_test.dart
  loan_flow_test.dart
  backup_flow_test.dart
  onboarding_flow_test.dart
```

### Unit Testing

Unit tests live in `test/` and use `flutter_test` + `mocktail` for mocking.

```bash
# Run all unit tests
flutter test

# Run a specific file
flutter test test/unit/features/expenses/expense_repository_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Example unit test for the expense repository:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocket_ledger/features/expenses/data/expense_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late ExpenseRepository repo;
  late MockDatabaseHelper db;

  setUp(() {
    db = MockDatabaseHelper();
    repo = ExpenseRepository(db);
  });

  test('getExpenses returns empty list when database is empty', () async {
    when(() => db.query('expenses')).thenAnswer((_) async => []);
    final result = await repo.getExpenses();
    expect(result, isEmpty);
  });
}
```

### Integration Testing

Integration tests use Flutter's `integration_test` package and run on a real device or emulator.

```bash
# Run a specific integration test
flutter test integration_test/expense_flow_test.dart

# Run all integration tests
flutter test integration_test/

# Run on a specific device
flutter test integration_test/ -d emulator-5554
```

Example integration test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket_ledger/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add expense end-to-end', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_expenses')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_expense_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount_field')), '50.00');
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    expect(find.text('50.00'), findsOneWidget);
  });
}
```

### Widget Testing

Widget tests render individual screens without a device — fast and suitable for CI.

```bash
flutter test test/widget/
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_ledger/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard shows summary cards', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );
    expect(find.text('Total Balance'), findsOneWidget);
  });
}
```

### Performance Testing

```bash
# Profile mode — close to release performance, no debug overhead
flutter run --profile

# Record startup trace
flutter run --profile --trace-startup
```

Open DevTools' **Performance** tab to inspect frame timings. Target: all frames under 16 ms (60 fps) or 8 ms (120 fps).

Key areas to profile:
- Dashboard chart rendering (fl_chart with large datasets)
- Transaction list scrolling (ensure `ListView.builder` not `ListView`)
- Database queries (add indexes in `database_helper.dart` for frequently queried columns)

### Security Testing

```bash
# Static analysis
flutter analyze

# Dependency vulnerability scan
flutter pub audit

# Check for outdated packages
flutter pub outdated
```

Manual checks:
- Confirm biometric data never leaves the device (`local_auth` is local-only).
- Confirm encryption keys are stored in `flutter_secure_storage` (backed by Android Keystore).
- Confirm backup files are encrypted before being written to external storage.
- Confirm no personally identifiable information is logged in release builds.

### Common Testing Commands

```bash
flutter test                          # all unit + widget tests
flutter test --coverage               # with coverage report
flutter test integration_test/        # integration tests on device
flutter analyze                       # static analysis
flutter pub audit                     # dependency vulnerability scan
dart run build_runner test            # generated code tests
```

---

## 4. Production Build Process

### Build Configurations

Flutter has three build modes:

| Mode | Command | Use case |
|---|---|---|
| Debug | `flutter build apk --debug` | Development, hot reload |
| Profile | `flutter build apk --profile` | Performance profiling |
| Release | `flutter build apk --release` | Production distribution |

### Release Mode Setup

Before building for release:

1. **Remove debug flags** — verify `main.dart` has no `debugPrint` or `kDebugMode` blocks that log sensitive data.
2. **Set production API keys** — Google Sign-In Client ID, ML Kit, etc.
3. **Configure signing** (see section 5).
4. **Set version** in `pubspec.yaml`:
   ```yaml
   version: 1.2.0+5   # versionName+versionCode
   ```

### Environment Variables / Build Flavors

The project currently uses a single flavor. For multi-environment support, use `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_CLIENT_ID=your_client_id \
  --dart-define=ENVIRONMENT=production
```

Read in Dart:

```dart
const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'debug');
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
```

### Optimizing Build Size

**Enable minification and resource shrinking** in [android/app/build.gradle](android/app/build.gradle):

```groovy
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**Split by ABI** — reduces download size by ~50% by shipping separate APKs per CPU architecture:

```bash
flutter build apk --release --split-per-abi
# Produces:
#   app-arm64-v8a-release.apk    (modern phones)
#   app-armeabi-v7a-release.apk  (older phones)
#   app-x86_64-release.apk       (emulators)
```

**Use App Bundle** for the Play Store — Google handles ABI/language splitting automatically:

```bash
flutter build appbundle --release
```

**Optimize assets** — convert large PNGs in `assets/images/` to WebP where possible.

### Build Commands Reference

```bash
# Debug APK
flutter build apk --debug

# Release APK (single fat APK)
flutter build apk --release

# Release APKs split by ABI (smaller per-device downloads)
flutter build apk --release --split-per-abi

# App Bundle (required for Play Store)
flutter build appbundle --release

# Output locations:
#   APK:    build/app/outputs/flutter-apk/app-release.apk
#   Bundle: build/app/outputs/bundle/release/app-release.aab
```

### Error Handling in Release Builds

Configure a global error handler in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to crash reporting service here
  };

  // Catch async errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log to crash reporting service here
    return true;
  };

  runApp(const ProviderScope(child: PocketLedgerApp()));
}
```

---

## 5. Android Release

### Creating a Keystore

You need a keystore to sign your release APK/AAB. **Keep the keystore file and passwords secure — losing them means you cannot publish updates to the Play Store.**

```bash
keytool -genkey -v \
  -keystore ~/pocket_ledger_release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias pocket_ledger
```

You will be prompted for keystore password, key password, and your name/organization/country.

Store the `.jks` file **outside the repository**. Add `*.jks` and `key.properties` to `.gitignore`.

### Signing Configuration

**Step 1** — Create `android/key.properties` (add to `.gitignore`):

```properties
storePassword=<your_keystore_password>
keyPassword=<your_key_password>
keyAlias=pocket_ledger
storeFile=C:/Users/<you>/pocket_ledger_release.jks
```

**Step 2** — Reference it in [android/app/build.gradle](android/app/build.gradle):

```groovy
// Add this block BEFORE the android {} block:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias     keystoreProperties['keyAlias']
            keyPassword  keystoreProperties['keyPassword']
            storeFile    keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release   // was signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Step 3** — Build signed bundle:

```bash
flutter build appbundle --release
```

### Version Code / Version Name Management

Controlled in a single place — `pubspec.yaml`:

```yaml
version: 1.2.0+5
#        ^^^^^  versionName (shown to users in Play Store)
#              ^ versionCode (integer, must strictly increment with each upload)
```

Gradle reads these automatically via `flutter.versionCode` and `flutter.versionName`.

Rules:
- `versionCode` must be a strictly increasing integer with each Play Store upload.
- Never reuse a `versionCode`, even if you unpublish a release.
- `versionName` is the human-readable string (Semantic Versioning: MAJOR.MINOR.PATCH recommended).

### ProGuard / R8 Rules

Create `android/app/proguard-rules.pro`:

```proguard
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# SQLite / sqflite
-keep class com.tekartik.sqflite.** { *; }

# WorkManager (background backup)
-keep class androidx.work.** { *; }

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.** { *; }

# ML Kit OCR
-keep class com.google.mlkit.** { *; }

# Gson (used by some plugins internally)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
```

After adding ProGuard, run the release build and test all features — missing keep rules cause `ClassNotFoundException` at runtime that only appear in release mode.

### Verifying the Signed Build

```bash
# Verify APK signature and print certificate info
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. Google Play Store Deployment

### Creating a Google Play Console Account

1. Go to https://play.google.com/console
2. Sign in with a Google account.
3. Pay the one-time $25 registration fee.
4. Accept the Developer Distribution Agreement.
5. Complete your developer profile (name, email, phone number).

### Creating the App Listing

1. In Play Console, click **Create app**.
2. Fill in:
   - **App name**: PocketLedger
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Accept the content guidelines and click **Create app**.

### App Content Declarations

Complete these under **Policy > App content**:

- **Privacy Policy URL** — required. Host a policy page (see below).
- **Ads** — declare whether the app shows ads (PocketLedger: No).
- **App access** — all features accessible without credentials, or provide test credentials.
- **Content rating** — complete the questionnaire. Expected rating: Everyone (financial utility app).
- **Target audience** — declare 18+ (financial data app).
- **Data safety section** — declare what data you collect:
  - Financial info (user-entered expenses, income, loans)
  - App activity (if crash reporting is enabled)
  - Device identifiers (for push notifications)
  - Data is not shared with third parties (if true)
  - User can request data deletion (required)

### Privacy Policy

A privacy policy is mandatory for all Play Store apps. Minimum required content:

- What data is collected and why (expenses, contacts, SMS for auto-parsing, camera for OCR).
- Where data is stored (local SQLite database on device; Google Drive if sync is enabled).
- How long data is retained.
- How users can delete their data.
- Contact email address.

Host as a static page (GitHub Pages, Notion, your own website) and paste the URL in Play Console.

### Screenshots and Assets

| Asset | Required dimensions | Notes |
|---|---|---|
| App icon | 512 x 512 px PNG | No rounded corners, no transparency |
| Feature graphic | 1024 x 500 px JPG or PNG | Shown at top of listing |
| Phone screenshots | Min 2, max 8; min 320px short side, 16:9 or 9:16 | Required |
| 7-inch tablet screenshots | Optional | Recommended |
| 10-inch tablet screenshots | Optional | Recommended |

Capture screenshots from the emulator:

```bash
# Save current screen to file
adb exec-out screencap -p > screenshot_01.png
```

Or use Android Studio Device Mirror (right-click emulator > Screenshot).

### Uploading the App Bundle

1. Play Console > your app > **Release > Production** (or start with Internal testing).
2. Click **Create new release**.
3. Upload `build/app/outputs/bundle/release/app-release.aab`.
4. Add release notes (What's new) for each supported language: English, Arabic, Hindi.
5. Click **Review release** then **Start rollout**.

### Testing Tracks

| Track | Who can install | Use case |
|---|---|---|
| **Internal testing** | Up to 100 testers (email allowlist) | Developer / QA team |
| **Closed testing (Alpha)** | Invite-only groups | Beta testers |
| **Open testing (Beta)** | Any Play Store user who opts in | Public beta |
| **Production** | All Play Store users | Full release |

Always start with **Internal testing** before promoting to production. This lets you catch critical bugs before they affect real users.

**Staged production rollout**:
1. Start at 10% rollout percentage.
2. Monitor Android Vitals for crash rate and ANR rate (aim for < 1%).
3. Expand to 50%, then 100% over several days if metrics stay healthy.
4. Use **Halt rollout** immediately if crash rate spikes.

---

## 7. CI/CD Automation

### GitHub Actions — Build and Test

Create `.github/workflows/flutter.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze

      - name: Unit tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info

  build-apk:
    name: Build APK
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Build debug APK
        run: flutter build apk --debug

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: debug-apk
          path: build/app/outputs/flutter-apk/app-debug.apk
```

### GitHub Actions — Signed Release + Play Store Upload

Create `.github/workflows/release.yml`. Triggers on version tags (e.g., `git tag v1.2.0+5 && git push --tags`):

```yaml
name: Release to Play Store

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/release.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.STORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=release.jks
          EOF

      - name: Build App Bundle
        run: flutter build appbundle --release

      - name: Upload to Play Store (Internal track)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.pocketledger.pocket_ledger
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed
```

**Required GitHub Secrets**:

| Secret | How to generate |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w 0 pocket_ledger_release.jks` |
| `STORE_PASSWORD` | Your keystore password |
| `KEY_PASSWORD` | Your key password |
| `KEY_ALIAS` | Your key alias (e.g., `pocket_ledger`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON key from Google Cloud Console service account |

**Creating a Play Store Service Account**:

1. Play Console > Setup > API access > Link to Google Cloud project.
2. Google Cloud Console > IAM & Admin > Service Accounts > Create service account.
3. Grant the **Release Manager** role (or a custom role with `androidpublisher` API permissions).
4. Create a JSON key for the service account and download it.
5. Paste the full JSON content as the `PLAY_SERVICE_ACCOUNT_JSON` secret.

### Integration Tests in CI

Use `macos-latest` runners for Android integration tests — macOS GitHub-hosted runners support hardware-accelerated Android emulators:

```yaml
  integration-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'

      - name: Install dependencies
        run: flutter pub get

      - name: Run integration tests on emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          arch: x86_64
          script: flutter test integration_test/
```

---

## 8. Troubleshooting

### Common Build Errors

**`Could not move temporary workspace to immutable location`**

Gradle's transform-cache atomic rename fails due to Windows Defender file locking on newly downloaded JARs.

Fix:
1. Add your Gradle cache directory to Windows Defender exclusions (e.g., `D:\GradleCache`).
2. In `android/gradle.properties`, set:
   ```properties
   org.gradle.parallel=false
   org.gradle.workers.max=1
   org.gradle.vfs.watch=false
   ```
3. If specific transforms still fail every run, manually complete the rename after a failed build:
   ```powershell
   # Find leftover temp directories
   Get-ChildItem "D:\GradleCache\caches\8.11.1\transforms" -Directory |
     Where-Object { $_.Name -like "<hash>-*" }

   # Move the most recent temp dir to the final immutable location
   Move-Item "D:\GradleCache\caches\8.11.1\transforms\<hash>-<uuid>" `
             "D:\GradleCache\caches\8.11.1\transforms\<hash>"
   ```

**`Minimum supported Gradle version is X.Y.Z. Current version is A.B.C`**

The Android Gradle Plugin version requires a newer Gradle wrapper.

Fix: Update `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-all.zip
```

**`checkDebugAarMetadata: requires Android Gradle Plugin X.Y.Z or higher`**

A transitive dependency requires a newer AGP.

Fix: Update `android/settings.gradle`:
```groovy
id "com.android.application" version "8.9.1" apply false
```

**`flutter_local_notifications requires core library desugaring`**

Fix: In `android/app/build.gradle`:
```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

**`The imperative apply() method cannot be used with the Gradle plugins DSL`**

Old `apply plugin:` syntax incompatible with Flutter 3.41.9.

Fix: Migrate `android/app/build.gradle` to declarative plugins block:
```groovy
// Remove old-style:
// apply plugin: 'com.android.application'
// apply plugin: 'kotlin-android'
// apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

// Use new declarative style:
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}
```

**`intl version conflict`**

Flutter SDK requires `intl 0.20.x` but `pubspec.yaml` pins `^0.19.0`.

Fix: In `pubspec.yaml`:
```yaml
intl: ^0.20.2
```

**`Error parsing AndroidManifest.xml` / unknown namespace `tools`**

The manifest uses `tools:node` without declaring the namespace.

Fix: Add namespace to the root element of `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
```

**`java.lang.OutOfMemoryError` / JVM crash**

Gradle JVM heap is too large for available RAM.

Fix: In `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m
```
Also: stop the Android emulator during builds — it consumes 1–2 GB of RAM.

**C: drive full during build**

Gradle downloads gigabytes of dependencies.

Fix:
```powershell
$env:GRADLE_USER_HOME = "D:\GradleCache"
$env:TEMP = "D:\FlutterTemp"
$env:TMP  = "D:\FlutterTemp"
```
Set these before running any `flutter` command.

### Signing Issues

**`keystore file not found`**

The `storeFile` path in `key.properties` doesn't exist.

Fix: Verify the path and escape backslashes (use `C:\\Users\\...` or forward slashes `C:/Users/...`).

**`SignatureException: Signature length not correct`**

Wrong key alias or mismatched passwords.

Fix: Re-check `keyAlias`, `storePassword`, and `keyPassword` against the values used when running `keytool -genkey`.

**Release build still signed with debug key**

Fix: Ensure `android/app/build.gradle` references `signingConfigs.release` not `signingConfigs.debug`:
```groovy
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

### Play Store Rejection Fixes

**Dangerous permissions policy violation**

`READ_SMS` and `RECEIVE_SMS` require approval. Google requires a **Core Functionality Declaration** and a demo video showing that SMS parsing is the primary feature.

Fix: In Play Console > App content > Sensitive Permissions, explain the SMS auto-categorization use case and upload a screenshare video.

**Target API level too low**

Play Store requires new apps to target the latest API.

Fix: In `android/app/build.gradle`:
```groovy
defaultConfig {
    targetSdk 36
}
```

**Missing privacy policy**

Fix: Host a privacy policy page and add the URL in Play Console > App content > Privacy policy.

**APK uploaded instead of AAB**

Play Store requires AAB for new apps since August 2021.

Fix: Use `flutter build appbundle --release` and upload the `.aab` file.

**App crashes immediately on launch**

Often caused by ProGuard stripping classes needed at runtime.

Fix:
1. Build with `minifyEnabled false` temporarily to confirm ProGuard is the cause.
2. Add missing `-keep` rules to `proguard-rules.pro`.
3. Re-enable minification.
4. Use `adb logcat` to find the `ClassNotFoundException` or `NoSuchMethodError`.

### Crash Analysis

**Android Vitals in Play Console**

Play Console > Android vitals > Crashes & ANRs shows crash reports from users. Upload the ProGuard mapping file so stack traces are human-readable:

- File: `build/app/outputs/mapping/release/mapping.txt`
- Upload in: Play Console > Release > App bundle explorer > select release > Artifacts

**Reproducing crashes locally**

```bash
# Run in release mode to reproduce production-only crashes
flutter run --release

# Watch device logs in real time
adb logcat -s flutter PocketLedger 2>/dev/null
```

**Firebase Crashlytics** (recommended for proactive crash monitoring)

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_crashlytics: ^4.0.0
```

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const ProviderScope(child: PocketLedgerApp()));
}
```

---

## Quick Reference

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter doctor -v

# Run
flutter run                           # debug on connected device/emulator
flutter run --profile                 # performance profiling
flutter run -d emulator-5554         # specific device
flutter devices                       # list available devices

# Test
flutter test                          # unit + widget tests
flutter test --coverage               # with coverage report
flutter test integration_test/        # integration tests (device required)
flutter analyze                       # static analysis
flutter pub audit                     # dependency vulnerability scan

# Build
flutter build apk --debug             # debug APK
flutter build apk --release           # release fat APK
flutter build apk --release --split-per-abi   # split APKs (smaller)
flutter build appbundle --release     # release AAB (Play Store)

# Utilities
flutter clean                         # clear build artifacts
flutter pub upgrade --major-versions  # upgrade all deps
flutter pub outdated                  # show outdated packages
```
