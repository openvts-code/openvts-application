# OpenVTS Flutter Project Architecture Guide

**Project:** OpenVTS Mobile Application  
**Document purpose:** This file is the development standard for the OpenVTS Flutter app. Use it as the primary reference before adding screens, APIs, services, widgets, themes, routes, or role-based modules.

---

## 1. Core Direction

OpenVTS Flutter must be simple, clean, maintainable, and aligned with the existing OpenVTS web application.

We are **not** using heavy Clean Architecture for every small screen.  
We are **not** using pure MVC.  
We are using a practical, role-based structure:

```text
Screen / Widget
  -> Riverpod Controller / Provider
    -> Role-wise Service / Business Logic
      -> Central ApiClient
        -> Dio
          -> Backend API
```

### Final Architecture Name

```text
OpenVTS Simple Role-Based Layered Architecture
```

### Why this architecture

This app has three major role areas:

- Superadmin
- Admin
- User

The app should remain easy to understand. A developer should open the project and quickly know:

- where API endpoints are defined
- where token handling happens
- where shared UI components live
- where each role's screens live
- where each role's business logic lives
- how data flows from backend to UI

---

## 2. Non-Negotiable Development Rules

### Must follow

```text
Centralize all API calls through core/api/api_client.dart.
Centralize all endpoint paths through core/api/api_endpoints.dart.
Use Riverpod for state management.
Use role-wise service files for business logic.
Use shared widgets for reusable UI.
Use OpenVTS theme tokens for colors, typography, spacing, and radius.
Use .env for API_BASE_URL.
Keep screens focused on rendering UI and sending user actions to controllers.
Keep role folders separate: auth, superadmin, admin, user.
Keep common widgets in shared/widgets.
Keep screen-specific widgets close to the screen.
```

### Must avoid

```text
Do not call Dio directly from screens.
Do not put token logic inside screens.
Do not hardcode API URLs inside services or screens.
Do not hardcode colors inside screens.
Do not create random button/card/input styles per screen.
Do not put all business logic in one giant file.
Do not mix superadmin/admin/user logic randomly.
Do not parse complex raw API maps directly in widgets.
Do not use setState for API loading/data/error flows.
Do not add unnecessary architecture layers unless the feature genuinely needs it.
```

---

## 3. Environment Configuration

The Flutter app must use a `.env` file.

### Required `.env`

```env
API_BASE_URL=https://app.openvts.io/api
USE_MOCK_DATA=false
```

### Location

```text
.env
.env.example
```

### Pubspec asset registration

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/brand/
    - assets/fonts/
    - assets/images/
    - .env
```

### Package name and import contract

`pubspec.yaml` package name must remain:

```text
open_vts
```

Internal absolute imports must use the same package prefix:

```dart
import 'package:open_vts/app.dart';
import 'package:open_vts/bootstrap.dart';
```

Do not rename the pubspec package without updating internal `package:open_vts/...` imports in the same change.

### Bootstrap rule

`lib/bootstrap.dart` must load `.env` before running the app callback supplied by `main.dart`.

```dart
Future<void> bootstrap(Future<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await runApp();
}
```

### Startup entry rule

Startup flow is intentionally split into a small pre-app pipeline:

```text
main.dart
  -> create startup dependencies such as SharedPreferences
  -> bootstrap.dart
    -> load .env
    -> run App
      -> app_entry.dart
        -> OnboardingScreen on first launch
        -> SplashScreen after onboarding
```

Rules:

```text
main.dart owns pre-runApp dependency hydration.
app.dart owns the MaterialApp shell.
app_entry.dart is the pre-router gate for onboarding vs splash.
Do not bury onboarding-completion checks in random role screens.
```

### Platform support rule

Flutter Web preview is a supported target for this repository.

Required generated platform folder:

```text
web/
```

If Chrome builds fail with "This application is not configured to build on the web", restore support with:

```text
flutter create . --platforms=web
```

Commit the generated `web/` folder so web preview remains available.

### AppConfig rule

`lib/core/config/app_config.dart` is the only place that reads environment values.

```dart
class AppConfig {
  const AppConfig._();

  static const appName = 'OpenVTS';

