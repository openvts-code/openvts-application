# OpenVTS — Final Cross‑Platform UI/UX Guidelines

> **Product:** OpenVTS ecosystem  
> **Targets:** Next.js marketing website, Next.js web dashboard, Flutter mobile app, Flutter tablet/desktop preview  
> **Purpose:** Create one Tier‑1 product ecosystem where website, web app, mobile app, and future desktop experiences feel like the same company, same operating system, and same design authority.  
> **Use this document as:** the UI/UX source of truth for GitHub Copilot, Flutter development, refactoring, reviews, and production QA.

---

## 0. Final decision

OpenVTS must not feel like separate products stitched together.

The user should feel:

```text
I saw the website.
I opened the web dashboard.
I installed the mobile app.
It is clearly the same serious infrastructure product.
```

The final UI direction is:

```text
Premium monochrome fleet command center
+ precise geospatial visual language
+ calm enterprise controls
+ native mobile usability
+ shared design tokens
+ shared component rules
```

OpenVTS is not a colorful SaaS template.  
OpenVTS is not a generic Flutter admin app.  
OpenVTS is not a copied desktop dashboard squeezed into mobile.

OpenVTS is a controlled, quiet, self‑hosted tracking infrastructure system.

---

## 1. Ecosystem design principle

### 1.1 One brand, different surfaces

OpenVTS has different interfaces, but one design DNA:

| Surface | Design role | UX behavior |
|---|---|---|
| Marketing website | Builds perception, trust, authority | Spacious, editorial, proof-led, visually iconic |
| Web dashboard | Full operational command center | Dense, powerful, multi-panel, table/map friendly |
| Mobile app | Touch-first fleet command center | Fast, focused, progressive, map-led |
| Tablet/desktop Flutter | Extended mobile command view | Adaptive layouts, split view where useful |

The same visual language must remain visible across all surfaces:

- Inter primary typography
- Satoshi secondary brand typography
- monochrome-first palette
- restrained status colors
- precise borders
- subtle translucent surfaces where justified
- premium card rhythm
- calm motion
- strong spacing
- geospatial/map-based visual identity

### 1.2 Same identity, native behavior

Do not copy layout blindly.

A web page can use:

- wide sidebars
- dense tables
- hover states
- mega panels
- multiple visible columns
- small secondary actions

Mobile should translate the same product into:

- bottom navigation
- bottom sheets
- one-column content
- sticky action zones
- segmented controls
- progressive detail screens
- full-width primary actions
- map overlays and docks
- large touch targets

Consistency means same system, not same pixel layout.

---

## 2. Design personality

Every OpenVTS interface must feel:

- exact
- calm
- premium
- mature
- engineered
- structured
- trustworthy
- globally credible
- operationally serious
- self-hosted and ownership-first

It must never feel:

- loud
- playful
- glossy
- over-colored
- template-like
- cartoonish
- cluttered
- cheaply futuristic
- over-animated
- generic SaaS
- default Flutter Material

The brand rule is simple:

```text
Structure creates trust.
Restraint creates luxury.
Consistency creates authority.
```

---

## 3. Web-to-Flutter visual translation

The existing web frontend uses CSS variables and premium utility classes. Flutter must translate them into tokens and shared widgets.

### 3.1 Token mapping

| Web design token/class | Flutter equivalent | Usage rule |
|---|---|---|
| `--background` | `OpenVtsColors.background` / dark background | Screen background |
| `--foreground` | `colorScheme.onSurface` / text primary | Primary text/icons |
| `--card-bg` | `OpenVtsCard`, glass map panel | Cards/panels |
| `--border` | `OpenVtsColors.border` / `BorderSide` | Card/input/divider border |
| `--accent` | `colorScheme.primary` | Primary action, active state, selected item |
| `.macos-card` | `OpenVtsCard(variant: subtle)` | Standard soft card |
| `.premium-card` | `OpenVtsCard(variant: elevated)` | Important grouped surface |
| `.glass-effect` | `OpenVtsGlassPanel` | Map overlays only, not normal CRUD cards |
| `.btn-primary` | `OpenVtsButton.primary` | Main CTA/action |
| `.btn-secondary` | `OpenVtsButton.secondary` | Secondary action |
| `.btn-ghost` | `OpenVtsButton.ghost` | Quiet action |
| `.input-field` | `OpenVtsTextField` | Forms/search/filter |
| `.pill` / `.badge` | `OpenVtsStatusChip` / `OpenVtsPill` | Status and filter chips |
| `.toast` | `OpenVtsFeedback` | Toast/snackbar feedback |
| `.dropdown-menu` | bottom sheet / popup menu | Mobile selection |
| `.modal-content` | `OpenVtsBottomSheet` / dialog | Mobile decision surfaces |
| `.heading-*` | `Theme.of(context).textTheme.*` | Typography scale |

