import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_dashboard_model.dart';
import '../models/superadmin_dashboard_state.dart';
import '../services/superadmin_dashboard_service.dart';

class SuperadminDashboardController
    extends StateNotifier<SuperadminDashboardState> {
  SuperadminDashboardController(this._service)
      : super(const SuperadminDashboardState.initial()) {
    load();
  }

  final SuperadminDashboardService _service;

  Future<void> load({bool refresh = false}) async {
    final hasData = state.hasData;

    state = state.copyWith(
      isInitialLoading: !hasData,
      isRefreshing: hasData || refresh,
      isLoadingMore: false,
      errorMessage: null,
    );

    try {
      final dashboard = await _service.getDashboard();
      state = state.copyWith(
        dashboard: dashboard,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    final actorId = state.selectedActorId;
    final fromDate = state.fromDate;
    final toDate = state.toDate;

    await load(refresh: true);

    if (actorId != null || fromDate != null || toDate != null) {
      await applyFilters(
        actorId: actorId,
        from: fromDate,
        to: toDate,
      );
    }
  }

  Future<void> applyFilters({
    int? actorId,
    DateTime? from,
    DateTime? to,
  }) async {
    final current = state.dashboard;
    if (current == null) {
      await load();
      return;
    }

    state = state.copyWith(
      selectedActorId: actorId,
      fromDate: from,
      toDate: to,
      isRefreshing: true,
      errorMessage: null,
    );

    try {
      final response = await _service.fetchActivityLogs(
        limit: SuperadminDashboardService.activityLogPageSize,
        actorId: actorId,
        from: from,
        to: to,
        refreshKey: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      final activityPage = SuperadminActivityLogPage.fromJson(response);

      state = state.copyWith(
        dashboard: current.copyWith(activityLogs: activityPage),
        isRefreshing: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> clearFilters() {
    return applyFilters();
  }

  Future<void> loadMoreActivityLogs() async {
    final current = state.dashboard;
    final nextCursorId = current?.activityLogs.nextCursorId;

    if (current == null ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        nextCursorId == null ||
        nextCursorId <= 0) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      errorMessage: null,
    );

    try {
      final response = await _service.fetchActivityLogs(
        limit: SuperadminDashboardService.activityLogPageSize,
        cursorId: nextCursorId,
      );
      final activityPage = SuperadminActivityLogPage.fromJson(response);

      state = state.copyWith(
        dashboard: current.copyWith(
          activityLogs: current.activityLogs.copyWith(
            items: _mergeActivityLogs(
              current.activityLogs.items,
              activityPage.items,
            ),
            nextCursorId: activityPage.nextCursorId,
          ),
        ),
        isLoadingMore: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  List<SuperadminActivityLog> _mergeActivityLogs(
    List<SuperadminActivityLog> current,
    List<SuperadminActivityLog> incoming,
  ) {
    final merged = <String, SuperadminActivityLog>{
      for (final log in current) log.id: log,
    };

    for (final log in incoming) {
      final key = log.id.isEmpty
          ? '${log.title}-${log.actorName}-${log.createdAt?.millisecondsSinceEpoch ?? 0}'
          : log.id;
      merged[key] = log;
    }

    final values = merged.values.toList(growable: false)
      ..sort(
        (left, right) =>
            (right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
          left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    return values;
  }

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return raw;
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
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
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