  static String get apiBaseUrl {
    final envValue = dotenv.env['API_BASE_URL'];
    if (envValue != null && envValue.trim().isNotEmpty) {
      return envValue.trim();
    }

    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api',
    );
  }

  static bool get useMockData {
    final envValue = dotenv.env['USE_MOCK_DATA'];
    if (envValue != null && envValue.trim().isNotEmpty) {
      return envValue.trim().toLowerCase() == 'true';
    }

    return const bool.fromEnvironment(
      'USE_MOCK_DATA',
      defaultValue: true,
    );
  }

  static const connectTimeoutSeconds = 20;
  static const receiveTimeoutSeconds = 30;
}
```

### Important security rule

`.env` in Flutter is not secure for private secrets. It is acceptable for public configuration such as:

```text
API_BASE_URL
USE_MOCK_DATA
APP_ENV
```

Never place these inside Flutter `.env`:

```text
JWT secret
Database password
Private backend key
Firebase service account JSON
Server secret
Payment gateway secret
```

---

## 4. Final Folder Structure

```text
lib/
├── main.dart
├── bootstrap.dart
├── app.dart
├── app_entry.dart
│
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   ├── api_response.dart
│   │   ├── api_exception.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       ├── refresh_token_interceptor.dart
│   │       ├── error_interceptor.dart
│   │       └── logging_interceptor.dart
│   │
│   ├── config/
│   │   ├── app_config.dart
│   │   └── app_constants.dart
│   │
│   ├── errors/
│   │   ├── app_error.dart
│   │   └── error_mapper.dart
│   │
│   ├── providers/
│   │   └── core_providers.dart
│   │
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_paths.dart
│   │
│   ├── socket/
│   │   └── socket_service.dart
│   │
│   ├── storage/
│   │   ├── storage_keys.dart
│   │   ├── token_storage.dart
│   │   └── local_cache.dart
│   │
│   ├── theme/
│   │   ├── open_vts_colors.dart
│   │   ├── open_vts_spacing.dart
│   │   ├── open_vts_radius.dart
│   │   ├── open_vts_typography.dart
│   │   └── open_vts_theme.dart
│   │
│   └── utils/
│       ├── date_time_formatter.dart
│       ├── validators.dart
│       └── permission_helper.dart
│
├── shared/
│   ├── helpers/
│   │   └── toast_helper.dart
│   │
│   ├── models/
│   │   ├── api_result.dart
│   │   ├── pagination_model.dart
│   │   ├── user_role.dart
│   │   └── vehicle_summary.dart
│   │
│   └── widgets/
│       ├── open_vts_button.dart
│       ├── open_vts_card.dart
│       ├── open_vts_text_field.dart
│       ├── open_vts_page_scaffold.dart
│       ├── open_vts_loader.dart
│       ├── open_vts_empty_state.dart
│       ├── open_vts_error_view.dart
│       ├── open_vts_status_chip.dart
│       ├── open_vts_search_field.dart
│       ├── open_vts_metric_card.dart
│       ├── vehicle_card.dart
│       ├── open_vts_map_preview.dart
│       └── placeholder_role_screen.dart
│
└── features/
    ├── auth/
    │   ├── controllers/
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    │
  ├── onboarding/
  │   ├── models/
  │   └── presentation/
  │       ├── controllers/
  │       ├── screens/
  │       └── widgets/
  │
    ├── superadmin/
    │   ├── controllers/
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    │
    ├── admin/
    │   ├── controllers/
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    │
    └── user/
        ├── controllers/
        ├── models/
        ├── screens/
        ├── services/
        └── widgets/