### 3.2 Web visual details to preserve

From the current web app, Flutter should preserve:

- monochrome background/foreground system
- Inter typography
- translucent card concept, but used carefully
- 0.5px/1px precise borders
- soft premium shadows only where needed
- rounded 12–20px surfaces
- compact but readable text hierarchy
- muted semantic status language
- geospatial route/map/vehicle visual language

### 3.3 Web details to avoid copying directly

Do not directly copy:

- hover-dependent interactions
- desktop table density
- complex sidebars on phones
- mega menus
- tiny inline actions
- dashboard grids with too many widgets
- heavy glass effects on every mobile card
- decorative background animations inside operational screens

---

## 4. Flutter UI architecture for design consistency

### 4.1 Required UI folders

```text
lib/
├── core/
│   └── theme/
│       ├── open_vts_colors.dart
│       ├── open_vts_typography.dart
│       ├── open_vts_spacing.dart
│       ├── open_vts_radius.dart
│       ├── open_vts_motion.dart
│       ├── open_vts_shadows.dart
│       ├── open_vts_borders.dart
│       └── open_vts_theme.dart
│
├── shared/
│   └── widgets/
│       ├── open_vts_page_scaffold.dart
│       ├── open_vts_button.dart
│       ├── open_vts_card.dart
│       ├── open_vts_glass_panel.dart
│       ├── open_vts_text_field.dart
│       ├── open_vts_search_field.dart
│       ├── open_vts_status_chip.dart
│       ├── open_vts_metric_card.dart
│       ├── open_vts_list_tile.dart
│       ├── open_vts_empty_state.dart
│       ├── open_vts_error_view.dart
│       ├── open_vts_loader.dart
│       ├── open_vts_feedback.dart
│       ├── open_vts_bottom_sheet.dart
│       ├── open_vts_dialog.dart
│       ├── open_vts_segmented_control.dart
│       ├── open_vts_filter_chip_group.dart
│       └── open_vts_map_controls.dart
```

### 4.2 Component priority rule

When building a UI screen, use this order:

1. Existing OpenVTS shared widget.
2. Existing OpenVTS theme token.
3. Screen-specific widget inside that feature folder.
4. New shared widget only if the pattern repeats in two or more screens.
5. Raw Flutter widget only for layout primitives.

Do not create one-off styles inside screens.

### 4.3 First-launch surfaces

Splash and onboarding are first-launch brand surfaces, not generic placeholders.

Implementation locations:

```text
lib/features/auth/screens/splash_screen.dart
lib/features/onboarding/
assets/images/
```

Rules:

- Keep onboarding and splash visually premium but restrained.
- Use only the shared Dart token APIs: `OpenVtsColors`, `OpenVtsTypography`, `OpenVtsSpacing`, `OpenVtsRadius`.
- Do not invent alternate token class names such as `OpenVTSColors`.
- Register onboarding illustrations in `pubspec.yaml` under `assets/images/`.
- Keep the first-launch gate in `app_entry.dart`, before auth/session restore redirects.

### 4.4 Cross-platform preview contract

Flutter Web preview is a supported OpenVTS surface.

Rules:

- Keep the generated `web/` folder committed.
- If the project stops being web-configured, regenerate with `flutter create . --platforms=web`.
- Review splash, onboarding, and auth surfaces on both mobile and web preview after major UI changes.

---

## 5. Color system

### 5.1 Primary palette

Use these values as the ecosystem base.

| Token | Value | Meaning |
|---|---:|---|
| Brand Ink | `#141118` | Primary brand ink, authority, primary action |
| Brand Ink Soft | `#1D1821` | Deeper panels, secondary dark surface |
| White | `#FFFFFF` | Main light surface and dark-mode text/action |
| Background | `#FAFAFB` | Light app background |
| Surface | `#F4F3F6` | Soft panels/cards |
| Border | `#E7E3EA` | Default border |
| Divider | `#D8D3DC` | Stronger divider |
| Text Secondary | `#6B6570` | Secondary information |
| Text Tertiary | `#908A96` | Subtle meta labels |

