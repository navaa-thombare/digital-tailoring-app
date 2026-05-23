# Digital Tailoring

Flutter Android app modeled after the sample tailoring APK in `D:\application-development\vercel-app-building\sample`.

The active app experience now focuses on a tailoring shop workflow:

- Onboarding with owner setup and shop capacity
- Login and biometric-login entry points
- Owner dashboard with shop load, orders, customers, and revenue metrics
- Order creation and editing with customer selection, measurements, priority, payment mode, and status
- Customer list, search, creation, and measurement notes
- Garment template creation and field management
- Shop profile, timings, capacity, password, and privacy entry points

## Project Setup

```powershell
cd d:\application-development\vercel-app-building\flutter-app-vscode
C:\src\flutter\bin\flutter.bat pub get
```

## Environments

The Android project has two flavors:

| Flavor | Use | Configuration |
| --- | --- | --- |
| `dev` | Local Android emulator and development testing | `config/dev.json` and `config/owner.json` |
| `prod` | Signed store release connected to Supabase | `config/prod.json` |

Configuration files are excluded from Git. Create them from the templates in
`config/`, or convert the existing ignored `.env` file:

```powershell
.\tool\create_local_config_from_env.ps1
```

The `.env` file is no longer bundled in the APK. Production uses the Supabase
project URL and publishable key supplied at build time. Never add a Supabase
secret or service-role key to either configuration file. The conversion script
keeps the development configuration local-only; add a separate development
Supabase project manually if cloud integration testing is required.

For the development build, copy `config/owner.example.json` to the ignored
`config/owner.json` file and enter the predefined owner's name, shop name,
phone number, shop address and default first-login password. The phone number
is the owner's login username. The owner must reset the configured default
password after the first successful login; the changed password is stored
securely on the emulator/device.

## Run Dev On Android

```powershell
.\tool\run_dev.ps1 -Device emulator-5554
```

This installs `Digital Tailoring Dev` alongside a production installation.

## Supabase Production Backend

The initial schema and Row Level Security policies are in
`supabase/migrations/202605230001_initial_tailoring_schema.sql`. Apply that
migration to the Supabase project before connecting production screens to cloud
data. It implements one owner shop, one active shop per worker, multi-role
memberships, and shop-scoped tailoring records.

## Build Production APK For USB Install

Before the first store release, choose the permanent Android `applicationId` in
`android/app/build.gradle.kts`, generate an upload keystore, and create
`android/key.properties` from `android/key.properties.example`.

```powershell
.\tool\build_prod.ps1
```

The signed release APK is generated at:

```text
build\app\outputs\flutter-apk\app-prod-release.apk
```

Install the release APK on a connected Android device over USB:

```powershell
adb install -r .\build\app\outputs\flutter-apk\app-prod-release.apk
```

Back up `android/digital-tailoring-release.jks` and
`android/key.properties` securely. Future upgrades of the installed app must
be signed with the same keystore.

## Verification

Verified in this workspace:

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat build apk --debug --flavor dev --dart-define-from-file=config/dev.json --dart-define-from-file=config/owner.json
```
