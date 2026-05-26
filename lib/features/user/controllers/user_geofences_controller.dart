import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_landmark_model.dart';
import '../models/user_landmark_state.dart';
import '../services/user_landmark_service.dart';
import 'user_landmark_studio_controller.dart' show userLandmarkErrorMessage;

class UserGeofencesController extends StateNotifier<UserGeofencesState> {
  UserGeofencesController({required UserLandmarkService service})
      : _service = service,
        super(const UserGeofencesState.initial());

  final UserLandmarkService _service;
  int _requestSerial = 0;

  Future<void> load() => _fetch(forceRefresh: false);

  Future<void> refresh() {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(refreshKey: key);
    return _fetch(forceRefresh: true);
  }

  Future<void> setSearchQuery(String query) async {
    final normalized = query.trim();
    if (normalized == state.searchQuery) return;
    state = state.copyWith(searchQuery: normalized, errorMessage: null);
    await _fetch(forceRefresh: false);
  }

  Future<void> setStatusFilter(UserLandmarkStatusFilter filter) async {
    if (filter == state.statusFilter) return;
    state = state.copyWith(statusFilter: filter, errorMessage: null);
    await _fetch(forceRefresh: false);
  }

  Future<void> setTypeFilter(UserGeofenceType? type) async {
    if (type == state.typeFilter) return;
    state = state.copyWith(typeFilter: type, errorMessage: null);
    await _fetch(forceRefresh: false);
  }

  void selectGeofence(UserGeofence? geofence) {
    state = state.copyWith(selectedGeofence: geofence);
  }

  Future<UserGeofence> fetchDetails(String id) async {
    final geofence = await _service.fetchGeofenceById(id);
    if (!mounted) return geofence;
    state = state.copyWith(
      geofences: _replaceById(state.geofences, geofence),
      selectedGeofence: state.selectedGeofence?.id == geofence.id
          ? geofence
          : state.selectedGeofence,
    );
    return geofence;
  }

  Future<UserGeofence> createGeofence(CreateUserGeofenceRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      final created = await _service.createGeofence(request);
      if (!mounted) return created;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return created;
      state = state.copyWith(
        isCreating: false,
        selectedGeofence: _findById(state.geofences, created.id) ?? created,
      );
      return created;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not create geofence.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<UserGeofence> updateGeofence(
    String id,
    UpdateUserGeofenceRequest request,
  ) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final updated = await _service.updateGeofence(id, request);
      if (!mounted) return updated;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return updated;
      state = state.copyWith(
        isUpdating: false,
        selectedGeofence: _findById(state.geofences, updated.id) ?? updated,
      );
      return updated;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isUpdating: false,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not update geofence.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> deleteGeofence(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(
      deletingIds: <String>{...state.deletingIds, normalized},
      errorMessage: null,
    );
    try {
      await _service.deleteGeofence(normalized);
      if (!mounted) return;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return;
      final next = <String>{...state.deletingIds}..remove(normalized);
      state = state.copyWith(
        deletingIds: next,
        selectedGeofence: state.selectedGeofence?.id == normalized
            ? null
            : state.selectedGeofence,
      );
    } catch (error) {
      if (mounted) {
        final next = <String>{...state.deletingIds}..remove(normalized);
        state = state.copyWith(
          deletingIds: next,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not delete geofence.',
          ),
        );
      }
      rethrow;
    }
  }

  void clearFilters() {
    if (!state.hasActiveFilters) return;
    state = state.copyWith(
      searchQuery: '',
      statusFilter: UserLandmarkStatusFilter.all,
      typeFilter: null,
      errorMessage: null,
    );
    // Re-fetch without filters.
    // ignore: discarded_futures
    _fetch(forceRefresh: false);
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _fetch({
    required bool forceRefresh,
    bool skipLoaderFlag = false,
  }) async {
    final serial = ++_requestSerial;
    final hasExisting = state.geofences.isNotEmpty;
    if (!skipLoaderFlag) {
      state = state.copyWith(
        isLoading: !hasExisting,
        isRefreshing: forceRefresh && hasExisting,
        errorMessage: null,
      );
    }

    try {
      final list = await _service.fetchGeofences(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        isActive: state.statusFilter.asActiveFlag,
        type: state.typeFilter,
        refreshKey: state.refreshKey.isEmpty ? null : state.refreshKey,
      );
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        geofences: list,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
        selectedGeofence: state.selectedGeofence == null
            ? null
            : _findById(list, state.selectedGeofence!.id),
      );
    } catch (error) {
      if (!mounted || serial != _requestSerial) return;
      // Don't wipe an existing list on transient errors.
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: userLandmarkErrorMessage(
          error,
          fallback: 'Could not load geofences.',
        ),
      );
    }
  }

  static List<UserGeofence> _replaceById(
    List<UserGeofence> list,
    UserGeofence item,
  ) {
    var replaced = false;
    final next = <UserGeofence>[];
    for (final entry in list) {
      if (entry.id == item.id) {
        next.add(item);
        replaced = true;
      } else {
        next.add(entry);
      }
    }
    if (!replaced) next.add(item);
    return next;
  }

  static UserGeofence? _findById(List<UserGeofence> list, String id) {
    for (final entry in list) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