```

---

## 5. What Each Folder Means

### `core/`

App-wide foundation. Code here should be used across the entire app.

Use `core/` for:

- API client
- endpoints
- interceptors
- token storage
- router
- theme
- config
- socket base service
- error mapping
- common utilities

Do not place role-specific business logic in `core/`.

---

### `shared/`

Reusable UI and common models.

Use `shared/` for:

- common widgets
- common models
- helper functions
- app-wide UI utilities

Rule:

```text
If a widget is used in 2 or more places, move it to shared/widgets.
If a widget is used only by one screen, keep it near that screen.
```

---

### `features/auth/`

Authentication and session management.

Use for:

- login screen
- forgot password screen
- reset password screen
- splash screen
- session restore
- login API logic
- logout logic
- current user model

---

### `features/onboarding/`

First-launch onboarding and walkthrough flow.

Use for:

- onboarding screen
- onboarding page models
- onboarding-only widgets
- onboarding illustration/copy mapping
- onboarding completion state consumed by `app_entry.dart`

---

### `features/superadmin/`

Superadmin role module.

Use for:

- superadmin dashboard
- superadmin map
- superadmin vehicles
- administrators
- devices
- reports
- settings
- superadmin-specific services
- superadmin-specific controllers

---

### `features/admin/`

Admin role module.

Use for:

- admin dashboard
- admin map
- admin vehicles
- admin users
- drivers
- reports
- settings
- admin-specific services
- admin-specific controllers

---

### `features/user/`

User role module.

Use for:

- user dashboard
- user map
- user vehicles
- history
- notifications
- user settings
- user-specific services
- user-specific controllers

---

## 6. API Calling Architecture

### Central rule

All API requests must go through:

```text
lib/core/api/api_client.dart
```

Screens must never import or use Dio directly.

### API flow

```text
Screen
  -> Riverpod Controller / Provider
    -> Role-wise Service
      -> ApiClient
        -> Dio
          -> Backend API
```

### Example flow

```text
SuperadminVehiclesScreen
  -> superadminVehiclesProvider
    -> SuperadminVehicleService
      -> ApiClient.get(ApiEndpoints.superadmin.vehicles)
        -> Dio GET /superadmin/vehicles
          -> Backend
```

---

## 7. API Endpoints System

All backend endpoint paths must be defined in:

```text
lib/core/api/api_endpoints.dart
```

### Endpoint grouping

```dart
class ApiEndpoints {
  const ApiEndpoints._();

  static const auth = _AuthEndpoints();
  static const superadmin = _SuperadminEndpoints();
  static const admin = _AdminEndpoints();
  static const user = _UserEndpoints();
}
```

### Example usage

```dart
ApiEndpoints.auth.login
ApiEndpoints.superadmin.dashboard
ApiEndpoints.admin.vehicles
ApiEndpoints.user.notifications
```

### Endpoint rules

```text
Do not hardcode endpoints inside screens.
Do not hardcode endpoints inside widgets.
Do not repeat endpoint strings across services.
Group endpoints by role or domain.
Dynamic endpoints should be functions.
```

Example:

```dart
String vehicleDetail(String id) => '/superadmin/vehicles/$id';
```

---

## 8. ApiClient Standard

`ApiClient` should expose basic HTTP methods:

```text
get
post
put
delete
```

Each method must:

- call Dio
- receive backend response
- parse response using parser callback
- return typed `ApiResponse<T>`
- throw or map structured API exceptions

### Example

```dart
Future<ApiResponse<T>> get<T>(
  String endpoint, {
  Map<String, dynamic>? queryParameters,
  required T Function(dynamic json) parser,
}) async {
  final response = await _dio.get<dynamic>(
    endpoint,
    queryParameters: queryParameters,
  );
  return _parseResponse(response, parser);
}
```

---

## 9. API Response Standard

Backend responses should be normalized through:

```text
lib/core/api/api_response.dart
```

The UI should not depend directly on raw backend JSON.

Recommended standard response structure:

```dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T data;
}
```

The exact model can be adjusted according to actual backend response format, but the rule remains:

```text
Raw response -> ApiClient -> ApiResponse<T> -> Service -> Controller -> UI
```

---

## 10. Interceptor Rules

Interceptors live in:

```text
lib/core/api/interceptors/
```

### Required interceptors

```text
auth_interceptor.dart
refresh_token_interceptor.dart
error_interceptor.dart
logging_interceptor.dart
```

### Auth interceptor

Adds access token to every API request.

```text
Authorization: Bearer <accessToken>
```

### Refresh token interceptor

Handles expired access tokens.

Expected flow:

```text
API returns 401
  -> pause retry loop
  -> use refresh token
  -> save new access token
  -> retry original request once
  -> if refresh fails, logout user
```

### Error interceptor

Converts Dio errors into predictable app errors.

### Logging interceptor

Allowed only for safe logs.

Never log:

```text
access token
refresh token
password
OTP
private payloads
sensitive user data
```

---

## 11. Token Storage

Token storage must be centralized in:

```text
lib/core/storage/token_storage.dart
```

Use:

```text
flutter_secure_storage
```

### Store

```text
accessToken
refreshToken
userRole
```

### Login flow

```text
Login screen
  -> AuthController.login()
    -> AuthService.login()
      -> ApiClient.post(ApiEndpoints.auth.login)
        -> save tokens
        -> save role
        -> update AuthState
        -> redirect to role dashboard
