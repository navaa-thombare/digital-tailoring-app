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
| `prod` | Signed store release connected to Supabase | `config/prod.json` and `config/owner.json` |

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
securely on the emulator/device. After the new owner password has been used
successfully, the installed app restores the owner session without asking for
the password again. Selecting Logout clears that saved session. This behavior
is enabled for both `dev` and `prod` builds.

## Run Dev On Android

```powershell
.\tool\run_dev.ps1 -Device emulator-5554
```

This installs `Digital Tailoring Dev` alongside a production installation.
The initial launch animation is displayed for 5 seconds.

Build an installable dev APK without launching an emulator:

```powershell
.\tool\build_dev.ps1
```

The dev APK is generated at:

```text
build\app\outputs\flutter-apk\app-dev-debug.apk
```

## Automatic WhatsApp Messages

Owner settings include:

- **WhatsApp Templates** for Marathi new-order, work-started, and
  ready-for-pickup messages.
- **WhatsApp API Configuration** for Meta Graph API version, WhatsApp phone
  number ID, permanent access token, and sender name.
- **WhatsApp Message History** for customer, date, message type, status,
  template, rendered message, provider ID, and errors.

Creating an order queues the `Order` message. The first worker assignment with
`In Stitching` status queues the `In Progress` message. The first transition
where every ordered unit is `Ready` queues the `Delivery` message. Each event is
stored once per order, so later edits do not send duplicates. If automatic API
sending is disabled, incomplete, or rejected, the app offers to open WhatsApp
with the Marathi message prefilled. Held and failed messages can also be opened
manually or retried through the API from message history.

The current mobile integration calls Meta WhatsApp Cloud API directly and keeps
the access token in Android secure storage. For production, put this call behind
a shop-owned backend so permanent Meta credentials are not distributed to
mobile devices. Meta may reject free-text business messages outside its
customer-service window; production business-initiated messages should use
Meta-approved WhatsApp templates.

## Supabase Production Backend

The initial schema and Row Level Security policies are in
`supabase/migrations/202605230001_initial_tailoring_schema.sql`. Apply that
migration to the Supabase project before connecting production screens to cloud
data. It implements one owner shop, one active shop per worker, multi-role
memberships, and shop-scoped tailoring records.

The current tailoring UI uses an offline-first state snapshot so all existing
fields remain compatible while the normalized schema is adopted incrementally:

- SQLite `tailoring_state_cache` keeps data after restarts and when offline.
- Supabase `tailoring_app_state` stores one revisioned JSON snapshot per shop.
- Supabase Realtime broadcasts state changes to other owner devices.
- Row Level Security limits the snapshot to active shop members.

Apply both migrations in order:

```text
supabase/migrations/202605230001_initial_tailoring_schema.sql
supabase/migrations/202606130001_realtime_tailoring_state.sql
supabase/migrations/202606140001_clear_shop_data.sql
```

In Supabase Authentication, enable Email/Password login. For private
owner-only provisioning, disable Confirm email or provide a real
`OWNER_AUTH_EMAIL` that can receive confirmation. The first production login
uses the configured default password and then creates the Supabase owner
account when the owner chooses a new password. Additional owner devices sign in
with the same owner email and changed password, download the shop snapshot, and
subscribe to Realtime updates.

Worker credentials are intentionally not included in the shared snapshot.
Production multi-device worker login requires separate Supabase Auth users and
`shop_memberships`; the migration already contains that authorization model.

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

## Jenkins Dev APK Publication

The root `Jenkinsfile` builds the installable `dev` debug APK from the Gitea
`dev` branch and publishes it to a Nexus raw hosted repository. It is written
for the local Linux Jenkins container in this CI stack.

Prerequisites on the Jenkins agent:

- Docker CLI access and the mounted Docker socket are available.
- `python3` and `curl` are available in the Jenkins container.
- The Flutter Android build image `ghcr.io/cirruslabs/flutter:stable` can be
  pulled by Docker.
- A Nexus raw hosted repository named `mobile-apps` exists, or set the
  `NEXUS_RAW_REPOSITORY` build parameter to the configured raw repository.

Create these Jenkins credentials:

| Credential ID | Type | Use |
| --- | --- | --- |
| `digital-tailoring-dev-owner-default-password` | Secret text | Test-only owner first-login password built into the dev APK |
| `nexus-admin` | Username with password | Nexus upload access |

The default `NEXUS_URL` is `http://local-nexus:8081`, the hostname exposed to
Jenkins on the Docker network. The pipeline accepts the Nexus URL and
owner/shop values as build parameters, generates ignored `config/dev.json`
and `config/owner.json` only inside the Jenkins workspace, runs analysis and
the APK build inside the Flutter SDK container, uploads the APK, and then
deletes those generated config files.

With the default repository name, the uploaded artifact path is:

```text
/repository/mobile-apps/digital-tailoring/dev/<version>/digital-tailoring-dev-<version>-build-<build-number>.apk
```

The password in a dev APK is only a test bootstrap password; do not reuse a
production owner password as a Jenkins development credential.

## Verification

Verified in this workspace:

```powershell
C:\src\flutter\bin\flutter.bat analyze
.\tool\build_dev.ps1
```
