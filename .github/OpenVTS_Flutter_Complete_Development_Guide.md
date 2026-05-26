# OpenVTS Flutter Complete Development Guide

> **Product:** OpenVTS Flutter Application  
> **Platforms:** Android, iOS, Flutter Web preview, future tablet/desktop adaptation  
> **Primary API:** `https://app.openvts.io/api`  
> **Purpose:** This document is the single development contract for the OpenVTS Flutter project. It defines architecture, folder structure, API calling, role-wise business logic, Riverpod state management, shared component usage, UI/UX rules, theme tokens, fonts, cache, token flow, routing, map behavior, and Copilot guardrails.

---

## 0. Final development decision

OpenVTS Flutter must use a **simple role-based layered architecture**.

It must not become a heavy over-engineered codebase.
It must also not become a screen-by-screen messy Flutter app.

The agreed architecture is:

```text
Screen / UI Widget
  -> Riverpod Controller / Provider
    -> Role-wise Service / Business Logic
      -> Central ApiClient
        -> Dio
          -> Backend API
```

This means:

- API calling is centralized.
- API endpoints are centralized.
- Token handling is centralized.
- Business logic is separated by role: Superadmin, Admin, User.
- UI is separated by role screens.
- Common UI components live in one shared widget system.
- Screen-specific widgets stay inside that screen/role folder.
- Riverpod manages screen state and dependency access.
- Screens do not directly call Dio, token storage, sockets, or raw backend services.

---

## 1. Non-negotiable project goals

The Flutter application must feel like the same product ecosystem as:

- OpenVTS marketing website,
- OpenVTS web dashboard,
- OpenVTS mobile app,
- future OpenVTS desktop/tablet app.

The product should feel:

- premium,
- calm,
- monochrome-first,
- precise,
- enterprise-grade,
- self-hosted and ownership-first,
- fast and operational,
- not like a generic Flutter admin template.

The codebase should feel:

- simple,
- readable,
- role-organized,
- centralized where it matters,
- easy for GitHub Copilot to follow,
- safe for long-term development.

---

## 2. Required root folder structure

Use this structure as the default structure for the Flutter app.

```text
lib/
├── main.dart
├── bootstrap.dart
├── app.dart
├── app_entry.dart
│
├── core/
│   ├── api/
│   ├── config/
│   ├── errors/
│   ├── providers/
│   ├── router/
│   ├── socket/
│   ├── storage/
│   ├── theme/
│   └── utils/
│
├── shared/
│   ├── helpers/
│   ├── models/
│   └── widgets/
│
└── features/
    ├── auth/
    ├── onboarding/
    ├── superadmin/
    ├── admin/
    └── user/
```

Required generated platform folder for Flutter Web preview:

```text
web/
```

### Folder responsibility

| Folder | Responsibility |
|---|---|
| `core/` | App-wide infrastructure: API, config, tokens, router, theme, socket, errors, utilities. |
| `shared/` | Reusable UI widgets, shared models, UI helpers, common view patterns. |
| `features/auth/` | Login, logout, session restore, forgot password, current user state. |
| `features/onboarding/` | First-launch onboarding flow, onboarding models, onboarding-only widgets, onboarding completion gate. |
| `features/superadmin/` | Superadmin screens, controllers, services, models, widgets. |
| `features/admin/` | Admin screens, controllers, services, models, widgets. |
| `features/user/` | User screens, controllers, services, models, widgets. |

---

## 3. Core folder structure

```text
lib/core/
├── api/
│   ├── api_client.dart
│   ├── api_endpoints.dart
│   ├── api_response.dart
│   ├── api_exception.dart
│   └── interceptors/
│       ├── auth_interceptor.dart
│       ├── refresh_token_interceptor.dart
│       ├── error_interceptor.dart
│       └── logging_interceptor.dart
│
├── config/
│   ├── app_config.dart
│   └── app_constants.dart
│
├── providers/
│   └── core_providers.dart
│
├── router/
│   ├── app_router.dart
│   └── route_paths.dart
│
├── storage/
│   ├── token_storage.dart
│   ├── local_cache.dart
│   └── storage_keys.dart
│
├── theme/
│   ├── open_vts_colors.dart
│   ├── open_vts_typography.dart
│   ├── open_vts_spacing.dart
│   ├── open_vts_radius.dart
│   └── open_vts_theme.dart
│
├── socket/
│   └── socket_service.dart
│
├── errors/
│   ├── app_error.dart
│   └── error_mapper.dart
│
└── utils/
    ├── validators.dart
    ├── formatters.dart
    ├── date_time_formatter.dart
    └── permission_helper.dart
```

### Rule

`core/` is not a place for feature-specific code.

Do not put Superadmin vehicle logic, Admin user logic, or User notification logic inside `core/`.

---

## 4. Shared folder structure