### 5.2 Dark mode palette

Recommended Flutter dark tokens:

| Token | Value | Usage |
|---|---:|---|
| Dark Background | `#121015` | App background |
| Dark Surface | `#1A1620` | Cards/panels |
| Dark Surface Soft | `#211B27` | Elevated panels |
| Dark Border | `#342D3D` | Borders/dividers |
| Dark Text Primary | `#FFFFFF` | Primary text |
| Dark Text Secondary | `#B6AFBC` | Secondary text |
| Dark Text Tertiary | `#8E8795` | Meta labels |

### 5.3 Semantic colors

Use muted colors only.

| Semantic | Suggested value | Usage |
|---|---:|---|
| Success / Moving | `#2D6A4F` | Moving vehicle, success, online health |
| Warning / Idle | `#8A5C1D` | Idle, warning, pending |
| Danger / Stopped/Error | `#8A2E43` | Stopped, failed, critical |
| Info | `#455A64` | System info, neutral updates |

### 5.4 Color rules

#### Must do

- Use `Theme.of(context).colorScheme` or `OpenVtsColors`.
- Use status colors only for real status/state.
- Keep most UI neutral.
- Use accent/brand ink for one primary action per area.
- Make dark mode intentionally designed, not auto-inverted.

#### Must not do

```dart
Colors.blue
Colors.green
Colors.red
Colors.black
Color(0xFF123456)
```

Feature screens must not define raw colors.

---

## 6. Typography system

### 6.1 Font

Use a two-font OpenVTS typography system:

| Role | Font | Usage |
|---|---|---|
| Primary product UI font | **Inter** | Screens, forms, data, maps, cards, tables, navigation, settings, body text |
| Secondary brand/editorial font | **Satoshi** | Controlled brand moments only: splash, onboarding headline, campaign-style hero, premium empty-state headline, logo-adjacent typography |

Inter remains the default across:

- website
- web dashboard
- Flutter mobile
- Flutter tablet/desktop
- docs/tutorial UI where applicable

Satoshi must not replace Inter for dense product UI. It is a secondary brand accent, not the normal app font.

Flutter implementation paths:

```text
lib/core/theme/open_vts_typography.dart
lib/core/theme/open_vts_theme.dart
assets/fonts/inter/
assets/fonts/satoshi/
```

Current boilerplate behavior:

- `OpenVtsTheme` applies Inter through the Flutter theme.
- `OpenVtsTypography.primaryFontFamily = 'Inter'`.
- `OpenVtsTypography.secondaryFontFamily = 'Satoshi'`.
- `OpenVtsTypography.brandTitle` and `brandLabel` are the only approved secondary-font styles.

Production font asset path:

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

`pubspec.yaml` production registration:

