# GitHub Copilot Rules for OpenVTS Flutter

## Main rule

Keep the app simple, role-based, and consistent with the web product.

## When creating UI

- Use OpenVTS shared widgets first.
- Use theme tokens from `core/theme`.
- Do not hardcode random colors or text styles.
- Use restrained, monochrome-first design.
- Keep cards border-based, not shadow-heavy.
- Keep mobile screens readable and spacious.

## When creating API code

- Add endpoint to `core/api/api_endpoints.dart`.
- Call backend only through `ApiClient`.
- Put role-specific logic inside that role's `services/` folder.
- Use Riverpod controller/provider for state.
- Do not call Dio directly from UI.

## When creating a new screen

1. Add route path.
2. Add screen under role folder.
3. Add service if API/business logic is needed.
4. Add controller/provider if dynamic data is needed.
5. Use shared widgets for UI.
6. Add screen-specific widgets inside that screen folder only if not reused.

## Preferred flow

```text
Screen -> Controller -> Service -> ApiClient -> Backend
```


## Environment rules

- Do not hardcode API base URLs in any feature file.
- Use `AppConfig.apiBaseUrl` only.
- Keep API paths inside `core/api/api_endpoints.dart`.
- Keep `.env.example` updated whenever a new environment key is added.