```text
lib/shared/
├── widgets/
│   ├── open_vts_page_scaffold.dart
│   ├── open_vts_button.dart
│   ├── open_vts_card.dart
│   ├── open_vts_text_field.dart
│   ├── open_vts_search_field.dart
│   ├── open_vts_status_chip.dart
│   ├── open_vts_loader.dart
│   ├── open_vts_empty_state.dart
│   ├── open_vts_error_view.dart
│   ├── open_vts_metric_card.dart
│   ├── open_vts_bottom_sheet.dart
│   ├── open_vts_app_bar.dart
│   ├── open_vts_bottom_nav.dart
│   ├── open_vts_list_tile.dart
│   ├── open_vts_confirmation_dialog.dart
│   ├── vehicle_card.dart
│   └── open_vts_map_preview.dart
│
├── models/
│   ├── api_result.dart
│   ├── pagination_model.dart
│   ├── user_role.dart
│   ├── dropdown_item.dart
│   └── vehicle_summary.dart
│
└── helpers/
    ├── toast_helper.dart
    ├── dialog_helper.dart
    └── ui_helper.dart
```

---

## 5. Common component rule

This is mandatory.

### 5.1 When a common component exists

If a UI component already exists in:

```text
lib/shared/widgets/
```

then every screen must use that component.

Examples:

| UI need | Use this path |
|---|---|
| Page layout | `lib/shared/widgets/open_vts_page_scaffold.dart` |
| Button | `lib/shared/widgets/open_vts_button.dart` |
| Card | `lib/shared/widgets/open_vts_card.dart` |
| Text field | `lib/shared/widgets/open_vts_text_field.dart` |
| Search input | `lib/shared/widgets/open_vts_search_field.dart` |
| Loading | `lib/shared/widgets/open_vts_loader.dart` |
| Empty state | `lib/shared/widgets/open_vts_empty_state.dart` |
| Error state | `lib/shared/widgets/open_vts_error_view.dart` |
| Status chip | `lib/shared/widgets/open_vts_status_chip.dart` |
| KPI/metric card | `lib/shared/widgets/open_vts_metric_card.dart` |
| Vehicle row/card | `lib/shared/widgets/vehicle_card.dart` |

### 5.2 When to create a new shared component

Create a component in `lib/shared/widgets/` only if:

- it is used in two or more screens,
- it represents a core OpenVTS UI pattern,
- it should look exactly the same across roles.

Examples:

- `OpenVtsFilterSheet`,
- `OpenVtsDateRangePicker`,
- `OpenVtsActionBar`,
- `OpenVtsSectionHeader`,
- `OpenVtsInfoRow`,
- `OpenVtsMapControlButton`.

### 5.3 When to keep component inside screen folder

If a widget is only used by one screen or one page flow, keep it close to that screen.

Example:

```text
lib/features/superadmin/screens/dashboard/widgets/superadmin_recent_activity_card.dart
```

Do not move it to `shared/widgets/` until it becomes reusable.

### 5.4 Do not bypass shared widgets

Do not use raw Flutter widgets in feature screens when OpenVTS components exist.

Avoid in screens:

```dart
ElevatedButton(...)
OutlinedButton(...)
TextButton(...)
TextFormField(...)
ScaffoldMessenger.of(context).showSnackBar(...)
CircularProgressIndicator(...)
Container(decoration: BoxDecoration(...)) // as repeated card pattern
```

Use:

```dart
OpenVtsButton(...)
OpenVtsTextField(...)
OpenVtsCard(...)
OpenVtsLoader(...)
OpenVtsErrorView(...)
OpenVtsEmptyState(...)
ToastHelper.showSuccess(...)
```

---

## 6. Feature folder structure

Every role feature should use this structure.

```text
features/superadmin/
├── screens/
├── controllers/
├── services/
├── models/
└── widgets/
```

Same for:

```text
features/onboarding/
features/admin/
features/user/
```

`features/onboarding/` is the approved location for first-launch flows that run before auth routing.

### Example: Superadmin

```text
lib/features/superadmin/
├── screens/
│   ├── superadmin_shell.dart
│   ├── dashboard/
│   │   └── superadmin_dashboard_screen.dart
│   ├── map/
│   │   └── superadmin_map_screen.dart
│   ├── vehicles/
│   │   ├── superadmin_vehicles_screen.dart
│   │   └── superadmin_vehicle_detail_screen.dart
│   ├── administrators/
│   │   └── administrators_screen.dart
│   ├── devices/
│   │   └── superadmin_devices_screen.dart
│   ├── reports/
│   │   └── superadmin_reports_screen.dart
│   └── settings/
│       └── superadmin_settings_screen.dart
│
├── controllers/
│   ├── superadmin_providers.dart
│   ├── superadmin_dashboard_controller.dart
│   ├── superadmin_vehicle_controller.dart
│   ├── superadmin_map_controller.dart
│   └── superadmin_settings_controller.dart
│
├── services/
│   ├── superadmin_dashboard_service.dart
│   ├── superadmin_vehicle_service.dart
│   ├── superadmin_map_service.dart
│   ├── superadmin_admin_service.dart
│   └── superadmin_report_service.dart
│
├── models/
│   ├── superadmin_dashboard_model.dart
│   ├── superadmin_vehicle_model.dart
│   └── superadmin_admin_model.dart
│
└── widgets/
    ├── superadmin_kpi_card.dart
    └── superadmin_quick_action_grid.dart
```

---

## 7. Role responsibility

### 7.1 Superadmin

Superadmin manages the full platform.

Common Superadmin modules:

```text
Dashboard
Map
Administrators
Vehicles
Devices
SIM cards
Drivers
Users
Reports
Notifications
Commands
Settings
Profile
Support
```

Superadmin screens can show more technical/administrative information than user screens.

