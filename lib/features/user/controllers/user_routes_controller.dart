import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_landmark_model.dart';
import '../models/user_landmark_state.dart';
import '../services/user_landmark_service.dart';
import 'user_landmark_studio_controller.dart' show userLandmarkErrorMessage;

class UserRoutesController extends StateNotifier<UserRoutesState> {
  UserRoutesController({required UserLandmarkService service})
      : _service = service,
        super(const UserRoutesState.initial());

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

  void selectRoute(UserRouteLandmark? route) {
    state = state.copyWith(selectedRoute: route);
  }

  Future<UserRouteLandmark> fetchDetails(String id) async {
    final route = await _service.fetchRouteById(id);
    if (!mounted) return route;
    state = state.copyWith(
      routes: _replaceById(state.routes, route),
      selectedRoute:
          state.selectedRoute?.id == route.id ? route : state.selectedRoute,
    );
    return route;
  }

  Future<UserRouteLandmark> createRoute(
    CreateUserRouteRequest request,
  ) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      final created = await _service.createRoute(request);
      if (!mounted) return created;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return created;
      state = state.copyWith(
        isCreating: false,
        selectedRoute: _findById(state.routes, created.id) ?? created,
      );
      return created;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not create route.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<UserRouteLandmark> updateRoute(
    String id,
    UpdateUserRouteRequest request,
  ) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final updated = await _service.updateRoute(id, request);
      if (!mounted) return updated;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return updated;
      state = state.copyWith(
        isUpdating: false,
        selectedRoute: _findById(state.routes, updated.id) ?? updated,
      );
      return updated;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isUpdating: false,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not update route.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> deleteRoute(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(
      deletingIds: <String>{...state.deletingIds, normalized},
      errorMessage: null,
    );
    try {
      await _service.deleteRoute(normalized);
      if (!mounted) return;
      await _fetch(forceRefresh: true, skipLoaderFlag: true);
      if (!mounted) return;
      final next = <String>{...state.deletingIds}..remove(normalized);
      state = state.copyWith(
        deletingIds: next,
        selectedRoute:
            state.selectedRoute?.id == normalized ? null : state.selectedRoute,
      );
    } catch (error) {
      if (mounted) {
        final next = <String>{...state.deletingIds}..remove(normalized);
        state = state.copyWith(
          deletingIds: next,
          errorMessage: userLandmarkErrorMessage(
            error,
            fallback: 'Could not delete route.',
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
    final hasExisting = state.routes.isNotEmpty;
    if (!skipLoaderFlag) {
      state = state.copyWith(
        isLoading: !hasExisting,
        isRefreshing: forceRefresh && hasExisting,
        errorMessage: null,
      );
    }

    try {
      final list = await _service.fetchRoutes(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        isActive: state.statusFilter.asActiveFlag,
        includeGeodata: true,
        refreshKey: state.refreshKey.isEmpty ? null : state.refreshKey,
      );
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        routes: list,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
        selectedRoute: state.selectedRoute == null
            ? null
            : _findById(list, state.selectedRoute!.id),
      );
    } catch (error) {
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: userLandmarkErrorMessage(
          error,
          fallback: 'Could not load routes.',
        ),
      );
    }
  }

  static List<UserRouteLandmark> _replaceById(
    List<UserRouteLandmark> list,
    UserRouteLandmark item,
  ) {
    var replaced = false;
    final next = <UserRouteLandmark>[];
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

  static UserRouteLandmark? _findById(
    List<UserRouteLandmark> list,
    String id,
  ) {
    for (final entry in list) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