```

### App start/session restore flow

```text
App starts
  -> Splash screen
    -> AuthController.restoreSession()
      -> read token
      -> read role
      -> if valid, authenticate user
      -> if invalid, show login
```

### Production improvement

Before production, session restore should call:

```text
/auth/me
```

Reason:

```text
Saved local role can become stale.
Backend should be source of truth for current user and role.
```

### Logout flow

```text
Logout
  -> disconnect socket
  -> clear access token
  -> clear refresh token
  -> clear role
  -> clear user-specific cache if needed
  -> redirect to login
```

---

## 12. State Management

Use:

```text
flutter_riverpod
```

Riverpod is used for:

- auth state
- dashboard state
- vehicle list state
- map state
- notification state
- loading/error/data states
- dependency injection

### Basic rule

Screens watch providers.  
Screens do not directly perform API operations.

Correct:

```dart
final vehiclesState = ref.watch(superadminVehiclesProvider);
```

Wrong:

```dart
final response = await Dio().get('/superadmin/vehicles');
```

### Controller/provider responsibility

A provider/controller should:

- call service methods
- manage loading state
- manage error state
- refresh data
- expose typed data to UI

### UI responsibility

A screen should:

- render loading state
- render error state
- render data state
- send user actions to controller
- not contain API logic

---

## 13. Role-Wise Business Logic

Business logic should be role-wise.

### Superadmin services

```text
features/superadmin/services/
```

Example:

```text
superadmin_dashboard_service.dart
superadmin_vehicle_service.dart
superadmin_map_service.dart
superadmin_admin_service.dart
```

### Admin services

```text
features/admin/services/
```

Example:

```text
admin_dashboard_service.dart
admin_vehicle_service.dart
admin_user_service.dart
admin_driver_service.dart
```

### User services

```text
features/user/services/
```

Example:

```text
user_dashboard_service.dart
user_vehicle_service.dart
user_notification_service.dart
user_history_service.dart
```

### Why role-wise services

This keeps the app simple and clear:

```text
Superadmin logic stays in superadmin.
Admin logic stays in admin.
User logic stays in user.
Common API client stays centralized.
Common UI stays shared.
```

---

## 14. Models

Models should live close to their feature when they are role-specific.

Examples:

```text
features/superadmin/models/superadmin_dashboard_model.dart
features/admin/models/admin_dashboard_model.dart
features/user/models/user_dashboard_model.dart
```

Shared models should live in:

```text
shared/models/
```

Examples:

```text
user_role.dart
api_result.dart
pagination_model.dart
vehicle_summary.dart
```

### Model rules

```text
Use typed models, not raw Map<String, dynamic> in screens.
Use fromJson/toJson methods for API mapping.
Keep parsing inside models/services, not widgets.
If the same model is used across roles, move it to shared/models.
If the model is role-specific, keep it inside that role folder.
```

---

## 15. Routing Architecture

Use:

```text
go_router
```

Router files:

```text
lib/core/router/app_router.dart
lib/core/router/route_paths.dart
```

### Pre-router entry gate

`lib/app_entry.dart` runs before role-based router redirects.

```text
AppEntry
  -> onboarding incomplete -> OnboardingScreen
  -> onboarding complete -> SplashScreen
    -> auth restore
    -> go_router role redirects
```

Onboarding is a pre-auth entry gate, not a role route.

### Route path examples

```text
/login
/splash
/forgot-password

/superadmin/dashboard
/superadmin/map
/superadmin/vehicles
/superadmin/administrators
/superadmin/devices
/superadmin/reports
/superadmin/settings

/admin/dashboard
/admin/map
/admin/users
/admin/vehicles
/admin/drivers
/admin/reports
/admin/settings