### 7.2 Admin

Admin manages assigned users, vehicles, drivers, and reports.

Common Admin modules:

```text
Dashboard
Map
Users
Vehicles
Drivers
Devices
Reports
Notifications
Commands
Settings
Profile
Support
```

Admin screens should focus on operational control, not platform-wide settings.

### 7.3 User

User mainly views and operates assigned vehicles.

Common User modules:

```text
Dashboard
Map
Vehicles
Vehicle Detail
History
Replay
Notifications
Profile
Settings
Support
```

User screens should be simpler, task-focused, and less technical.

---

## 8. API base URL and environment

The Flutter app must use `.env` for environment configuration.

### Required `.env`

```env
API_BASE_URL=https://app.openvts.io/api
USE_MOCK_DATA=false
```

### Required `.env.example`

```env
API_BASE_URL=https://app.openvts.io/api
USE_MOCK_DATA=false
```

### Required pubspec assets

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/brand/
    - assets/fonts/
    - assets/images/
    - .env
```

### Required package and import contract

`pubspec.yaml` package name must be:

```text
open_vts
```

Internal absolute imports must use the same prefix:

```dart
import 'package:open_vts/app.dart';
import 'package:open_vts/bootstrap.dart';
```

Do not keep `package:open_vts/...` imports while renaming the pubspec package to something else.

### Required bootstrap

`bootstrap.dart` must load `.env` before app startup and then invoke the callback supplied by `main.dart`:

```dart
Future<void> bootstrap(Future<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await runApp();
}
```

### Required startup flow

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
app.dart owns the MaterialApp shell.
app_entry.dart owns the pre-router onboarding gate.
Splash remains the auth/session restore surface.
Onboarding completion is persisted before entering auth restore.
```

### Required web support rule

Flutter Web preview is a supported target. Keep the generated `web/` folder in version control.

If it is missing, restore it with:

```text
flutter create . --platforms=web
```

### Required config

`lib/core/config/app_config.dart` must read:

```dart
static String get apiBaseUrl {
  final value = dotenv.env['API_BASE_URL'];
  if (value != null && value.trim().isNotEmpty) {
    return value.trim();
  }

  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.openvts.io/api',
  );
}
```

### Security rule

`.env` in Flutter is not for secrets.

Allowed:

```text
API_BASE_URL
USE_MOCK_DATA
APP_ENV
```

Not allowed:

```text
JWT secret
database password
server private key
Firebase service account
admin password
payment secret key
```

---

## 9. Centralized API implementation

All backend calls must pass through:

```text
lib/core/api/api_client.dart
```

Screens must never call Dio directly.

### Correct flow

```text
Screen
  -> Riverpod Controller
    -> Role Service
      -> ApiClient
        -> Dio
          -> Backend
```

### Incorrect flow

```text
Screen
  -> Dio directly
```

or

```text
Screen
  -> TokenStorage directly
```

or

```text
Screen
  -> raw http package
```

### ApiClient responsibilities

`ApiClient` should handle:

- `GET`,
- `POST`,
- `PUT`,
- `PATCH` if needed,
- `DELETE`,
- centralized response parsing,
- centralized API exception mapping,
- query parameters,
- payload forwarding,
- generic parser callback.

### Example API client pattern

```dart
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: queryParameters,
    );

    return ApiResponse<T>.fromJson(
      response.data,
      parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    required T Function(dynamic json) parser,
  }) async {
    final response = await _dio.post(endpoint, data: data);

    return ApiResponse<T>.fromJson(
      response.data,
      parser,
    );
  }
}
```

---

## 10. Centralized API endpoints

All endpoints must live inside:

```text
lib/core/api/api_endpoints.dart
```

Endpoints must be grouped by feature/role.

### Required pattern

```dart
class ApiEndpoints {
  static const auth = _AuthEndpoints();
  static const superadmin = _SuperadminEndpoints();
  static const admin = _AdminEndpoints();
  static const user = _UserEndpoints();
}
```

### Example

```dart
class _AuthEndpoints {
  const _AuthEndpoints();

  String get login => '/auth/login';
  String get refreshToken => '/auth/refresh';
  String get forgotPassword => '/auth/forgot-password';
  String get logout => '/auth/logout';
  String get me => '/auth/me';
}

class _SuperadminEndpoints {
  const _SuperadminEndpoints();

  String get dashboard => '/superadmin/dashboard';
  String get vehicles => '/superadmin/vehicles';
  String vehicleDetail(String id) => '/superadmin/vehicles/$id';
  String get administrators => '/superadmin/admins';
  String get devices => '/superadmin/devices';
  String get reports => '/superadmin/reports';
}
```

### Endpoint rules

Do not hardcode endpoint strings inside screens or services.

Wrong:

```dart
apiClient.get('/superadmin/vehicles', ...)
```

Correct:

```dart
apiClient.get(ApiEndpoints.superadmin.vehicles, ...)
```

---

## 11. API response model

All API responses should be parsed through a central response model.

Recommended path:

```text
lib/core/api/api_response.dart
```

Example:

```dart
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final T data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) parser,
  ) {
    final dataNode = json['data'];

    return ApiResponse<T>(
      success: json['status'] == 'success' || json['success'] == true,
      message: _extractMessage(json),
      data: parser(_extractPayload(dataNode)),
    );
  }
}
```

