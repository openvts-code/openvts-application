#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

report_matches() {
  local title="$1"
  local pattern="$2"
  shift 2
  local output

  output="$(rg -n --hidden --glob '!build/**' --glob '!android/.gradle/**' "$pattern" "$@" || true)"
  if [[ -n "$output" ]]; then
    echo
    echo "[$title]"
    echo "$output"
    status=1
  fi
}

filter_matches() {
  local title="$1"
  local pattern="$2"
  local path="$3"
  shift 3
  local output

  output="$(rg -n --hidden --glob '!build/**' --glob '!android/.gradle/**' "$pattern" "$path" "$@" || true)"
  if [[ -n "$output" ]]; then
    while IFS= read -r allow; do
      [[ -z "$allow" ]] && continue
      output="$(printf '%s\n' "$output" | rg -v "$allow" || true)"
    done
  fi
  if [[ -n "$output" ]]; then
    echo
    echo "[$title]"
    echo "$output"
    status=1
  fi
}

echo "Checking OpenVTS Flutter architecture guardrails..."

# 1. Feedback must go through ToastHelper.
filter_matches \
  "No raw ScaffoldMessenger/SnackBar outside ToastHelper" \
  "ScaffoldMessenger|SnackBar\\(" \
  "lib" \
  "lib/shared/helpers/toast_helper.dart"

# 2. Dio is allowed only in central API plumbing and temporary controller/service migration zones.
filter_matches \
  "No Dio import/use outside approved API layers" \
  "package:dio/dio.dart|\\bDio\\b|DioException|Options\\(" \
  "lib" \
  "lib/core/api/" \
  "lib/core/providers/"

# 3. Backend endpoint strings must live in ApiEndpoints. Route paths and external/map URLs are allowed.
filter_matches \
  "No hardcoded backend endpoint strings outside endpoint/router/socket config" \
  "['\"]/((auth|admin|superadmin|user|api|vehicletypes|timezones|documenttypes|countries|states|cities|mobileprefix)[^'\"]*)['\"]" \
  "lib" \
  "lib/core/api/api_endpoints.dart" \
  "lib/core/router/route_paths.dart" \
  "lib/core/socket/" \
  "lib/core/notifications/mobile_push_navigation.dart" \
  "lib/features/live_map/models/live_map_role_config.dart" \
  "lib/features/user/utils/route_optimisation_google_maps.dart" \
  "https?://"

# 4. Screens/widgets should not read service providers directly.
filter_matches \
  "No ServiceProvider reads inside feature screens/widgets" \
  "ref\\.(read|watch)\\([^\\)]*(serviceProvider|ServiceProvider)" \
  "lib/features" \
  "lib/features/.*/controllers/" \
  "lib/features/.*/services/"

# 5. FutureBuilder is banned for API-driven feature data, with a narrow temporary allowlist.
filter_matches \
  "No FutureBuilder in feature screens for API-driven data" \
  "FutureBuilder\\s*<|FutureBuilder\\s*\\(" \
  "lib/features" \
  "lib/features/live_map/screens/live_map_screen.dart" \
  "lib/features/admin/screens/logs/widgets/admin_telemetry_log_detail_sheet.dart" \
  "lib/features/admin/screens/logs/widgets/admin_vehicle_event_detail_sheet.dart"

# 6. Long receive timeout needs an explicit heavy-operation marker.
filter_matches \
  "No receiveTimeout 60s without heavy-operation-timeout comment" \
  "receiveTimeout:.*Duration\\(seconds: 60\\)(?!.*heavy-operation-timeout)" \
  "lib" \
  "--pcre2"

# 7. No runtime GoogleFonts usage.
report_matches \
  "No GoogleFonts import/use in lib" \
  "google_fonts|GoogleFonts" \
  "lib"

if [[ "$status" -ne 0 ]]; then
  echo
  echo "OpenVTS architecture guardrails failed."
  exit 1
fi

echo "OpenVTS architecture guardrails passed."