/user/dashboard
/user/map
/user/vehicles
/user/history
/user/notifications
/user/settings
```

### Route guard rules

```text
If auth status is loading -> /splash
If user is not authenticated -> /login
If role is superadmin -> allow only /superadmin routes
If role is admin -> allow only /admin routes
If role is user -> allow only /user routes
If user opens wrong role route -> redirect to correct role home
```

### Shell routes

Each role should have its own shell:

```text
SuperadminShell
AdminShell
UserShell
```

Shells handle:

- bottom navigation
- role layout
- role menu
- common role page structure

---

## 16. UI/UX Design System

OpenVTS Flutter UI must match the OpenVTS web brand language.

The product should feel:

```text
calm
premium
minimal
precise
engineered
trustworthy
enterprise-grade
monochrome-first
structured
```

### UI principles

```text
Structure over decoration.
Spacing over clutter.
Borders over heavy shadows.
Typography over visual noise.
Consistency over novelty.
Clarity over cleverness.
```

### Avoid

```text
random colors
bright gradients
neon effects
heavy shadows
cartoon icons
crowded cards
raw Material default styling
one-off component styles
inconsistent spacing
```

---

## 17. Color System

Colors must be centralized in:

```text
lib/core/theme/open_vts_colors.dart
```

### Required colors

```dart
class OpenVtsColors {
  static const ink = Color(0xFF141118);
  static const inkSoft = Color(0xFF1D1821);
  static const white = Color(0xFFFFFFFF);

  static const background = Color(0xFFFAFAFB);
  static const surface = Color(0xFFF4F3F6);
  static const border = Color(0xFFE7E3EA);
  static const divider = Color(0xFFD8D3DC);