The exact parser can be adjusted to your backend response shape, but the response handling must remain centralized.

---

## 12. Dio setup and interceptors

Dio must be configured in:

```text
lib/core/providers/core_providers.dart
```

or a dedicated:

```text
lib/core/api/dio_provider.dart
```

Required interceptors:

```text
lib/core/api/interceptors/auth_interceptor.dart
lib/core/api/interceptors/refresh_token_interceptor.dart
lib/core/api/interceptors/error_interceptor.dart
lib/core/api/interceptors/logging_interceptor.dart
```

### Auth interceptor

Adds token to every authorized API request.

```text
Authorization: Bearer <accessToken>
```

### Refresh token interceptor

When backend returns `401`:

```text
401 received
  -> check refresh token
  -> call refresh endpoint
  -> save new access token
  -> retry original request once
  -> if still failed, logout
```

### Error interceptor

Converts `DioException` into app-level error.

Screens should not display raw backend error maps.

### Logging interceptor

Allowed only in debug/development.

Never log:

- access token,
- refresh token,
- password,
- private user data,
- authorization headers.

---

## 13. Token storage system

Token storage must be centralized in:

```text
lib/core/storage/token_storage.dart
```

Use:

```text
flutter_secure_storage
```

### Required stored values

```text
accessToken
refreshToken
userRole
userId
optional user snapshot
```

### Login flow

```text
User submits login
  -> AuthController
    -> AuthService.login()
      -> ApiClient.post(ApiEndpoints.auth.login)
        -> TokenStorage.saveTokens()
          -> AuthState authenticated
            -> GoRouter redirects by role
```

### Session restore flow

Phase 1:

```text
App start
  -> read token and role
  -> if available, restore authenticated state
  -> redirect to role dashboard
```

Production target:

```text
App start
  -> read token
  -> call ApiEndpoints.auth.me
  -> validate user and role
  -> restore authenticated state
  -> initialize sockets
```

### Logout flow

```text
Logout
  -> disconnect socket
  -> unregister FCM token if implemented
  -> clear token storage
  -> clear user-specific local cache if required
  -> reset auth state
  -> navigate to login
```

---

## 14. Riverpod state management

Use Riverpod for:

- auth state,
- API loading/error/data state,
- dashboard data,
- vehicle list state,
- map state,
- notification state,
- form submission state,
- selected filters,
- app-level settings.

### Required controller pattern

```text
features/<role>/controllers/<role>_<feature>_controller.dart
```

Example:

```dart
final superadminVehicleControllerProvider =
    AsyncNotifierProvider<SuperadminVehicleController, List<VehicleSummary>>(
  SuperadminVehicleController.new,
);

class SuperadminVehicleController extends AsyncNotifier<List<VehicleSummary>> {
  @override
  Future<List<VehicleSummary>> build() async {
    final service = ref.read(superadminVehicleServiceProvider);
    return service.getVehicles();
  }

  Future<void> refreshVehicles() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(superadminVehicleServiceProvider);
      return service.getVehicles();
    });
  }
}
```

### Screen pattern

```dart
class SuperadminVehiclesScreen extends ConsumerWidget {
  const SuperadminVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(superadminVehicleControllerProvider);

    return OpenVtsPageScaffold(
      title: 'Vehicles',
      body: state.when(
        data: (vehicles) => VehicleListView(vehicles: vehicles),
        loading: () => const OpenVtsLoader(),
        error: (error, stackTrace) => OpenVtsErrorView(
          message: 'Unable to load vehicles.',
          onRetry: () => ref
              .read(superadminVehicleControllerProvider.notifier)
              .refreshVehicles(),
        ),
      ),
    );
  }
}
```

### Riverpod rules

Do:

- Use providers for services.
- Use `AsyncValue` for API-driven screens.
- Keep loading/error/data state outside widgets.
- Keep controller logic small and focused.

Do not:

- Use `setState` for API loading/data/error.
- Call services directly from widgets.
- Parse JSON inside widgets.
- Put business logic in `build()`.

`setState` is allowed only for tiny local UI state such as:

- password visibility,
- local tab selection,
- expansion tile state,
- temporary animation toggle.

---

## 15. Role-wise business logic services

Business logic should be role-wise, not one giant service.

Correct:

```text
features/superadmin/services/superadmin_vehicle_service.dart
features/admin/services/admin_vehicle_service.dart
features/user/services/user_vehicle_service.dart
```

### Example Superadmin service

```dart
class SuperadminVehicleService {
  SuperadminVehicleService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<VehicleSummary>> getVehicles() async {
    final response = await _apiClient.get<List<VehicleSummary>>(
      ApiEndpoints.superadmin.vehicles,
      parser: (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => VehicleSummary.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );

    return response.data;
  }
}
```

### Why role-wise services?

Because Superadmin, Admin, and User can have:

- different endpoints,
- different payloads,
- different permissions,
- different screen actions,
- different response models,
- different business rules.

Common models can still live in `shared/models/` when response shape is the same.

---

## 16. Models

Models should live close to the role/feature unless shared.

### Role-specific model

```text
features/superadmin/models/superadmin_dashboard_model.dart
```

### Shared model

```text
shared/models/vehicle_summary.dart
```

Use shared model only when the same model is truly used across roles.

