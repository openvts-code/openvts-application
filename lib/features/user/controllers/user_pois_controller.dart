import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_landmark_model.dart';
import '../models/user_landmark_state.dart';
import '../services/user_landmark_service.dart';
import 'user_landmark_studio_controller.dart' show userLandmarkErrorMessage;

class UserPoisController extends StateNotifier<UserPoisState> {
  UserPoisController({required UserLandmarkService service})
      : _service = service,
        super(const UserPoisState.initial());

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

  /// Category filtering is applied client-side; backend does not currently
  /// accept a category query parameter.
  void setCategoryFilter(String? category) {
    final normalized = category?.trim();
    final next = normalized == null || normalized.isEmpty ? null : normalized;
    if (next == state.categoryFilter) return;
    state = state.copyWith(categoryFilter: next, errorMessage: null);
  }

  void selectPoi(UserPoi? poi) {
    state = state.copyWith(selectedPoi: poi);
  }

  Future<UserPoi> fetchDetails(String id) async {
    final poi = await _service.fetchPoiById(id);
    if (!mounted) return poi;
    state = state.copyWith(
      pois: _replaceById(state.pois, poi),
      selectedPoi: state.selectedPoi?.id == poi.id ? poi : state.selectedPoi,
    );
    return poi;
  }

  Future<UserPoi> createPoi(CreateUserPoiRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      final created = await _service.createPoi(request);
      if (!mounted) return created;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return created;
      state = state.copyWith(
        isCreating: false,
        selectedPoi: _findById(state.pois, created.id) ?? created,
      );
      return created;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not create POI.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<UserPoi> updatePoi(
    String id,
    UpdateUserPoiRequest request,
  ) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final updated = await _service.updatePoi(id, request);
      if (!mounted) return updated;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return updated;
      state = state.copyWith(
        isUpdating: false,
        selectedPoi: _findById(state.pois, updated.id) ?? updated,
      );
      return updated;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isUpdating: false,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not update POI.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> deletePoi(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(
      deletingIds: <String>{...state.deletingIds, normalized},
      errorMessage: null,
    );
    try {
      await _service.deletePoi(normalized);
      if (!mounted) return;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return;
      final next = <String>{...state.deletingIds}..remove(normalized);
      state = state.copyWith(
        deletingIds: next,
        selectedPoi:
            state.selectedPoi?.id == normalized ? null : state.selectedPoi,
      );
    } catch (error) {
      if (mounted) {
        final next = <String>{...state.deletingIds}..remove(normalized);
        state = state.copyWith(
          deletingIds: next,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not delete POI.',
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
      categoryFilter: null,
      errorMessage: null,
    );
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
    final hasExisting = state.pois.isNotEmpty;
    if (!skipLoaderFlag) {
      state = state.copyWith(
        isLoading: !hasExisting,
        isRefreshing: forceRefresh && hasExisting,
        errorMessage: null,
      );
    }

    try {
      final list = await _service.fetchPois(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        isActive: state.statusFilter.asActiveFlag,
        refreshKey: state.refreshKey.isEmpty ? null : state.refreshKey,
      );
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        pois: list,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
        selectedPoi: state.selectedPoi == null
            ? null
            : _findById(list, state.selectedPoi!.id),
      );
    } catch (error) {
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: userLandmarkErrorMessage(
          error,
          fallback: 'Could not load POIs.',
        ),
      );
    }
  }

  static List<UserPoi> _replaceById(List<UserPoi> list, UserPoi item) {
    var replaced = false;
    final next = <UserPoi>[];
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

  static UserPoi? _findById(List<UserPoi> list, String id) {
    for (final entry in list) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