  static const textPrimary = Color(0xFF141118);
  static const textSecondary = Color(0xFF6B6570);
  static const textTertiary = Color(0xFF908A96);
}
```

### Functional colors

Functional colors should be muted and mature:

```text
Success: deep muted green
Warning: deep muted amber
Error: deep muted red
Info: deep muted blue-gray
```

### Color rules

```text
Use monochrome first.
Use functional colors only for state or meaning.
Do not use color as decoration.
Do not hardcode Color() inside screens.
Do not use random hex values.
Do not rely only on color to communicate errors/status.
```

---

## 18. Typography and Fonts

Primary font:

```text
Inter
```

Fallback:

```text
system-ui / platform default
```

### Font rule

All typography must come from:

```text
lib/core/theme/open_vts_typography.dart
```

### Recommended mobile type scale

```text
Display: 32 / 40 / 600
H1:      28 / 36 / 600
H2:      24 / 32 / 600
H3:      20 / 28 / 600
Body:    16 / 24 / 400
Body Sm: 14 / 22 / 400
Label:   13 / 18 / 500
Meta:    12 / 18 / 400
Button:  14 / 20 / 500
```

### Important font setup note

If `fontFamily: 'Inter'` is used, Inter font files must be added before final production UI polishing.

Recommended location:

```text
assets/fonts/
```

Recommended pubspec setup:

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### Typography rules

```text
Use one font family across the app.
Do not create random text styles inside screens.
Use TextTheme from OpenVTS theme.
Prefer clear hierarchy over bold-heavy UI.
Keep labels readable and calm.
Avoid overly small body text.
```

---

## 19. Spacing System

Spacing must be centralized in:

```text
lib/core/theme/open_vts_spacing.dart
```

### Base unit

```text
8px
```

### Allowed spacing scale

```text
4, 8, 12, 16, 20, 24, 32, 40, 48, 64
```

### Spacing rules

```text
Use spacing tokens, not random numbers.
Increase spacing before adding decoration.
Group related content by proximity.
Separate sections with rhythm.
Use enough padding for touch comfort.
Minimum touch target: 44x44.
```

---

## 20. Radius System

Radius must be centralized in:

```text
lib/core/theme/open_vts_radius.dart
```

### Recommended radius

```text
Small: 8
Medium: 12
Large: 16
XL: 20 only when justified
```

### Radius rules

```text
Do not use random BorderRadius values.
Do not over-round enterprise UI.
Cards usually use 12 or 16.
Buttons usually use 10 or 12.
Inputs usually use 10 or 12.
```

---

## 21. Theme System

Theme must be defined in:

```text
lib/core/theme/open_vts_theme.dart
```

The app must use:

```dart
MaterialApp.router(
  theme: OpenVtsTheme.lightTheme,
  routerConfig: router,
)
```

### Theme should define

```text
ColorScheme
TextTheme
Scaffold background
AppBar theme
Input decoration theme
Button themes
Card theme
Bottom navigation theme
Divider theme
```

### Theme rules

```text
Do not style every screen manually.
Set global defaults in theme.
Override locally only when required.
All controls should feel like one product.
```

---

## 22. Shared Widget System

Shared widgets live in:

```text
lib/shared/widgets/
```

### Required shared widgets

```text
OpenVtsButton
OpenVtsCard
OpenVtsTextField
OpenVtsPageScaffold
OpenVtsLoader
OpenVtsEmptyState
OpenVtsErrorView
OpenVtsStatusChip
OpenVtsSearchField
OpenVtsMetricCard
VehicleCard
OpenVtsMapPreview
OpenVtsBottomSheet
OpenVtsConfirmationDialog
```

### Shared widget rules

```text
Use shared widgets before creating new UI.
If two screens need the same pattern, make it shared.
Shared widgets must use theme tokens.
Shared widgets must not contain role-specific logic.
Shared widgets must support loading/error/disabled states where needed.
```

### Screen-specific widgets

If a widget belongs only to one screen, keep it inside:

```text
features/<role>/screens/<page>/widgets/
```

Example:

```text
features/superadmin/screens/dashboard/widgets/superadmin_revenue_card.dart
```

---

## 23. Buttons

Use:

```text
OpenVtsButton
```

### Button types

```text
primary
secondary
ghost / text
icon button where needed
```

### Button rules

```text
One clear primary action per area.
Button labels must be action-oriented.
Loading state must be supported.
Disabled state must be clear.
Minimum height should be 44.
Do not create custom button styles in screens.
```

---

## 24. Forms and Inputs

Use:

```text
OpenVtsTextField
OpenVtsSearchField
```

### Form rules

```text
Labels above fields where possible.
Validation should be clear and calm.
Do not rely only on red color for errors.
Use helper text where needed.
Long forms should be grouped into sections.
Sticky action area can be used for long edit screens.
```

---

## 25. Cards and Lists

Use:

```text
OpenVtsCard
VehicleCard
OpenVtsMetricCard
```

### Card rules

```text
Prefer border-based cards.
Use subtle background contrast.
Avoid heavy shadows.
Use generous internal padding.
Keep card hierarchy clear.
Do not overload cards with too many actions.
```

### List rules

```text
Rows should be readable and touch-friendly.
Use status chips for status values.
Avoid dense desktop-style tables on mobile.
Use bottom sheets for details/actions when needed.
```

---

## 26. Icons

Recommended direction:

```text
Use one icon family only.
Use clean monoline icons.
Use icons functionally, not decoratively.
```

### Icon sizes

```text
16
18
20
24
```

### Icon rules

```text
Do not mix many icon packs.
Do not use playful/cartoon icons.
Icons must support meaning.
Icons should align optically with text.
```

---

## 27. Map Architecture

Map screens are important for OpenVTS and must stay performant.

Current foundation:

```text
flutter_map
latlong2
socket_io_client placeholder
```

### Map feature folders

For now, map screens live inside each role:

```text
features/superadmin/screens/map/
features/admin/screens/map/
features/user/screens/map/
```

Shared map preview/components live in:

```text
shared/widgets/open_vts_map_preview.dart
```

### Future map services

If map logic grows, add:

```text
core/socket/socket_service.dart
core/telemetry/telemetry_parser.dart
core/telemetry/telemetry_deduplicator.dart
core/telemetry/telemetry_throttler.dart
```

### Real-time telemetry flow

```text
Socket event
  -> socket service
    -> parse telemetry
      -> validate data
        -> deduplicate/stale check
          -> throttle updates
            -> Riverpod map state
              -> map marker UI
