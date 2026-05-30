# Localization QA Checklist

## Summary of Changes

### Flutter i18n Infrastructure Setup
✅ **Created `l10n.yaml`** - Flutter i18n build configuration
✅ **Created `lib/l10n/` ARB files:**
  - `app_en.arb` - English (base language, 77 strings)
  - `app_hi.arb` - Hindi translations
  - `app_ar.arb` - Arabic translations
  - `app_es.arb` - Spanish translations
  - `app_fr.arb` - French translations
  - `app_pt.arb` - Portuguese translations

✅ **Generated localization classes** - `flutter gen-l10n` produced:
  - `app_localizations.dart` (main delegate)
  - `app_localizations_*.dart` (language-specific implementations)

✅ **Wired MaterialApp** - Added `AppLocalizations.delegate` to localizationsDelegates

✅ **App startup hydration** - Updated `auth_controller.dart` to rehydrate preferences on session restore

✅ **Added `generate: true`** to `pubspec.yaml` to enable localization code generation

### Localized Strings Coverage (Phase 1 - Foundation)

Currently migrated/localized:
- Settings labels: "Settings", "Localization", "Language", "Theme", "Date Format", "Time Format", "Timezone"
- Common actions: "Save", "Cancel", "Edit", "Search", "Delete", "Reset", "Close", "Back", "Next"
- Theme options: "Light", "Dark", "System"
- Language names: "English", "Hindi", "Arabic", "Spanish", "French", "Portuguese"
- Common UI: "Profile", "Logout", "Login", "Home", "Dashboard"
- Status messages: "Loading", "Error", "Success", "Warning"
- Date/time: "Preview", "Select Language", "Select Theme", etc.

### NOT Yet Migrated (Hardcoded English)
- Role-specific pages: Administrators list, Payments, Support
- Admin/Superadmin settings screens UI (still uses hardcoded strings)
- User profile sections (hardcoded English)
- Navigation labels throughout the app
- Role switcher UI
- Live map labels
- Route optimization UI

**Note:** This is intentional per requirements. Only localized strings update with language changes until full migration.

---

## QA Test Plan

### Prerequisites
- App installed/running on device or emulator
- All three roles available for testing (Superadmin, Admin, User)
- Logged into each role sequentially

---

## SUPERADMIN QA (Settings > Localization)

### Theme Persistence QA
- [ ] Navigate to Superadmin > Settings > Localization
- [ ] Select "Dark" and click Save
  - [ ] App immediately switches to dark theme (no restart required)
  - [ ] Dark colors visible on all screens
- [ ] Select "Light" and click Save
  - [ ] App immediately switches to light theme
  - [ ] Light colors visible
- [ ] Select "System" and click Save
  - [ ] App follows device theme setting
  - [ ] Theme changes if device setting is changed
- [ ] Close app completely (swipe from recents on mobile)
- [ ] Reopen app
  - [ ] Theme preference persists (no flashing to default)

### Date Format Persistence QA
- [ ] Select date format "DD MMM YYYY" (e.g., "25 Dec 2025")
- [ ] Click Save
  - [ ] Date preview updates immediately
  - [ ] Administrators list: dates show selected format
  - [ ] Single Admin detail: dates show selected format
  - [ ] Any payment transactions: dates show selected format
  - [ ] Any support tickets: dates show selected format
- [ ] Select different date format (e.g., "YYYY-MM-DD")
- [ ] Click Save
  - [ ] All dates immediately update to new format across all screens
  - [ ] No page refresh needed
- [ ] Close and reopen app
  - [ ] Date format persists

### Time Format Persistence QA
- [ ] Check "24-Hour Time" and click Save
  - [ ] Time format updates to 24-hour (14:30 instead of 2:30 PM)
  - [ ] All timestamps in app update
  - [ ] Date preview shows 24-hour format
- [ ] Uncheck "24-Hour Time" and click Save
  - [ ] Time format updates to 12-hour (2:30 PM)
  - [ ] All timestamps in app update
- [ ] Close and reopen app
  - [ ] Time format persists

### Language Change QA
- [ ] Select "English" language and Save
  - [ ] MaterialApp locale updates
  - [ ] Localized strings update to English
  - [ ] Hardcoded English strings remain (expected)
  - [ ] Date picker shows English (Material)
- [ ] Select "Hindi" language and Save
  - [ ] Localized strings update to Hindi
  - [ ] "Settings" → "सेटिंग्स"
  - [ ] "Save" → "सहेजें"
  - [ ] Material UI (buttons, dialogs) show Hindi labels
  - [ ] Date picker shows Hindi numerals/text