```yaml
flutter:
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

Do not commit or distribute font files unless the license allows it.

### 6.2 Mobile type scale

| Use | Size / line height / weight |
|---|---|
| Screen title | 24 / 32 / 600 |
| Section title | 18 / 26 / 600 |
| Card title | 16 / 24 / 600 |
| Body | 14 / 22 / 400 |
| Body strong | 14 / 22 / 500 |
| Label | 13 / 18 / 500 |
| Metadata | 12 / 18 / 400 |
| Micro badge | 11 / 16 / 600 |
| Button | 14 / 20 / 600 |
| KPI number | 28–36 / 36–44 / 600 |

### 6.3 Tablet/desktop Flutter type scale

| Use | Size / line height / weight |
|---|---|
| Page title | 28–32 / 40 / 600 |
| Section title | 20–24 / 32 / 600 |
| Body | 14–16 / 24 / 400 |
| Dense table text | 13 / 18 / 400–500 |

### 6.4 Typography rules

- No raw `TextStyle` inside screens unless extending a theme style.
- Use tabular figures for speed, distance, odometer, engine hours, coordinates, counts, timestamps.
- Keep headings operational, not marketing-heavy.
- Use sentence case for labels and actions.
- Do not use tiny text below 11sp.
- Do not mix font families.

Correct:

```dart
Text(
  'Vehicles',
  style: Theme.of(context).textTheme.titleLarge,
)
```

Avoid:

```dart
Text(
  'Vehicles',
  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
)
```

---

## 7. Spacing and layout

### 7.1 Spacing scale

Use a disciplined 4/8-based scale:

```dart
OpenVtsSpacing.xxs = 4
OpenVtsSpacing.xs = 8
OpenVtsSpacing.sm = 12
OpenVtsSpacing.md = 16
OpenVtsSpacing.lg = 20
OpenVtsSpacing.xl = 24
OpenVtsSpacing.xxl = 32
OpenVtsSpacing.xxxl = 40
OpenVtsSpacing.section = 48
```

### 7.2 Mobile layout defaults

| Area | Rule |
|---|---|
| Page horizontal padding | 16dp |
| Dense panel padding | 12dp |
| Standard card padding | 16dp |
| Important card padding | 20–24dp |
| List row minimum height | 56dp |
| Touch target minimum | 44x44dp |
| Bottom nav content clearance | 80–96dp |
| Bottom sheet horizontal padding | 20dp |

### 7.3 Desktop/tablet adaptive layout

| Width | Layout behavior |
|---|---|
| `< 600` | mobile one-column layout |
| `600–900` | two-column where useful, bottom nav or rail |
| `900–1200` | navigation rail/sidebar, split panels |
| `> 1200` | desktop-like dashboard density |

### 7.4 Layout rules

- Maps may be full-bleed.
- CRUD screens should use padded content.
- Do not use random spacing values like 17, 23, 31.
- Keep vertical rhythm consistent.
- Use `SafeArea` on every screen shell.
- Use `EdgeInsetsDirectional`, not left/right hardcoding.

---

## 8. Radius, borders, shadows, and surfaces

### 8.1 Radius scale

```dart
OpenVtsRadius.sm = 8
OpenVtsRadius.md = 12
OpenVtsRadius.lg = 16
OpenVtsRadius.xl = 20
OpenVtsRadius.pill = 999
```

### 8.2 Border philosophy

OpenVTS is border-based premium, not shadow-based premium.

Use borders to define:

- cards
- inputs
- panels
- map overlays
- bottom sheets
- selected states
- tooltips

### 8.3 Shadow rules

Shadows are allowed only when they clarify elevation:

- floating map controls
- bottom sheets
- dropdowns
- selected marker panels
- important cards

Avoid heavy shadows on every item.

### 8.4 Surface variants

Define these shared surfaces:

| Surface | Flutter widget | Use |
|---|---|---|
| Standard card | `OpenVtsCard` | Lists, forms, grouped content |
| Elevated card | `OpenVtsCard.elevated` | KPI/group hero cards |
| Subtle card | `OpenVtsCard.subtle` | Dense secondary panels |
| Glass panel | `OpenVtsGlassPanel` | Map overlays only |
| Bottom sheet | `OpenVtsBottomSheet` | Mobile selection/filter/action panels |

---

## 9. Glass effect rule

The web app uses glass-like surfaces. Mobile should preserve the premium feel but restrict it.

### Use glass for

- map selected vehicle panel
- live map floating controls
- replay metrics overlay
- geofence drawing controls
- temporary command panels on map

### Do not use glass for

- normal forms
- long lists
- settings screens
- every dashboard card
- support ticket messages
- vehicle detail data groups

Glass must remain readable in light and dark mode.

---

## 10. Icon system

### 10.1 Icon family

Use one primary icon family only.

Recommended:

```text
Lucide-style monoline icons
```

This matches the web’s serious, thin, functional icon language.

### 10.2 Icon sizes

| Use | Size |
|---|---:|
| Micro metadata | 14–16 |
| Inline label | 16 |
| List leading icon | 20–24 |
| Card icon | 20–24 |
| Empty state icon | 40–56 |
| Map controls | 20–24 inside 44dp button |

### 10.3 Rules

- Icons support meaning; they do not decorate.
- Do not mix icon packs casually.
- Do not use cartoon/filled playful icons.
- Icon-only controls must have tooltip/semantic labels.

---

## 11. Buttons

### 11.1 Variants

| Variant | Use |
|---|---|
| Primary | One main action per screen/section |
| Secondary | Alternative action |
| Ghost | Quiet action |
| Danger | Destructive action |
| Icon | Map/action/tool buttons |

### 11.2 Button dimensions

| Type | Height | Radius |
|---|---:|---:|
| Standard | 44–48 | 10–12 |
| Compact | 36–40 | 8–10 |
| Icon | 44x44 | 10–12 |
| Form primary | 48 | 12 |

### 11.3 Button rules

- One primary action per area.
- Primary action full-width on mobile forms.
- Loading button disables itself.
- Dangerous action requires confirmation.
- Do not use raw `ElevatedButton`, `TextButton`, or `OutlinedButton` in feature screens if `OpenVtsButton` fits.

---

## 12. Inputs and forms

### 12.1 Text fields

Use:

```dart
OpenVtsTextField
OpenVtsSearchField
```

Do not use raw `TextFormField` in feature screens unless creating the shared component itself.

### 12.2 Field rules

- Height: 44–48dp.
- Label above field for complex forms.
- Helper text below field.
- Error text calm and direct.
- Prefix icon only when it improves recognition.
- Use correct keyboard types.
- Use autofill hints.
- Use input formatters for phone, number, IMEI, plate where useful.

### 12.3 Form layout

Mobile form structure:

```text
Screen title
Short helper text when needed
Grouped fields
Optional advanced section
Sticky bottom action
```

Do not create long ungrouped forms.

---

## 13. Cards and data blocks

### 13.1 Card anatomy

Standard card order:

```text
Header row
  icon/title/status
