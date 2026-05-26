import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/superadmin_calendar_model.dart';
import '../services/superadmin_calendar_service.dart';

final calendarFiltersProvider = StateProvider<List<String>>((ref) => ['users', 'vehicle', 'expiry']);
final calendarFocusedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarSelectedDateProvider = StateProvider<DateTime?>((ref) => DateTime.now());

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final service = ref.watch(superadminCalendarServiceProvider);
  final focusedDate = ref.watch(calendarFocusedDateProvider);
  final filters = ref.watch(calendarFiltersProvider);

  final firstDay = DateTime(focusedDate.year, focusedDate.month, 1);
  final lastDay = DateTime(focusedDate.year, focusedDate.month + 1, 0);

  final fromStr = '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
  final toStr = '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

  final result = await service.getEvents(fromStr, toStr, filters);
  if (result.isSuccess) {
    return result.data ?? [];
  }

  throw result.error ?? Exception('Failed to load calendar events');
});

final calendarDayDetailsProvider = FutureProvider.family<List<CalendarDayDetail>, DateTime>((ref, date) async {
  final service = ref.watch(superadminCalendarServiceProvider);
  final filters = ref.watch(calendarFiltersProvider);
  
  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  
  final result = await service.getDayDetails(dateStr, filters);
  if (result.isSuccess) {
    return result.data ?? [];
  }

  throw result.error ?? Exception('Failed to load calendar details');
});

final calendarUserDetailsProvider =
    FutureProvider.family<CalendarLinkedDetail?, String>((ref, uid) async {
  if (uid.trim().isEmpty) {
    return null;
  }

  final service = ref.watch(superadminCalendarServiceProvider);
  final result = await service.getUserDetails(uid);
  if (result.isSuccess) {
    return result.data;
  }
  return null;
});

final calendarVehicleDetailsProvider =
    FutureProvider.family<CalendarLinkedDetail?, String>((ref, vehicleId) async {
  if (vehicleId.trim().isEmpty) {
    return null;
  }

  final service = ref.watch(superadminCalendarServiceProvider);
  final result = await service.getVehicleDetails(vehicleId);
  if (result.isSuccess) {
    return result.data;
  }
  return null;
});
