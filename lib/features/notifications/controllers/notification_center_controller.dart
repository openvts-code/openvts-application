import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/performance/open_vts_perf.dart';
import '../models/app_notification.dart';
import '../models/notification_center_state.dart';
import '../services/notification_service.dart';

class NotificationCenterController
    extends StateNotifier<NotificationCenterState> {
  NotificationCenterController(this._service)
      : super(const NotificationCenterState.initial());

  final NotificationService _service;

  Future<void> load({bool refresh = false}) {
    return OpenVtsPerf.traceAsync('notifications.load', () async {
      final shouldShowFullScreenLoader = !state.hasItems && !refresh;

      state = state.copyWith(
        isInitialLoading: shouldShowFullScreenLoader,
        isRefreshing: refresh,
        isLoadingMore: false,
        errorMessage: null,
      );

      try {
        final page = await _service.getNotifications(
          limit: AppConstants.defaultPageSize,
          unreadOnly: state.unreadOnly,
        );
        final unreadCount = page.unreadCount ?? await _service.getUnreadCount();

        state = state.copyWith(
          items: page.items,
          unreadCount: unreadCount,
          hasMore: page.hasMore,
          nextBeforeId: page.nextBeforeId,
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
    });
  }

  Future<void> refresh() {
    return load(refresh: true);
  }

  Future<void> setUnreadOnly(bool unreadOnly) async {
    if (state.unreadOnly == unreadOnly) {
      return;
    }

    state = state.copyWith(
      unreadOnly: unreadOnly,
      hasMore: false,
      nextBeforeId: null,
      errorMessage: null,
    );
    await load();
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.items.isEmpty) {
      return;
    }

    final beforeId = state.nextBeforeId ?? state.items.last.id;
    if (beforeId <= 0) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      errorMessage: null,
    );

    try {
      final page = await _service.getNotifications(
        limit: AppConstants.defaultPageSize,
        beforeId: beforeId,
        unreadOnly: state.unreadOnly,
      );

      state = state.copyWith(
        items: _mergeById(state.items, page.items),
        unreadCount: page.unreadCount ?? state.unreadCount,
        hasMore: page.hasMore,
        nextBeforeId: page.nextBeforeId,
        isLoadingMore: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> markAsRead(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }

    final notification = state.items[index];
    if (notification.isRead) {
      return;
    }

    final previousState = state;
    final updatedItems = List<AppNotification>.from(previousState.items);
    updatedItems[index] = notification.copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );

    state = previousState.copyWith(
      items: updatedItems,
      unreadCount:
          previousState.unreadCount > 0 ? previousState.unreadCount - 1 : 0,
      errorMessage: null,
    );

    try {
      await _service.markAsRead(id);
    } catch (error) {
      state = previousState.copyWith(
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    if (state.isMarkingAllRead || state.unreadCount == 0) {
      return;
    }

    final previousState = state;
    state = previousState.copyWith(
      items: previousState.items
          .map(
            (item) => item.isRead
                ? item
                : item.copyWith(
                    isRead: true,
                    readAt: DateTime.now(),
                  ),
          )
          .toList(growable: false),
      unreadCount: 0,
      isMarkingAllRead: true,
      errorMessage: null,
    );

    try {
      await _service.markAllAsRead();
      state = state.copyWith(isMarkingAllRead: false);
    } catch (error) {
      state = previousState.copyWith(
        isMarkingAllRead: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  List<AppNotification> _mergeById(
    List<AppNotification> current,
    List<AppNotification> incoming,
  ) {
    final merged = <int, AppNotification>{
      for (final notification in current) notification.id: notification,
    };

    for (final notification in incoming) {
      merged[notification.id] = notification;
    }

    final values = merged.values.toList(growable: false)
      ..sort((left, right) => right.id.compareTo(left.id));
    return values;
  }

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.response?.statusCode == 400) {
        return 'The notification request was rejected by the server.';
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