Metadata row
Main content
Optional actions
```

### 13.2 Vehicle card must show

- vehicle name / plate
- status chip
- speed or last known state
- last update time
- location summary when available
- driver/user where relevant
- quick action only if common

### 13.3 Metric card must show

- label
- main value
- unit
- optional trend/state
- timestamp/context if important

### 13.4 Rules

- Cards should group meaning, not decorate.
- Use consistent padding.
- Use one main visual anchor per card.
- Do not put too many actions in one card.
- Use bottom sheets for extra actions.

---

## 14. Navigation system

### 14.1 Mobile navigation

Use bottom navigation for primary role sections.

Maximum 5 visible items:

```text
Dashboard
Map
Vehicles
Notifications/Reports
More
```

Role-specific suggestions:

#### Superadmin

```text
Dashboard | Map | Vehicles | Admins | More
```

#### Admin

```text
Dashboard | Map | Vehicles | Users | More
```

#### User

```text
Dashboard | Map | Vehicles | Alerts | More
```

### 14.2 More screen

Use More for:

- drivers
- devices
- reports
- settings
- support
- profile
- billing/payment where applicable
- logs/diagnostics where permitted

### 14.3 Tablet/desktop navigation

Use navigation rail or sidebar when width allows.

Do not stretch mobile bottom nav into desktop awkwardly.

---

## 15. Role-based UI rules

OpenVTS roles include:

```text
SUPERADMIN
ADMIN
USER
SUBUSER
TEAM
DRIVER
```

### 15.1 Principle

The visual system stays the same.  
The available actions and information density change by role.

### 15.2 Superadmin UI

Superadmin can show more technical/system information:

- platform status
- admins
- payment/license information
- device/SIM management
- logs/diagnostics
- global vehicle map

Design should remain clean. Do not expose everything on the first screen.

### 15.3 Admin UI

Admin focuses on operations:

- users
- vehicles
- drivers
- devices
- map
- alerts
- reports

Admin UX should prioritize search, filters, and quick action flows.

### 15.4 User UI

User focuses on assigned vehicles and actions:

- live location
- history/replay
- alerts
- driver/vehicle details
- simple settings

User UI must be simpler than admin UI.

### 15.5 Permission behavior

- Hide actions the user cannot perform.
- Disable only when the action is temporarily unavailable.
- Backend remains authority.
- UI permissions are for clarity, not security.
- Dangerous changes require confirmation.

---

## 16. Screen patterns

### 16.1 Dashboard

Purpose:

```text
What needs attention right now?
```

Mobile structure:

```text
Header / role context
Critical KPI strip
Live status summary
Recent alerts/events
Quick actions
```

Rules:

- No chart overload.
- KPI values must be readable in 3 seconds.
- Alerts should be grouped by severity.
- Keep primary action obvious.

### 16.2 Live map

The map is the hero surface.

Structure:

```text
Full-bleed map
Top search/filter strip
Floating map controls
Vehicle markers
Selected vehicle bottom dock
Optional command/history/replay sheet
```

Rules:

- Map tile layer must not rebuild for every marker update.
- Visual effect applies only to tile layer, not UI overlays.
- Selected vehicle state must be obvious.
- Map controls must be 44dp minimum.
- Do not scatter controls everywhere.

### 16.3 Vehicle list

Structure:

```text
Page header
Search field
Status filter chips
Vehicle cards/list
Pagination/load-more/pull-refresh
```

Rules:

- Use cards on phones.
- Use table/data grid only on tablet/desktop.
- Last update must be human-readable.
- Unknown values use `—`.

### 16.4 Vehicle detail

Structure:

```text
Vehicle identity header
Status + live metrics
Location/address
Segmented sections:
  Overview
  History
  Commands
  Alerts
  Documents/Settings
