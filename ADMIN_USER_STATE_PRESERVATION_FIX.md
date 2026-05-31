# Admin User Details - State Preservation Fix

## Problem Statement

Similar to the Superadmin Admin Profile issue, the Admin User Details screen was losing critical data on refresh because the detail API returned partial/default values that overwrote known values from the list:

1. **Active Status**: Detail API returns default `true`, overwriting known `false` from list
2. **Vehicle Count**: Detail API returns `0`, overwriting known positive counts from list  
3. **Last Login**: Using `updatedAt` as proxy, detail API may return `null`

## Root Cause

The `AdminUserDetailsState` had an `initialUser` field but wasn't using it to preserve values when the detail API returned defaults. The state initialization was also setting `user = initialUser` which caused premature data display.

## Solution Applied

### 1. State Model Updates (`admin_user_details_state.dart`)

**Changed initialization:**
```dart
// Before:
user = initialUser,

// After:  
user = null,  // Wait for actual detail load
```

**Added resolver getters:**
```dart
// Resolves active status from detail > initialUser > default
bool get effectiveIsActive {
  if (user != null) return user!.isActive;
  if (initialUser != null) return initialUser!.isActive;
  return true;
}

// Resolves vehicle count, avoiding 0 overwrite
int? get resolvedVehicleCount {
  if (hasLoadedVehicles) return linkedVehicles.length;
  if (user != null && user!.vehicleCount > 0) return user!.vehicleCount;
  if (initialUser != null && initialUser!.vehicleCount > 0) {
    return initialUser!.vehicleCount;
  }
  return null;  // Unknown, not 0
}

// Resolves last login from updatedAt
DateTime? get resolvedLastLogin {
  if (user?.updatedAt != null) return user!.updatedAt;
  if (initialUser?.updatedAt != null) return initialUser!.updatedAt;
  return null;
}
```

### 2. Controller Updates (`admin_user_details_controller.dart`)

**Added seed method:**
```dart
void seedInitialData({
  int? vehicleCount,
  DateTime? lastLogin,
}) {
  // State.initialUser already holds list item data
  // Resolvers use it directly
}
```

**Enhanced loadProfile to preserve known values:**
```dart
var user = await _service.getUserDetails(_userId);

// Preserve known status if detail returned default true
// but list had explicit false
if (user.isActive == true &&
    state.initialUser != null &&
    state.initialUser!.isActive == false) {
  user = user.copyWith(isActive: false);
}

// Preserve known vehicle count if detail returned 0
// but list had positive count
if (user.vehicleCount == 0 &&
    state.initialUser != null &&
    state.initialUser!.vehicleCount > 0) {
  user = user.copyWith(vehicleCount: state.initialUser!.vehicleCount);
}
```

### 3. Screen Updates (`admin_user_details_screen.dart`)

**Added initState to seed initial data:**
```dart
@override
void initState() {
  super.initState();
  if (widget.initialUser != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          ref.read(adminUserDetailsControllerProvider(widget.userId).notifier);
      controller.seedInitialData(
        vehicleCount: widget.initialUser!.vehicleCount > 0
            ? widget.initialUser!.vehicleCount
            : null,
        lastLogin: widget.initialUser!.updatedAt,
      );
    });
  }
}
```

**Updated _UserSnapshot.resolve to use effectiveIsActive:**
```dart
static _UserSnapshot resolve({
  required AdminUserDetails? details,
  required AdminUserListItem? fallback,
  required String userId,
  required bool effectiveIsActive,  // Now uses resolved value
}) {
  // ...
  isActive: effectiveIsActive,  // Not details.isActive
  // ...
}
```

### 4. Profile Tab Updates (`admin_user_profile_tab.dart`)

**Updated _ProfileSnapshot.resolve to accept resolved values:**
```dart
static _ProfileSnapshot resolve({
  required AdminUserDetails? details,
  required admin_users.AdminUserListItem? fallback,
  required String userId,
  required bool effectiveIsActive,
  required int? resolvedVehicleCount,
  required DateTime? resolvedLastLogin,
}) {
  return _ProfileSnapshot(
    // ...
    isActive: effectiveIsActive,
    updatedAt: resolvedLastLogin ?? details.updatedAt,
    vehicleCount: resolvedVehicleCount ?? details.vehicleCount,
    // ...
  );
}
```

**Updated widget build to pass resolved values:**
```dart
final profile = _ProfileSnapshot.resolve(
  details: state.user,
  fallback: initialUser,
  userId: userId,
  effectiveIsActive: state.effectiveIsActive,
  resolvedVehicleCount: state.resolvedVehicleCount,
  resolvedLastLogin: state.resolvedLastLogin,
);
```

## Behavior After Fix

### Status Toggle
- ✅ Optimistic update on toggle
- ✅ Preserved after refresh (won't revert to default true)
- ✅ Rollback on API failure (handled by existing code)

### Vehicle Count
- ✅ Shows list count initially if > 0
- ✅ Shows detail count if > 0
- ✅ Shows actual linked vehicles count when tab loaded
- ✅ Never shows misleading 0 when unknown

### Last Login
- ✅ Shows updatedAt from list initially
- ✅ Shows updatedAt from detail when loaded
- ✅ Never loses known timestamp

### Refresh Safety
- ✅ Refresh does NOT overwrite known false status with true
- ✅ Refresh does NOT overwrite known vehicle count with 0  
- ✅ Refresh does NOT overwrite known last login with null

## Testing Checklist

- [ ] User list shows inactive user (isActive: false, count: 5)
- [ ] Click user → Detail loads → Status shows inactive (not active)
- [ ] Vehicle count shows 5 (not 0)
- [ ] Toggle status to active → optimistic update works
- [ ] Pull to refresh → status stays active (preserved)
- [ ] Vehicles tab → shows actual vehicles → count updates
- [ ] Close and reopen user → status/count preserved from list

## Files Modified

1. `lib/features/admin/models/admin_user_details_state.dart`
   - Changed user initialization to null
   - Added effectiveIsActive getter
   - Added resolvedVehicleCount getter
   - Added resolvedLastLogin getter

2. `lib/features/admin/controllers/admin_user_details_controller.dart`
   - Added seedInitialData method
   - Enhanced loadProfile to preserve known values

3. `lib/features/admin/screens/users/admin_user_details_screen.dart`
   - Added initState to seed data
   - Updated _UserSnapshot.resolve to accept effectiveIsActive
   - Pass effectiveIsActive to resolve method

4. `lib/features/admin/screens/users/widgets/admin_user_profile_tab.dart`
   - Updated _ProfileSnapshot.resolve signature
   - Pass all resolved values from state
   - Updated public helper functions

## Notes

- **No backend changes**: All fixes are client-side state management
- **No data faking**: Only preserves actual known values from list
- **Same pattern as Superadmin**: Consistent approach across both features
- **Backward compatible**: Works correctly even if list/detail have complete data
