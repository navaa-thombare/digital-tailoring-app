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

## Run

```powershell
C:\src\flutter\bin\flutter.bat run
```

## Build Android APK

```powershell
C:\src\flutter\bin\flutter.bat build apk --debug
```

The debug APK is generated at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Verification

Verified in this workspace:

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat build apk --debug
```