```

Rules:

- Progressive disclosure.
- Do not show every raw field first.
- Technical IDs should have copy action.
- Commands must show risk/confirmation where needed.

### 16.5 Reports

Mobile reports should not copy desktop tables.

Use:

- filters in bottom sheets
- summary cards
- grouped result cards
- export/share actions
- compact charts only when useful

### 16.6 Settings

Use grouped settings rows.

Structure:

```text
Account
Preferences
Notifications
Map
Security
Support
Danger zone
```

Rules:

- Explain high-impact settings.
- Use switches for simple booleans.
- Use bottom sheets for selection.
- Keep dangerous actions separated.

### 16.7 Support/tickets

Structure:

```text
Ticket list
Status chips
Conversation view
Attachments
Reply box
```

Rules:

- Support must feel calm and trustworthy.
- Do not show internal/admin metadata to normal users unless useful.
- Show timestamps according to user locale/timezone.

---

## 17. Map and geospatial UI

### 17.1 Map layers

Keep map layers conceptually separate:

```text
Tile layer
Visual style/effect layer
Vehicle marker layer
Route/polyline layer
Geofence layer
POI/landmark layer
Selected vehicle overlay
Map controls
Bottom sheet/dock
```

### 17.2 Vehicle markers

Markers should:

- use vehicle type icon where available
- show moving/stopped/idle state clearly
- rotate smoothly when direction exists
- animate without jank
- keep labels optional
- avoid excessive color

### 17.3 Status colors

Use vehicle status colors only for status:

| State | Color behavior |
|---|---|
| Moving | muted success |
| Stopped | muted danger |
| Idle | muted warning |
| Offline | neutral/tertiary |
| Selected | brand ink/primary emphasis |

### 17.4 Selected vehicle panel

Show:

- vehicle name / plate
- status
- speed
- ignition
- last update
- address
- quick actions: Details, Replay/History, Command if permitted

### 17.5 Replay UI

Replay must include:

- start point
- end point
- route line
- directional arrows
- stoppage points
- play/pause
- replay speed
- distance
- speed
- odometer
- engine hours where available

Route style:

- subtle monochrome road-like line
- visible directional arrows
- no neon
- no overly thick route line
- stoppage points visually distinct but quiet

---

## 18. Tables, lists, and dense data

### 18.1 Mobile rule

Do not copy web tables directly to phone screens.

Use cards and progressive detail.

### 18.2 Tablet/desktop rule

Tables/data grids are allowed on wider layouts.

Rules:

- sticky header where useful
- comfortable row height
- clear truncation
- explicit action area
- horizontal scrolling only when unavoidable
- no cramped icon-only action clusters

### 18.3 Data value rules

| Value type | Rule |
|---|---|
| Unknown | show `—` |
| Zero | show `0` only when true zero |
| Date/time | use user preference/local timezone |
| Units | use user unit preference |
| IMEI/device ID | truncate in list, full in detail with copy |
| Coordinates | avoid in lists, show in detail/diagnostics |
| Raw API error | never show to users |

---

## 19. Feedback, loading, empty, and error states

### 19.1 Feedback

Use `OpenVtsFeedback`.

Do not call `ScaffoldMessenger` directly from feature screens.

Feedback style:

- short
- calm
- action-oriented
- no raw errors
- no stack traces

### 19.2 Loading

Use:

- skeleton cards for initial list/dashboard loading
- inline loader for small components
- button loader for submit actions
- pull-to-refresh for lists

Avoid full-screen spinner unless app is bootstrapping.

### 19.3 Empty states

Empty state structure:

```text
Icon/visual
Clear title
Short explanation
Optional action
```

Examples:

```text
No vehicles found
Try changing the filter or add a new vehicle.
```

```text
No route history
This vehicle has no route data for the selected date.
```

### 19.4 Error states

Error structure:

```text
Human message
Retry action
Optional support/diagnostics path
```

Never show raw backend exception.

---

## 20. Motion and interaction

### 20.1 Motion character

OpenVTS motion should be:

- fast
- minimal
- purposeful
- controlled
- almost invisible

### 20.2 Timing

| Motion | Duration |
|---|---:|
| Press feedback | 80–120ms |
| Micro interaction | 120–180ms |
| Bottom sheet/dialog | 180–240ms |
| Screen transition | 200–260ms |
| Map marker movement | data-dependent, smooth linear |

### 20.3 Rules

- Motion must guide attention or confirm action.
- Avoid bounce and playful spring effects.
- Respect reduced motion settings.
- Do not animate large layouts unnecessarily.
- Avoid multiple competing animations.

---

## 21. Accessibility and internationalization

### 21.1 Accessibility

Every screen must support:

- 44x44dp minimum touch targets
- high contrast
- readable text at scaling
- semantic labels
- icon button tooltips
- visible focus state for web/desktop preview
- no color-only state indicators
- reduced motion support
- safe area compliance

### 21.2 RTL

Use:

```dart
EdgeInsetsDirectional
AlignmentDirectional
TextAlign.start
CrossAxisAlignment.start
BorderRadiusDirectional when asymmetric
```

Avoid:

```dart
EdgeInsets.only(left: ...)
Alignment.centerLeft
TextAlign.left
```

### 21.3 Localization

All visible text must be localizable.

Do not hardcode strings in shared reusable widgets.

Dates, units, and numbers must follow user preferences.

---

## 22. Performance rules

### 22.1 Build method

Do not perform inside `build()`:

- API calls
- JSON parsing
- large list sorting
- route simplification
- distance calculations for large histories
- heavy permission calculations
- image processing

### 22.2 Lists

Use:

- `ListView.builder`
- pagination/load-more
- pull-to-refresh
- `const` widgets where possible
- scoped provider watches

### 22.3 Maps

Use:

- `RepaintBoundary`
- separated marker layer state
- throttled telemetry updates
- cached vehicle icons
- pre-processed route points

Do not rebuild the entire map for every telemetry event.

### 22.4 Images

Use cached network images for remote assets.

Avoid raw network images in list-heavy screens.

---

## 23. Required shared Flutter components

Before production UI development, these components should exist and be used consistently.

```text
OpenVtsPageScaffold
OpenVtsButton
OpenVtsCard
OpenVtsGlassPanel
OpenVtsTextField
OpenVtsSearchField
OpenVtsStatusChip
OpenVtsMetricCard
OpenVtsListTile
OpenVtsVehicleCard
OpenVtsEmptyState
OpenVtsErrorView
OpenVtsLoader
OpenVtsSkeleton
OpenVtsFeedback
OpenVtsBottomSheet
OpenVtsDialog
OpenVtsSegmentedControl
OpenVtsFilterChipGroup
OpenVtsMapControlButton
OpenVtsVehicleMarker
OpenVtsSelectedVehiclePanel
```

---

## 24. Development guardrails

### 24.1 Do this

- Use OpenVTS tokens.
- Use shared widgets first.
- Keep role UI consistent.
- Translate web design DNA to native mobile patterns.
- Keep maps powerful but not noisy.
- Keep CRUD screens calm and readable.
- Keep status colors meaningful.
- Keep typography disciplined.
- Keep spacing tokenized.
- Use `SafeArea` and directional layout.

### 24.2 Do not do this

- Do not use raw colors in screens.
- Do not create one-off button styles.
- Do not create one-off card styles.
- Do not use glass everywhere.
- Do not use colorful dashboards without data reason.
- Do not copy desktop tables directly to phones.
- Do not show raw API errors.
- Do not use tiny tap targets.
- Do not mix icon families.
- Do not make product UI feel different from website.
- Do not make mobile feel like a generic Flutter template.

---

## 25. Screen acceptance checklist

A screen is production-ready only when all relevant items pass.

### Brand consistency

- [ ] Feels like OpenVTS web/dashboard ecosystem.
- [ ] Uses Inter as primary UI font.
- [ ] Uses Satoshi only for approved secondary brand moments.
- [ ] Uses monochrome-first palette.
- [ ] Uses restrained semantic colors.
- [ ] Avoids generic Material look.
- [ ] Avoids decorative gradients/glows/noise.

### Token usage

- [ ] Uses OpenVTS color tokens.
- [ ] Uses OpenVTS spacing tokens.
- [ ] Uses OpenVTS radius tokens.
- [ ] Uses OpenVTS typography/theme styles.
- [ ] No arbitrary hardcoded visual values.

### Component usage

- [ ] Uses `OpenVtsButton`.
- [ ] Uses `OpenVtsTextField`.
- [ ] Uses `OpenVtsCard`.
- [ ] Uses `OpenVtsFeedback`.
- [ ] Uses shared loading/error/empty states.
- [ ] Extracts repeated patterns.

### Mobile UX

- [ ] Touch targets are at least 44dp.
- [ ] Safe areas respected.
- [ ] Keyboard does not hide primary action.
- [ ] Bottom nav clearance exists.
- [ ] Filters/actions use bottom sheets where appropriate.
- [ ] Destructive actions confirm.

### Data clarity

- [ ] Unknown values use `—`.
- [ ] Dates follow user preference.
- [ ] Units follow user preference.
- [ ] Status is not color-only.
- [ ] Raw technical data is hidden unless useful.

### Performance

- [ ] No heavy logic in `build()`.
- [ ] Lists use builder/pagination.
- [ ] Map layers are separated.
- [ ] Heavy widgets wrapped or isolated.
- [ ] Provider watches are scoped.

### Accessibility

- [ ] Semantic labels exist where needed.
- [ ] Dynamic text scale works.
- [ ] Contrast is strong.
- [ ] Reduced motion supported.
- [ ] RTL not broken.

---

## 26. GitHub Copilot instruction block

Use this prompt when asking Copilot to create or refactor Flutter UI.

```text
You are working on the OpenVTS Flutter app.
Follow docs/OpenVTS_Final_Cross_Platform_UI_UX_Guidelines.md exactly.