Do not create one huge `models/` folder with everything mixed together.

---

## 17. Routing and role guards

Use:

```text
go_router
```

Required files:

```text
lib/core/router/app_router.dart
lib/core/router/route_paths.dart
```

### Pre-router entry gate

`app_entry.dart` runs before `go_router` role guards.

```text
AppEntry
  -> onboarding incomplete -> OnboardingScreen
  -> onboarding complete -> SplashScreen
    -> auth restore
    -> role-based redirects
```

Do not model first-launch onboarding as a role route.

### Route paths

```text
/login
/forgot-password
/splash

/superadmin/dashboard
/superadmin/map
/superadmin/vehicles
/superadmin/vehicles/:id
/superadmin/administrators
/superadmin/devices
/superadmin/reports
/superadmin/settings

/admin/dashboard
/admin/map
/admin/users
/admin/vehicles
/admin/vehicles/:id
/admin/drivers
/admin/reports
/admin/settings

/user/dashboard
/user/map
/user/vehicles
/user/vehicles/:id
/user/history
/user/notifications
/user/settings
```

### Guard rule

```text
No token -> login
Role superadmin -> superadmin routes
Role admin -> admin routes
Role user -> user routes
Wrong role route -> redirect to correct role dashboard
```

Backend remains the final authority for permissions.
Frontend role guards are only UX protection.

---

## 18. Cache and local storage

Keep cache simple in Phase 1.

### Use secure storage for

```text
access token
refresh token
user role
user id
```

### Use local cache/shared preferences for

```text
selected language
theme mode
last selected map type
last selected filters
small user preferences
```

### Use database/cache later only if needed for

```text
history replay cache
large route history
offline vehicle list
notification archive
queued commands
```

Do not add heavy offline database in Phase 1 unless the feature requires it.

---

## 19. Socket and real-time telemetry

Socket foundation should live in:

```text
lib/core/socket/socket_service.dart
```

Do not connect sockets directly from screens.

### Correct flow

```text
Auth success
  -> initialize socket
  -> join role/user rooms if backend requires
  -> receive telemetry/events
  -> controller/provider updates UI-ready state
  -> map/list widgets render state
```

### Map telemetry rule

Do not allow every socket event to rebuild the full map.

Correct structure:

```text
Socket event
  -> parse
  -> validate
  -> deduplicate
  -> throttle/buffer if needed
  -> update marker state
  -> only marker layer updates
```

The map tile layer must not rebuild for every marker update.

---

## 20. UI/UX source of truth

The Flutter UI must follow the OpenVTS web/product visual system.

OpenVTS design language:

```text
premium
monochrome-first
precise
calm
enterprise-grade
border-led
not loud
not glossy
not generic
```

Use theme tokens and shared widgets before creating screen-specific visuals.

---

## 21. Theme system

Required theme files:

```text
lib/core/theme/open_vts_colors.dart
lib/core/theme/open_vts_typography.dart
lib/core/theme/open_vts_spacing.dart
lib/core/theme/open_vts_radius.dart
lib/core/theme/open_vts_theme.dart
```

### Color tokens

Core colors:

```text
Brand Ink:        #141118
Brand Ink Soft:   #1D1821
White:            #FFFFFF
Background:       #FAFAFB
Surface:          #F4F3F6
Border:           #E7E3EA
Divider:          #D8D3DC
Text Secondary:   #6B6570
Text Tertiary:    #908A96
```

Status colors must be muted:

```text
Success: muted green
Warning: muted amber
Danger: muted red
Info: muted blue-gray
```

### Color rules

Do not use raw colors in screens.

Wrong:

```dart
Colors.black
Colors.white
Colors.red
Color(0xFF141118)
```

Correct:

```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
Theme.of(context).colorScheme.onSurface
OpenVtsColors.success
OpenVtsColors.danger
```

Status color is for status, not decoration.

---

## 22. Font and typography

OpenVTS uses a two-font typography system.

| Role | Font | Usage |
|---|---|---|
| Primary product UI font | **Inter** | All normal screens, forms, lists, data, dashboard, maps, navigation, reports, and body copy |
| Secondary brand/editorial font | **Satoshi** | Controlled brand moments only: splash, onboarding headline, premium empty-state heading, campaign-style hero, logo-adjacent typography |

Inter is the default. Satoshi is rare and must not be used for dense operational UI.

### Required implementation files

```text
lib/core/theme/open_vts_typography.dart
lib/core/theme/open_vts_theme.dart
assets/fonts/README.md
assets/fonts/inter/
assets/fonts/satoshi/
```

### Development implementation

The boilerplate applies Inter through `OpenVtsTheme` and `OpenVtsTypography`.

```dart
OpenVtsTypography.primaryFontFamily   // Inter
OpenVtsTypography.secondaryFontFamily // Satoshi
OpenVtsTypography.brandTitle          // approved Satoshi style
OpenVtsTypography.brandLabel          // approved Satoshi style
OpenVtsTypography.numeric             // tabular Inter numeric style
```

### Production local font paths

```text
assets/fonts/inter/
  Inter-Regular.ttf
  Inter-Medium.ttf
  Inter-SemiBold.ttf
  Inter-Bold.ttf

assets/fonts/satoshi/
  Satoshi-Regular.ttf
  Satoshi-Medium.ttf
  Satoshi-Bold.ttf
```