```

### Map rules

```text
Do not rebuild the full map for every socket packet.
Do not put socket parsing inside widgets.
Do not keep heavy marker logic inside screen build methods.
Throttle marker updates when live data is high volume.
Use bottom sheets for vehicle details on mobile.
```

---

## 28. Socket Architecture

Base socket service lives in:

```text
lib/core/socket/socket_service.dart
```

### Socket rules

```text
Connect only after successful login/session restore.
Disconnect on logout.
Reconnect safely when app resumes or network returns.
Do not let socket events directly mutate UI widgets.
Convert socket events into Riverpod state.
```

### Namespaces to support later

```text
/telemetry
/notifications
```

---

## 29. Cache System

Current Phase 1 cache:

```text
flutter_secure_storage -> tokens and role
shared_preferences -> lightweight local settings
```

### Cache use cases

```text
selected language
last selected map type
theme mode if added later
user profile snapshot
last role
small preferences
```

### Do not cache blindly

Do not cache sensitive or large operational data without a clear reason.

### Future cache upgrade

If offline history/replay or large telemetry cache is needed, use a database like Drift later.

Do not add a heavy local database in Phase 1 unless the feature needs it.

---

## 30. Localization, Date, and Time

Date/time formatting must be centralized in:

```text
lib/core/utils/date_time_formatter.dart
```

### Rules

```text
Do not format dates directly inside widgets.
Do not use raw DateFormat everywhere.
Do not hardcode inconsistent date formats.
Use central formatter for all dates/times.
```

Future localization can add:

```text
core/localization/
```

Recommended future files:

```text
app_localizations.dart
locale_controller.dart
translation_keys.dart
```

---

## 31. Error Handling

Central error files:

```text
lib/core/errors/app_error.dart
lib/core/errors/error_mapper.dart
lib/core/api/api_exception.dart
```

### Error flow

```text
Dio error
  -> ApiErrorInterceptor
    -> ApiException / AppError
      -> Controller AsyncError
        -> OpenVtsErrorView
