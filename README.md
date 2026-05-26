# Open VTS 2026

Open VTS is an open-source mobile application codebase. This repository contains the Flutter starter built for the OpenVTS mobile application.

- Website: https://openvts.io

This boilerplate follows the agreed Phase 1 architecture:

```text
UI Screen
  -> Riverpod Controller / Provider
    -> Role-wise Service
      -> Central ApiClient
        -> Dio + Backend API
```

## Architecture choice

This is intentionally **not heavy Clean Architecture** and **not MVC**.

It uses:

- centralized API calling
- centralized API endpoints
- centralized token storage
- role-wise business logic
- role-wise screens
- shared OpenVTS widgets
- Riverpod for state management
- GoRouter for route and role guards
- OpenVTS theme tokens for consistent UI

## Folder philosophy

```text
lib/core      = app foundation: API, router, storage, theme, errors
lib/shared    = reusable widgets, models, helpers
lib/features  = auth + role modules: superadmin, admin, user
```


## Environment setup

Configuration is supplied via `--dart-define` flags at build/run time.
No `.env` file is bundled as a Flutter asset.

For local development, copy the example file as a reference:

```bash
cp .env.example .env   # local reference only — has no effect on the build
```

**Default values** (used when no `--dart-define` flags are passed):

| Key | Default |
|-----|---------|
| `API_BASE_URL` | `https://app.openvts.io/api` |
| `USE_MOCK_DATA` | `true` |

Mock mode is on by default so the app runs without a backend on first checkout.

To run against the real backend:

```bash
flutter run \
  --dart-define=USE_MOCK_DATA=false
```

To run against a local backend:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000/api \
  --dart-define=USE_MOCK_DATA=false
```

## Run

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:3000/api \
  --dart-define=USE_MOCK_DATA=true
```

For real backend mode:

```bash
flutter run -d chrome
```

## Demo login in mock mode

Use any email/password. Role is detected from email text:

- `superadmin@openvts.com` -> superadmin
- `admin@openvts.com` -> admin
- anything else -> user

## Important rules

Do not call Dio directly from screens.
Do not store token logic inside screens.
Do not create random button/text/card styles.
Do not hardcode colors inside screens.
Do not mix role logic randomly.
Do not place all business logic in one giant file.

## Phase 1 includes

- App bootstrap
- Theme system
- Central API client
- Central endpoints
- Auth interceptor
- Token storage
- Refresh-token interceptor placeholder
- Role-based routing
- Role shells
- Auth screens
- Superadmin dashboard/vehicles/map/settings sample
- Admin dashboard/vehicles/map/settings sample
- User dashboard/vehicles/map/notifications/settings sample
- Shared UI widgets
- Basic mock mode

## Next implementation steps

1. Replace placeholder endpoints with exact backend endpoints.
2. Replace mock services with live response parsing.
3. Add real response models for each page.
4. Add FCM registration after login.
5. Add Socket.IO telemetry pipeline for live map.
6. Add role permission checks if backend exposes granular permissions.
7. Add tests for API client, auth controller, and role guards.