### Production pubspec registration

The boilerplate includes this block in `pubspec.yaml` as comments. Uncomment only after adding licensed font files.

```yaml
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/inter/Inter-Regular.ttf
        weight: 400
      - asset: assets/fonts/inter/Inter-Medium.ttf
        weight: 500
      - asset: assets/fonts/inter/Inter-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/inter/Inter-Bold.ttf
        weight: 700
  - family: Satoshi
    fonts:
      - asset: assets/fonts/satoshi/Satoshi-Regular.ttf
        weight: 400
      - asset: assets/fonts/satoshi/Satoshi-Medium.ttf
        weight: 500
      - asset: assets/fonts/satoshi/Satoshi-Bold.ttf
        weight: 700
```

Do not commit or distribute font files unless your license permits it.

### Typography rules

Do not create raw `TextStyle` in feature screens.

Wrong:

```dart
TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)
```

Correct:

```dart
Theme.of(context).textTheme.bodyMedium?.copyWith(
  color: Theme.of(context).colorScheme.onSurfaceVariant,
)
```

Use tabular figures for:

- speed,
- odometer,
- distance,
- engine hours,
- coordinates,
- counts,
- timestamps.

---

## 23. Spacing system

Use spacing tokens from:

```text
lib/core/theme/open_vts_spacing.dart
```

Recommended scale:

```text
4, 8, 12, 16, 20, 24, 32, 40, 48, 64
```

Default mobile page padding:

```text
16dp
```

Rules:

- Do not use random values like `17`, `23`, `31`.
- Use full-bleed layout only for map/media screens.
- CRUD screens should use 16dp horizontal padding.
- Add bottom safe area padding for scrollable screens.

---

## 24. Radius, borders, shadow

Use radius tokens from:

```text
lib/core/theme/open_vts_radius.dart
```

Recommended:

```text
Small: 8
Medium: 12
Large: 16
XL: 20
Pill: 999
```

Use borders more than shadows.

Rules:

- Cards should usually use subtle border.
- Shadows should be rare and soft.
- No neon glow.
- No heavy Material elevation everywhere.
- No random radius per screen.

---

## 25. Button rules

Use:

```text
lib/shared/widgets/open_vts_button.dart
```

Do not use raw Material buttons in feature screens if OpenVTS button fits.

Button rules:

- One primary action per screen/section.
- Full-width primary button on mobile forms.
- Destructive action uses danger style.
- Loading button disables itself.
- Icon-only button must have minimum 44dp tap target.

---

## 26. Form rules

Use:

```text
lib/shared/widgets/open_vts_text_field.dart
```

Form rules:

- Labels above fields for complex forms.
- Use helper text when useful.
- Error text below input.
- Required field marking must be consistent.
- Use correct keyboard type.
- Use autofill hints for login/profile forms.
- Prevent double submit.
- Use inline validation.

---

## 27. Card/list rules

Use:

```text
OpenVtsCard
VehicleCard
OpenVtsMetricCard
OpenVtsStatusChip
OpenVtsListTile
```

List rules:

- Use `ListView.builder` for dynamic lists.
- Minimum tap target 44dp.
- Show title, key metadata, status, and action clearly.
- Do not copy desktop table layout into mobile.
- Use detail screen or bottom sheet instead of wide rows.

---

## 28. Loading, empty, and error states

Use:

```text
OpenVtsLoader
OpenVtsEmptyState
OpenVtsErrorView
```

### Loading

Use full-screen loader only for first screen load.
Use inline loader for buttons and small sections.
Use skeleton later for premium list loading.

### Empty

Empty state must include:

- title,
- short explanation,
- optional action.

Example:

```text
No vehicles found
Try changing the filter or add a new vehicle.
```

### Error

Error state must include:

- clear human message,
- retry action where possible,
- no raw backend exception.

Do not show stack traces or raw JSON to users.

---

## 29. Feedback/toast rules

Use shared helper:

```text
lib/shared/helpers/toast_helper.dart
```

or future:

```text
OpenVtsFeedback
```

Do not call `ScaffoldMessenger` directly from every screen.

Feedback messages should be:

- short,
- human,
- action-aware,
- not technical unless it is a diagnostic/admin screen.

---

## 30. Navigation and shell UX

Mobile should use role-specific shell screens.

```text
SuperadminShell
AdminShell
UserShell
```

### Bottom navigation

Use no more than 5 primary nav items.

Example Superadmin:

```text
Dashboard
Map
Vehicles
Reports
Settings/More
```

Example Admin:

```text
Dashboard
Map
Vehicles
Users
Settings/More
```

Example User:

```text
Dashboard
Map
Vehicles
Notifications
Settings/More
```

Secondary screens should be accessible from More/Settings/Quick Actions.

---

## 31. Screen layout patterns

### Dashboard

Dashboard should answer:

```text
What needs attention right now?
```

Recommended sections:

```text
Header / role context
KPI metrics
Live status summary
Recent alerts/activity
Quick actions
```

### Vehicle list

Recommended sections:

```text
Header
Search field
Status filter chips
Vehicle list/cards
```

Vehicle card should show:

```text
vehicle name/plate
status
speed or last known state
last update time
location summary
quick action when needed
```

### Vehicle detail

Recommended sections:

```text
Vehicle identity + status
Live metrics
Current location
History/replay
Commands if permitted
Settings/documents if permitted
```

Use progressive disclosure. Do not put everything on one screen.

### Settings

Use grouped rows:

```text
Account
Preferences
Notifications
Security
Support
Danger zone if needed
```

---

## 32. Map UI rules

The map is the most important mobile surface.

### Required map layers

```text
Tile layer
Route/polyline layer
Geofence/POI layer
Vehicle marker layer
Selected vehicle overlay
Map controls
Bottom panel/dock
```

### Rules

- Map can be full-bleed.
- Controls must respect safe areas.
- Floating controls must be 44dp minimum.
- Tile layer must not rebuild on every marker update.
- Visual effects apply only to map/tile layer, not the whole UI.
- Selected vehicle panel should show speed, ignition, last update, address, and key actions.

### Replay

Replay UI should include:

```text
route line
start/end points
directional arrows
stoppage points
metrics panel
play/pause controls
speed control
```

Use subtle route styling, not neon lines.

---

## 33. Data display rules

### Unknown values

Use:

```text
—
```

Do not show:

```text
null
undefined
N/A
```

Do not use `0` for unknown. Zero is real data.

### Dates

All dates must go through:

```text
lib/core/utils/date_time_formatter.dart
```

Do not format dates directly inside screens.

### Units

Units must be centralized later:

```text
km / miles
km/h / mph
liters / gallons if needed
```

Do not hardcode unit logic inside every widget.

---

## 34. Localization and RTL

All user-visible strings should become localizable.

Use directional layout:

```dart
EdgeInsetsDirectional
AlignmentDirectional
TextAlign.start
CrossAxisAlignment.start
```

Avoid:

```dart
EdgeInsets.only(left: ...)
Alignment.centerLeft
TextAlign.left
```

---

## 35. Accessibility

Every screen must respect:

- 44dp minimum touch target,
- readable contrast,
- no color-only status,
- semantic labels for icon-only buttons,
- dynamic text scaling,
- safe areas,
- keyboard accessibility where applicable.

---

## 36. Performance rules

### Do not do heavy work in `build()`

Do not put inside `build()`:

- API calls,
- JSON parsing,
- sorting huge lists,
- route simplification,
- heavy permission calculations,
- heavy date formatting loops.

### Lists

Use:

```dart
ListView.builder
```

for dynamic lists.

### Images

Use cached image component for network images.

### Map

Use:

```text
RepaintBoundary
throttled marker updates
separate marker state
separate map tile layer
```

---

## 37. Feature creation process

When creating a new screen/feature, follow this order.

### Step 1 — Add endpoint

Update:

```text
lib/core/api/api_endpoints.dart
```

### Step 2 — Add model

Use role model or shared model.

```text
features/<role>/models/<model>.dart
```

or

```text
shared/models/<model>.dart
```

### Step 3 — Add service method

Update role service:

```text
features/<role>/services/<role>_<feature>_service.dart
```

### Step 4 — Add provider/controller

Update:

```text
features/<role>/controllers/<role>_providers.dart
```

or create:

```text
features/<role>/controllers/<role>_<feature>_controller.dart
```

### Step 5 — Add screen

Add screen in:

```text
features/<role>/screens/<feature>/<role>_<feature>_screen.dart
```

### Step 6 — Use shared components

Before creating new UI, check:

```text
lib/shared/widgets/
```

### Step 7 — Add route

Update:

```text
lib/core/router/route_paths.dart
lib/core/router/app_router.dart
```

### Step 8 — Verify checklist

Run screen acceptance checklist from this document.

---

## 38. Example end-to-end feature flow

Example: Superadmin vehicles screen.

```text
ApiEndpoints.superadmin.vehicles
  -> SuperadminVehicleService.getVehicles()
    -> superadminVehicleControllerProvider
      -> SuperadminVehiclesScreen
        -> OpenVtsPageScaffold
        -> OpenVtsSearchField
        -> VehicleCard
        -> OpenVtsLoader / OpenVtsErrorView / OpenVtsEmptyState
```

This is the exact pattern every feature should follow.

---

## 39. Copilot rules

When using GitHub Copilot, include this instruction:

```text
You are working on the OpenVTS Flutter app.
Follow docs/OpenVTS_Flutter_Complete_Development_Guide.md exactly.

Architecture:
- Use simple role-based layered architecture.
- Screens call Riverpod controllers/providers only.
- Controllers call role-wise services.
- Services call central ApiClient.
- ApiClient uses centralized endpoints and Dio.
- Do not call Dio directly from screens.
- Do not hardcode endpoint strings in screens/services.
- Do not put token logic in screens.

UI/UX:
- Match OpenVTS web/product design language.
- Use Inter, monochrome-first palette, border-led cards, restrained styling.
- Use theme tokens from lib/core/theme.
- Use shared widgets from lib/shared/widgets before raw Flutter widgets.
- Do not use raw colors, random TextStyle, random spacing, or one-off buttons.
- Keep mobile screens touch-first, clean, premium, and operational.

State:
- Use Riverpod for API loading/error/data state.
- Do not use setState for API data.
- Do not parse JSON in widgets.

Before finishing:
- Verify route guards, loading, empty, error states, token usage, theme tokens, and shared component usage.
```

