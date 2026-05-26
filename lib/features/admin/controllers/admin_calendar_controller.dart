import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/admin_calendar_model.dart';
import '../services/admin_calendar_service.dart';

final _adminCalendarServiceProvider = Provider<AdminCalendarService>((ref) {
  return AdminCalendarService(ref.read(apiClientProvider));
});

final adminCalendarFiltersProvider =
    StateProvider<List<String>>((ref) => ['users', 'vehicle', 'expiry']);
final adminCalendarFocusedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());
final adminCalendarSelectedDateProvider =
    StateProvider<DateTime?>((ref) => DateTime.now());

final adminCalendarEventsProvider =
    FutureProvider<List<AdminCalendarEvent>>((ref) async {
  final service = ref.watch(_adminCalendarServiceProvider);
  final focusedDate = ref.watch(adminCalendarFocusedDateProvider);
  final filters = ref.watch(adminCalendarFiltersProvider);

  final firstDay = DateTime(focusedDate.year, focusedDate.month, 1);
  final lastDay = DateTime(focusedDate.year, focusedDate.month + 1, 0);

  final fromStr =
      '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
  final toStr =
      '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

  final result = await service.getEvents(fromStr, toStr, filters);
  if (result.isSuccess) {
    return result.data ?? [];
  }

  throw result.error ?? Exception('Failed to load calendar events');
});

final adminCalendarDayDetailsProvider =
    FutureProvider.family<List<AdminCalendarDayDetail>, DateTime>(
        (ref, date) async {
  final service = ref.watch(_adminCalendarServiceProvider);
  final filters = ref.watch(adminCalendarFiltersProvider);

  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final result = await service.getDayDetails(dateStr, filters);
  if (result.isSuccess) {
    return result.data ?? [];
  }

  throw result.error ?? Exception('Failed to load calendar details');
});

final adminCalendarUserDetailsProvider =
    FutureProvider.family<AdminCalendarLinkedDetail?, String>((ref, uid) async {
  if (uid.trim().isEmpty) return null;

  final service = ref.watch(_adminCalendarServiceProvider);
  final result = await service.getUserDetails(uid);
  if (result.isSuccess) {
    return result.data;
  }

  return null;
});

final adminCalendarVehicleDetailsProvider =
    FutureProvider.family<AdminCalendarLinkedDetail?, String>(
        (ref, vehicleId) async {
  if (vehicleId.trim().isEmpty) return null;

  final service = ref.watch(_adminCalendarServiceProvider);
  final result = await service.getVehicleDetails(vehicleId);
  if (result.isSuccess) {
    return result.data;
  }

  return null;
});