- [ ] Select "Arabic" language and Save
  - [ ] Localized strings update to Arabic
  - [ ] "Settings" → "الإعدادات"
  - [ ] Date picker shows Arabic numerals
- [ ] Try "Spanish", "French", "Portuguese"
  - [ ] Each has appropriate translations
- [ ] Close and reopen app
  - [ ] Selected language persists
- [ ] Verify hardcoded English strings remain unchanged (expected)

### Timezone Persistence QA
- [ ] Select timezone and Save
  - [ ] Setting persists
  - [ ] If date/time display uses timezone, verify correctness
- [ ] Close and reopen app
  - [ ] Timezone persists

### No Blocking of Navigation
- [ ] While on Superadmin > Settings > Localization
- [ ] Rapidly change settings and click Save multiple times
  - [ ] App remains responsive
  - [ ] Can navigate away without waiting for saves to complete
  - [ ] No network delays block UI

### Regression - Superadmin Core Features
- [ ] Administrators list loads correctly
- [ ] Can view single Admin details
- [ ] Payments page loads correctly
- [ ] Support tickets load correctly
- [ ] Role switching works (if available)

---

## ADMIN QA (Settings > Localization)

### Theme Save & Persist
- [ ] Log in as Admin user
- [ ] Navigate to Admin > Settings > Localization
- [ ] Change theme to Dark, save
  - [ ] App immediately shows dark theme
- [ ] Change theme to Light, save
  - [ ] App immediately shows light theme
- [ ] Close and reopen app
  - [ ] Theme persists

### Date Format Save & Persist
- [ ] Select different date format and save
  - [ ] Admin pages reflect date format where migrated
- [ ] Verify dates on:
  - [ ] Admin list (if admin list exists)
  - [ ] Any transaction/ticket pages
- [ ] Close and reopen app
  - [ ] Date format persists

### Time Format Save & Persist
- [ ] Toggle 24-hour format on/off and save
  - [ ] Times update across Admin pages
- [ ] Close and reopen app
  - [ ] Time format persists

### Language Change
- [ ] Change language to non-English option
  - [ ] Localized strings update
  - [ ] Material UI adapts
- [ ] Close and reopen app
  - [ ] Language persists

### Regression - Admin Core Features
- [ ] Admin dashboard loads correctly
- [ ] Can navigate to admin-specific pages
- [ ] No crashes when changing settings

---

## USER QA (Settings > Localization)

### Theme Save & Persist
- [ ] Log in as User
- [ ] Navigate to User > Settings > Localization
- [ ] Change theme to Dark, save
  - [ ] App immediately shows dark theme
- [ ] Change theme to Light, save
  - [ ] App immediately shows light theme
- [ ] System theme: verify it follows device setting
- [ ] Close and reopen app
  - [ ] Theme persists

### Date Format Save & Persist
- [ ] Select date format and save
  - [ ] User pages reflect date format where migrated
  - [ ] Trip history/vehicle history dates show selected format
- [ ] Select different date format and save
  - [ ] All dates update immediately
- [ ] Close and reopen app
  - [ ] Date format persists

### Time Format Save & Persist
- [ ] Toggle 24-hour format and save
  - [ ] Times update across User pages
- [ ] Close and reopen app
  - [ ] Time format persists

### Language Change
- [ ] Select non-English language and save
  - [ ] Localized strings update
  - [ ] Material UI adapts
- [ ] Close and reopen app
  - [ ] Language persists

### Regression - User Core Features
- [ ] User dashboard/home loads correctly
- [ ] Can navigate to user-specific pages
- [ ] Map/route optimization pages load
- [ ] No crashes when changing settings

---

## Cross-Role QA

### Login & Role Switch Hydration
- [ ] Log out completely
- [ ] Log in as Superadmin
  - [ ] Superadmin preferences load (if saved)
  - [ ] Date/time/theme from last Superadmin session apply
- [ ] Role switch to Admin (if available)
  - [ ] Admin preferences apply
  - [ ] Date/time/theme from last Admin session apply
- [ ] Role switch to User
  - [ ] User preferences apply
  - [ ] Date/time/theme from last User session apply
- [ ] Log out and log back in as Superadmin
  - [ ] Superadmin preferences still correct

