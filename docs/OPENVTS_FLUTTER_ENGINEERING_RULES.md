# OpenVTS Flutter Engineering Rules

OpenVTS Flutter follows the simple role-based layered architecture:

```text
Screen / Widget
  -> Riverpod Controller / Provider
    -> Role-wise Service / Business Logic
      -> Central ApiClient
        -> Dio
          -> Backend API
```

Run the guardrail script before merging architecture-sensitive changes:

```bash
bash tool/check_openvts_architecture.sh
```

## Guardrails

1. **No raw app feedback in screens**
   - Do not use `ScaffoldMessenger` or raw `SnackBar` outside `lib/shared/helpers/toast_helper.dart`.
   - Use `ToastHelper` for success, error, and info messages.

2. **No direct Dio outside approved infrastructure**
   - Dio setup belongs in `core/api`, `core/providers`, and interceptors.
   - Feature code should call role services, and role services should call `ApiClient`.
   - Temporary exceptions must stay explicit in `tool/check_openvts_architecture.sh`.

3. **No hardcoded backend endpoints outside endpoint config**
   - Backend endpoint paths must live in `lib/core/api/api_endpoints.dart`.
   - Route paths belong in `lib/core/router/route_paths.dart`.
   - Socket namespace/config and public external URL helpers may be allowed explicitly.

4. **No service-provider reads in feature screens/widgets**
   - Screens/widgets must not call `ref.read(fooServiceProvider)` or `ref.watch(fooServiceProvider)`.
   - Screens/widgets should watch controller/provider state and dispatch controller actions.

5. **No `FutureBuilder` for API-driven feature data**
   - API loading/data/error state belongs in Riverpod providers/controllers.
   - Temporary exceptions must remain narrow and documented in the script allowlist.

6. **No blanket long read timeouts**
   - `receiveTimeout: Duration(seconds: 60)` requires the inline marker:
     `// heavy-operation-timeout`
   - Use normal API options for ordinary list/detail/settings/support reads.
   - Reserve heavy timeouts for replay, history, export, upload/download, and large logs.

7. **No runtime GoogleFonts in `lib/`**
   - Do not import `google_fonts` or call `GoogleFonts.*` in app code.
   - Use local/system font resolution through `OpenVtsTypography.primaryFontFamily`.
   - Only register licensed local font files in `pubspec.yaml`.

## Temporary Allowlist Policy

Allowlist entries are not permanent architecture exemptions. They must be:

- narrow to a specific file or folder,
- tied to an active migration,
- removed when the feature is refactored,
- reviewed during architecture cleanup work.

Do not add broad allowlist patterns to make the script pass.
