# OpenVTS Font Assets

OpenVTS uses:

- **Primary product UI font:** Inter
- **Secondary brand/editorial font:** Satoshi

## Current boilerplate behavior

The boilerplate uses the `google_fonts` package to apply Inter immediately during development.
This keeps the starter project runnable without shipping font files.

## Production/offline build policy

For final production builds, add licensed font files locally and register them in `pubspec.yaml`.

Expected local paths:

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

Then uncomment the `fonts:` block in `pubspec.yaml`.

Do not commit or distribute font files unless your license permits it.