### Session Restore
- [ ] Set preferences (theme, date format, language) for current role
- [ ] Kill app (don't just navigate away)
- [ ] Reopen app
  - [ ] Preferences restore automatically (no login required if token still valid)
  - [ ] App starts with correct theme, date format, language

### LocalCache Fallback
- [ ] Verify app starts correctly even if backend settings API hasn't loaded yet
- [ ] No crashes on empty/missing role settings
- [ ] LocalCache values use as fallback

---

## Localization Strings QA

### Supported Languages
- [ ] English (en) - all strings present
- [ ] Hindi (hi) - all strings present
- [ ] Arabic (ar) - all strings present
- [ ] Spanish (es) - all strings present
- [ ] French (fr) - all strings present
- [ ] Portuguese (pt) - all strings present

### String Completeness
- [ ] No "???" or placeholder text in any language
- [ ] No missing placeholders in parameterized strings (e.g., `previewDate`, `confirmDiscardMessage`)
- [ ] Settings labels use correct localized strings
- [ ] Common actions (Save, Cancel, etc.) use localized strings
- [ ] Date/time preview cards show localized strings

### Locale-Specific Date Formatting
- [ ] When language changes, date picker locale adapts (Material Design)
- [ ] Date picker shows correct language numerals/text
- [ ] Time format respects 12h/24h setting

### Hardcoded String Expectations
- [ ] Verify that hardcoded English strings remain:
  - [ ] Role-specific page titles/labels
  - [ ] Admin/Superadmin feature names
  - [ ] Navigation drawer items (until migrated)
  - [ ] Chart labels, vehicle info
- [ ] These should NOT change when language changes (expected behavior during migration phase)

---

## Error Handling & Edge Cases

### Invalid Date Format
- [ ] Enter invalid date format string in settings
  - [ ] App should fall back to default format
  - [ ] No crash

### Unsupported Language Code
- [ ] Verify app handles unsupported language gracefully
  - [ ] Falls back to English
  - [ ] No crash

### Missing LocalCache
- [ ] On fresh install, preferences should be:
  - [ ] English, Light theme, 12-hour, "DD MMM YYYY" format
  - [ ] App starts normally with defaults

### Network Issues During Settings Save
- [ ] Simulate offline by toggling airplane mode
- [ ] Try to save settings
  - [ ] Error message shows
  - [ ] LocalCache retains previous values
  - [ ] No data corruption

### Multiple Rapid Saves
- [ ] Rapidly change settings and click Save multiple times
  - [ ] Settings eventually stabilize
  - [ ] No crash
  - [ ] Final state is persisted

---

## Regression Tests

### Core App Functionality
- [ ] Login screen works
- [ ] Login succeeds with correct credentials
- [ ] Role list shows after login
- [ ] Can switch roles
- [ ] Can log out
- [ ] Can log back in

### API Integration
- [ ] Settings API calls still work
- [ ] Backend receives correct payloads
- [ ] Backend returns expected responses
- [ ] No new API contract changes

### UI Rendering
- [ ] No layout shifts when settings change
- [ ] No flickering or visual glitches
- [ ] Theme change is smooth
- [ ] Language change doesn't break layouts

### Performance
- [ ] App startup time is not degraded
- [ ] Settings changes are responsive (<500ms)
- [ ] No memory leaks on rapid theme/language changes
- [ ] Navigation is smooth

---

## Test Completion Checklist

- [ ] All Superadmin tests pass
- [ ] All Admin tests pass
- [ ] All User tests pass
- [ ] Cross-role hydration works
- [ ] Session restore works
- [ ] Localization strings complete and correct
- [ ] No hardcoded strings changed (expected)
- [ ] Error handling works
- [ ] Regression tests pass
- [ ] No crashes observed
- [ ] All preferences persist across app restart

---

## Known Limitations (Phase 1)

✅ Implemented:
- Language selection with locale change
- Theme persistence and immediate update
- Date/time format persistence and immediate update
- Timezone storage
- Session restore hydration
- LocalCache fallback
- Localized strings for Settings UI and common actions

⏳ Not Yet Implemented (Future Phase):
- Full app string migration to use AppLocalizations
- Hardcoded English strings throughout remain unchanged
- RTL (Right-to-Left) layout support for Arabic
- Locale-specific number formatting

---

## Notes for Testers

1. **Hardcoded English Strings Expected**: During this migration phase, only migrated strings change when language changes. This is intentional.
2. **No Page Reload Required**: All settings changes apply immediately via Riverpod state management.
3. **Preferences Follow User**: Each role maintains its own saved preferences. When you switch roles, those role's preferences apply.
4. **LocalCache is Source of Truth**: Persisted preferences load from local cache on app startup, not from backend.
5. **Date Formatting**: Backend uses Moment.js patterns (YYYY, DD, etc.) which are converted to Dart intl patterns (yyyy, dd, etc.) automatically.