Goal:
Build a premium OpenVTS interface that feels consistent with the Next.js website and web dashboard, while using native Flutter/mobile UX patterns.

Design DNA:
- Premium monochrome fleet command center
- Calm, precise, restrained, enterprise-grade
- Same Inter primary typography, Satoshi secondary brand typography, and OpenVTS token system
- Border-based premium, not shadow-heavy UI
- Map/geospatial visual language where relevant
- No generic Flutter admin template feeling

Rules:
- Use OpenVTS theme tokens from lib/core/theme.
- Use shared OpenVTS widgets before raw Flutter widgets.
- No hardcoded colors in feature screens.
- No raw TextStyle except extending Theme text styles.
- No random spacing/radius/shadows.
- No raw ElevatedButton/TextButton/OutlinedButton where OpenVtsButton fits.
- No raw TextFormField where OpenVtsTextField fits.
- No direct ScaffoldMessenger in feature screens; use OpenVtsFeedback.
- Use cards/lists/bottom sheets instead of desktop tables on phone.
- Keep map overlays powerful but restrained.
- Keep CRUD screens calm, readable, and fast.
- Preserve dark mode, RTL, accessibility, and safe areas.
- Avoid heavy work inside build().

Before finishing:
- Review the screen against the acceptance checklist.
- Remove anything noisy, generic, inconsistent, or over-styled.
```

---

## 27. Final standard

The final OpenVTS ecosystem should feel like this:

```text
Website: premium perception and trust.
Web dashboard: complete operational control.
Mobile app: fast command center in the operator’s hand.
Tablet/desktop Flutter: adaptive extension of the same system.
```

Everything must feel:

- exact
- calm
- premium
- mature
- controlled
- trustworthy
- operationally intelligent
- globally credible
- engineered, not decorated

If it feels noisy, reduce it.  
If it feels generic, sharpen the system.  
If it feels like default Flutter, rebuild the component.  
If it feels disconnected from the web app, align the tokens and rhythm.  
If it feels merely good-looking, keep refining.

Stop only when it feels inevitable.