---

## 40. Strict do-not list

Do not:

- call Dio directly from screens,
- hardcode API endpoints inside screens,
- store tokens inside widgets,
- parse raw JSON inside widgets,
- create all business logic in one giant file,
- mix Superadmin/Admin/User service logic randomly,
- create random common folders without purpose,
- create a new button style per screen,
- create a new card style per screen,
- use raw `Colors.*` in feature UI,
- use raw `TextStyle` in feature UI,
- copy desktop tables directly into mobile,
- show raw API errors,
- rebuild the full map on every socket update,
- use heavy shadows, neon, gradients, or generic template visuals.

---

## 41. Production screen acceptance checklist

Before a screen is approved:

### Architecture

- [ ] Screen does not call Dio directly.
- [ ] Screen uses Riverpod provider/controller.
- [ ] Service uses `ApiClient`.
- [ ] Endpoint is defined in `ApiEndpoints`.
- [ ] Token logic is not inside screen.
- [ ] JSON parsing is not inside screen.

### UI/UX

- [ ] Uses `OpenVtsPageScaffold` where appropriate.
- [ ] Uses shared OpenVTS widgets where available.
- [ ] Uses theme colors, not raw colors.
- [ ] Uses theme typography, not random `TextStyle`.
- [ ] Uses spacing/radius tokens.
- [ ] Looks consistent with OpenVTS web/dashboard style.
- [ ] No generic Flutter admin-template feel.

### State

- [ ] Loading state exists.
- [ ] Empty state exists where relevant.
- [ ] Error state exists with retry where possible.
- [ ] Submit actions prevent double tap.
- [ ] Local UI state is not mixed with API data state.

### Mobile usability

- [ ] Touch targets are at least 44dp.
- [ ] Safe areas are respected.
- [ ] Keyboard does not hide primary action.
- [ ] Scrollable content has bottom clearance.
- [ ] Destructive actions ask confirmation.

### Data

- [ ] Unknown values use `—`.
- [ ] Dates go through centralized formatter.
- [ ] Units are not randomly hardcoded.
- [ ] Status uses text/icon plus color.
- [ ] No raw backend errors shown.

### Performance

- [ ] Dynamic lists use builder/sliver APIs.
- [ ] No heavy work inside `build()`.
- [ ] Map updates are isolated.
- [ ] Static widgets are `const` where possible.

---

## 42. Final standard

OpenVTS Flutter must be simple enough to build fast, but disciplined enough to remain clean.

The final standard is:

```text
Centralized API
Centralized endpoints
Centralized token handling
Role-wise business logic
Role-wise screens
Shared OpenVTS widgets
Riverpod state
OpenVTS theme tokens
Inter typography
Mobile-first layouts
Web-to-mobile visual consistency
```

If a new file, screen, or component does not fit this document, it should be revised before merging.

The goal is not only to make a working Flutter app.
The goal is to create a Tier-1 OpenVTS product ecosystem where web, mobile, and future desktop feel like one serious software brand.


---

# Typography implementation: Inter primary + Satoshi secondary

## Final decision

OpenVTS Flutter uses a two-font system:

| Role | Font | Required usage |
|---|---|---|
| Primary product UI font | **Inter** | All normal screens, forms, lists, cards, dashboard numbers, map labels, settings, reports, navigation, and body text |
| Secondary brand/editorial font | **Satoshi** | Only controlled brand moments such as splash, onboarding headline, campaign/hero-like heading, premium empty state title, or logo-adjacent brand copy |

Do not use Satoshi as the default app font. Dense fleet software must stay readable and consistent, so Inter remains the product UI base.

## Boilerplate implementation files

```text
lib/core/theme/open_vts_typography.dart
lib/core/theme/open_vts_theme.dart
assets/fonts/README.md
assets/fonts/inter/
assets/fonts/satoshi/
pubspec.yaml
```

## Code rules

Use the theme for normal text:

```dart
Text(
  'Vehicles',
  style: Theme.of(context).textTheme.titleLarge,
)
```

Use OpenVTS typography tokens only when a shared widget needs explicit style:

```dart
Text(
  value,
  style: OpenVtsTypography.numeric,
)
```

Use Satoshi only through approved brand styles:

```dart
Text(
  'Track Without Limits',
  style: OpenVtsTypography.brandTitle,
)
```

Do not create raw screen-level font styles:

```dart
// Not allowed in feature screens
TextStyle(fontFamily: 'Satoshi', fontSize: 29, color: Colors.black)
```

## Production font asset policy

The boilerplate includes the font implementation structure, but it does not ship actual font files. Add licensed font files locally when preparing production builds:

```text
assets/fonts/inter/
  Inter-Regular.ttf
  Inter-Medium.ttf
  Inter-SemiBold.ttf
  Inter-Bold.ttf

assets/fonts/satoshi/
  Satoshi-Regular.ttf
  Satoshi-Medium.ttf
  Satoshi-Bold.ttf
```

Then uncomment the `fonts:` block in `pubspec.yaml`. Never commit or distribute font files unless your license permits it.

## Copilot rule

When creating Flutter UI, Copilot must preserve this typography system:

- Inter is default.
- Satoshi is secondary and rare.
- No raw `TextStyle` in feature screens.
- No new random font family.
- Use tabular figures for operational numbers.
