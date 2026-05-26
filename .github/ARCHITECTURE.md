# OpenVTS Mobile Architecture

## Name

Simple Role-Based Layered Architecture.

## Flow

```text
Screen
  -> Riverpod Controller / Provider
    -> Role Service
      -> Central ApiClient
        -> Dio
          -> Backend
```

## Core decisions

- API calling is centralized in `core/api/api_client.dart`.
- API endpoints are centralized in `core/api/api_endpoints.dart`.
- Token storage is centralized in `core/storage/token_storage.dart`.
- App toast feedback is centralized in `shared/helpers/toast_helper.dart` through a global `ScaffoldMessenger` key.
- Business logic is role-wise under `features/{role}/services`.
- State is handled through Riverpod controllers/providers.
- UI reuses `shared/widgets` first.
- Role screens stay inside their own role module.
- Role home routes act as launcher pages with a shared top bar, brand area, desktop-icon grid, footer, theme toggle, and profile logout menu.
- New shared UI should default to a compact/minimal visual density: smaller typography, tighter heights, and controlled spacing before adding decorative space.

## UI density rule

- Default new components to a compact/minimal footprint.
- Prefer smaller theme text styles like `titleSmall`, `body`, and `label` unless a screen is intentionally a hero or brand moment.
- Prefer compact heights and controls such as ~56px page headers and dense action buttons before increasing size.
- Prefer `OpenVtsSpacing.sm` to `OpenVtsSpacing.md` for dense page padding and only grow padding/margins when the content needs it.
- Avoid oversized one-off font sizes, padding, margins, header heights, and empty whitespace in normal product screens.

## Folder rules

### core

Use for app-wide infrastructure only.

Examples:

- API client
- endpoint constants
- interceptors
- router
- theme
- storage
- error mapping
- config

### shared

Use for reusable pieces that are not role-specific.

Examples:

- OpenVTS buttons
- OpenVTS cards
- loaders
- error views
- common models
- UI helpers

### features

Use for role and feature screens.

Examples:

- auth
- superadmin
- admin
- user

## Anti-rules

- No Dio calls inside screens.
- No token reads inside screens.
- No hardcoded colors inside screens.
- No role-mixed business logic.
- No huge all-in-one service file.
- No screen that parses raw complex backend JSON directly.


## Environment configuration

The app reads API configuration from `.env` through `flutter_dotenv`.

```env
API_BASE_URL=https://app.openvts.io/api
USE_MOCK_DATA=false
```

`AppConfig.apiBaseUrl` is the single source used by Dio. Do not hardcode API URLs in screens, services, or controllers.
