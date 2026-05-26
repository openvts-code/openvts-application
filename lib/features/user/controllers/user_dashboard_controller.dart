import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_cache.dart';
import '../models/user_dashboard_model.dart';
import '../models/user_dashboard_state.dart';
import '../services/user_dashboard_service.dart';

class UserDashboardController extends StateNotifier<UserDashboardState> {
  UserDashboardController({
    required UserDashboardService service,
    required LocalCache localCache,
  })  : _service = service,
        _localCache = localCache,
        super(const UserDashboardState.initial());

  static const lastSelectedDashboardCacheKey = 'openvts_user_last_dashboard_id';

  final UserDashboardService _service;
  final LocalCache _localCache;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoadingDashboards: true,
      isLoadingSelectedDashboard: false,
      isRefreshing: false,
      errorMessage: null,
      selectedDashboardError: null,
    );

    try {
      final dashboards = await _service.getDashboards();
      if (!mounted) return;

      final selectedId = _resolveInitialDashboardId(dashboards);
      state = state.copyWith(
        dashboards: dashboards,
        selectedDashboardId: selectedId,
        selectedDashboard: null,
        orderedWidgets: const <UserDashboardWidgetConfig>[],
        isLoadingDashboards: false,
        errorMessage: null,
      );

      if (selectedId == null) {
        await _localCache.remove(lastSelectedDashboardCacheKey);
        return;
      }

      await _saveSelectedDashboardId(selectedId);
      await _loadDashboardDetail(selectedId);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingDashboards: false,
        isLoadingSelectedDashboard: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isRefreshing: true,
      errorMessage: null,
      selectedDashboardError: null,
    );

    try {
      final dashboards = await _service.getDashboards();
      if (!mounted) return;

      final selectedId = _resolveRefreshDashboardId(dashboards);
      if (selectedId == null) {
        await _localCache.remove(lastSelectedDashboardCacheKey);
        state = state.copyWith(
          dashboards: dashboards,
          selectedDashboardId: null,
          selectedDashboard: null,
          orderedWidgets: const <UserDashboardWidgetConfig>[],
          isRefreshing: false,
        );
        return;
      }

      await _saveSelectedDashboardId(selectedId);
      final detail = await _service.getDashboardById(selectedId);
      if (!mounted) return;

      state = state.copyWith(
        dashboards: dashboards,
        selectedDashboardId: selectedId,
        selectedDashboard: detail,
        orderedWidgets: _orderWidgets(detail),
        isRefreshing: false,
        selectedDashboardError: null,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> selectDashboard(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return;

    final exists =
        state.dashboards.any((dashboard) => dashboard.id == normalizedId);
    if (!exists) {
      state = state.copyWith(
        selectedDashboardError: 'Dashboard is no longer available.',
      );
      return;
    }

    state = state.copyWith(
      selectedDashboardId: normalizedId,
      selectedDashboard: null,
      orderedWidgets: const <UserDashboardWidgetConfig>[],
      selectedDashboardError: null,
    );
    await _saveSelectedDashboardId(normalizedId);
    await _loadDashboardDetail(normalizedId);
  }

  Future<void> reloadSelectedDashboard() async {
    final selectedId = state.selectedDashboardId;
    if (selectedId == null || selectedId.trim().isEmpty) {
      await loadInitial();
      return;
    }

    await _loadDashboardDetail(selectedId,
        refreshing: state.hasSelectedDashboard);
  }

  Future<void> _loadDashboardDetail(
    String id, {
    bool refreshing = false,
  }) async {
    state = state.copyWith(
      isLoadingSelectedDashboard: !refreshing,
      isRefreshing: refreshing ? true : state.isRefreshing,
      selectedDashboardError: null,
    );

    try {
      final detail = await _service.getDashboardById(id);
      if (!mounted) return;

      state = state.copyWith(
        selectedDashboardId: detail.id.trim().isNotEmpty ? detail.id : id,
        selectedDashboard: detail,
        orderedWidgets: _orderWidgets(detail),
        isLoadingSelectedDashboard: false,
        isRefreshing: refreshing ? false : state.isRefreshing,
        selectedDashboardError: null,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingSelectedDashboard: false,
        isRefreshing: refreshing ? false : state.isRefreshing,
        selectedDashboardError: _toErrorMessage(error),
      );
    }
  }

  String? _resolveInitialDashboardId(List<UserDashboardListItem> dashboards) {
    if (dashboards.isEmpty) return null;

    final savedId =
        _localCache.getString(lastSelectedDashboardCacheKey)?.trim();
    if (savedId != null && savedId.isNotEmpty) {
      final savedExists =
          dashboards.any((dashboard) => dashboard.id == savedId);
      if (savedExists) return savedId;
    }

    return dashboards.first.id;
  }

  String? _resolveRefreshDashboardId(List<UserDashboardListItem> dashboards) {
    if (dashboards.isEmpty) return null;

    final currentId = state.selectedDashboardId?.trim();
    if (currentId != null && currentId.isNotEmpty) {
      final currentExists =
          dashboards.any((dashboard) => dashboard.id == currentId);
      if (currentExists) return currentId;
    }

    return _resolveInitialDashboardId(dashboards);
  }

  Future<void> _saveSelectedDashboardId(String id) {
    return _localCache.setString(lastSelectedDashboardCacheKey, id);
  }

  List<UserDashboardWidgetConfig> _orderWidgets(UserDashboardDetail detail) {
    final widgets = detail.config.widgets;
    if (widgets.isEmpty) return widgets;

    final widgetById = {
      for (final widget in widgets) widget.id: widget,
    };

    for (final breakpoint in userDashboardMobileLayoutPreference) {
      final layout = detail.config.layouts[breakpoint]
              ?.where((item) => widgetById.containsKey(item.i))
              .toList(growable: false) ??
          const <UserDashboardLayoutItem>[];
      if (layout.isEmpty) continue;

      final sortedLayout = [...layout]..sort((left, right) {
          final yCompare = left.y.compareTo(right.y);
          if (yCompare != 0) return yCompare;
          return left.x.compareTo(right.x);
        });

      final ordered = <UserDashboardWidgetConfig>[];
      final included = <String>{};
      for (final item in sortedLayout) {
        final widget = widgetById[item.i];
        if (widget != null && included.add(widget.id)) {
          ordered.add(widget);
        }
      }

      for (final widget in widgets) {
        if (included.add(widget.id)) {
          ordered.add(widget);
        }
      }

      return ordered;
    }

    return widgets;
  }

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) return responseMessage;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return raw.isEmpty ? 'Dashboard could not be loaded.' : raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }

      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }
}