```

### Error UI rule

Use:

```text
OpenVtsErrorView
```

Do not create random error layouts per screen.

### Error message rules

```text
Messages should be calm and useful.
Do not expose raw backend stack traces.
Do not show technical errors to normal users.
Provide retry action when possible.
```

---

## 32. Loading and Empty States

Use:

```text
OpenVtsLoader
OpenVtsEmptyState
```

### Loading rules

```text
Show full-page loader for first load.
Show small inline loader for refresh/action.
Avoid unnecessary skeleton complexity in Phase 1.
Do not block entire app for small actions.
```

### Empty state rules

```text
Explain what is empty.
Provide next action where possible.
Keep tone simple and helpful.
```

---

## 33. Role Responsibilities

### Superadmin

Superadmin manages platform-level operations.

Initial pages:

```text
Dashboard
Map
Vehicles
Administrators
Devices
Reports
Settings
```

Future pages:

```text
SIM cards
Drivers
Users
Billing
Notifications
Commands
Support
White-label settings
```

### Admin

Admin manages assigned fleet/users.

Initial pages:

```text
Dashboard
Map
Vehicles
Users
Drivers
Reports
Settings
```

Future pages:

```text
Devices
Geofences
Notifications
Commands
Support
```

### User

User mainly views and operates assigned vehicles.

Initial pages:

```text
Dashboard
Map
Vehicles
Notifications
Settings
```

Future pages:

```text
History
Replay
Vehicle detail
Profile
Support
```

---

## 34. Adding a New API

When adding a new API:

### Step 1: Add endpoint

File:

```text
lib/core/api/api_endpoints.dart
```

Example:

```dart
String get geofences => '/admin/geofences';
```

### Step 2: Add model

Role-specific:

```text
features/admin/models/admin_geofence_model.dart
```

Shared:

```text
shared/models/geofence_summary.dart
```

### Step 3: Add service method

```text
features/admin/services/admin_geofence_service.dart
```

Example:

```dart
Future<List<AdminGeofenceModel>> getGeofences() async {
  final response = await _apiClient.get<List<AdminGeofenceModel>>(
    ApiEndpoints.admin.geofences,
    parser: (json) {
      final list = json as List<dynamic>;
      return list
          .map((item) => AdminGeofenceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    },
  );

  return response.data;
}
```

### Step 4: Add provider/controller

```text
features/admin/controllers/admin_providers.dart
```

### Step 5: Use provider in screen

```dart
final geofencesState = ref.watch(adminGeofencesProvider);
```

### Step 6: Render with shared widgets

Use:

```text
OpenVtsPageScaffold
OpenVtsCard
OpenVtsLoader
OpenVtsErrorView
OpenVtsEmptyState
```

---

## 35. Adding a New Screen

### Step 1: Create screen folder

Example:

```text
features/admin/screens/geofences/admin_geofences_screen.dart
```

### Step 2: Add route path

```text
lib/core/router/route_paths.dart
```

### Step 3: Register route

```text
lib/core/router/app_router.dart
```

### Step 4: Add service/model/provider if dynamic data is needed

```text
features/admin/services/
features/admin/models/
features/admin/controllers/
```

### Step 5: Use shared layout

```dart
return OpenVtsPageScaffold(
  title: 'Geofences',
  body: ...,
);
```

---

## 36. Adding a New Shared Widget

Create widget only when repeated.

### Good shared widget examples

```text
Status chip
Metric card
Search field
Filter sheet
Error view
Empty state
Vehicle card
Page scaffold
```

### Bad shared widget examples

```text
A widget used only once
A widget with role-specific business logic
A widget that directly calls API
A widget that knows about token/session state unnecessarily
```

---

## 37. Dependency Direction

Current project dependency direction:

```yaml
flutter_riverpod: state management and dependency injection
go_router: routing and role guards
dio: centralized API calling
pretty_dio_logger: safe debug logging
flutter_dotenv: .env config
flutter_secure_storage: secure token storage
shared_preferences: simple local preferences
intl: formatting
flutter_svg: SVG assets
cached_network_image: remote images
flutter_map: map foundation
latlong2: coordinates
socket_io_client: socket foundation
connectivity_plus: network awareness
url_launcher: external links
```

### Dependency rules

```text
Do not add a package for small tasks that Dart can handle.
Do not add multiple packages for the same responsibility.
Do not add another state management package.
Do not add another HTTP client.
Do not add random UI kit packages that break OpenVTS design consistency.
```

### Approved major choices

```text
State management: Riverpod
Routing: GoRouter
HTTP: Dio
Secure storage: flutter_secure_storage
Small cache: shared_preferences
Map: flutter_map
Realtime: socket_io_client
Environment: flutter_dotenv
```

---

## 38. Testing and Quality Rules

### Minimum checks before committing

```bash
flutter analyze
flutter test
```

### Recommended checks

```bash
flutter pub outdated
flutter pub deps
```

### What to test first

```text
AuthController login/logout/session restore
ApiClient success/error parsing
TokenStorage save/read/clear
Route guard redirects
Role-based service methods
Critical shared widgets
```

---

## 39. Copilot Development Rules

When using GitHub Copilot, always instruct it:

```text
Follow OpenVTS Simple Role-Based Layered Architecture.
Do not create heavy Clean Architecture folders unless explicitly requested.
Do not call Dio directly from screens.
Do not hardcode API URLs.
Do not hardcode colors/styles in screens.
Use ApiEndpoints for endpoint paths.
Use ApiClient for API calls.
Use role-wise services for business logic.
Use Riverpod providers/controllers for screen state.
Use shared OpenVTS widgets before creating new widgets.
Use OpenVTS theme tokens.
Keep Superadmin/Admin/User folders separate.
```

### Copilot must not do this

```text
Create direct Dio calls in widgets.
Create new random ApiService in a screen folder.
Create duplicate endpoint strings.
Use setState for backend data.
Add GetX, Provider, Bloc, or another state package.
Create random color constants in screens.
Create page-specific button/card styles without reason.
Move role-specific code into core.
```

---

## 40. Production Readiness Checklist

Before production release, complete these:

```text
Replace mock data with real backend response mapping.
Validate API_BASE_URL=https://app.openvts.io/api in .env.
Implement real /auth/me session validation.
Implement real refresh token retry logic.
Confirm logout clears tokens and disconnects socket.
Add Inter font files and register them in pubspec.yaml.
Connect real dashboard APIs for each role.
Connect real vehicle list APIs for each role.
Connect real map vehicle APIs.
Implement socket telemetry carefully.
Add notification flow.
Add app icon and splash branding.
Add Android permissions.
Add iOS permissions if iOS is supported.
Run flutter analyze with zero critical issues.
Run tests for auth, API, routing, storage.
Check UI consistency across roles.
Check mobile responsiveness on small/large screens.
Check loading/error/empty states on every dynamic screen.
Ensure no private secrets exist in .env or assets.
```

---

## 41. Final Standard

The OpenVTS Flutter app should feel:

```text
simple to maintain
clean to extend
role-wise organized
centralized where needed
not over-engineered
not messy
premium in UI
consistent with the web app
safe in token handling
predictable in API flow
ready for phased development
```

The final development principle:

```text
Centralize the foundation.
Separate the roles.
Reuse the UI.
Keep screens clean.
Let Riverpod manage state.
Let services manage business logic.
Let ApiClient manage API calls.
Let theme tokens control design.
```

This document is the source of truth for OpenVTS Flutter development.
