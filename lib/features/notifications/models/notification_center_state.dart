import 'app_notification.dart';

class NotificationCenterState {
  const NotificationCenterState({
    required this.items,
    required this.unreadCount,
    required this.hasMore,
    this.nextBeforeId,
    this.errorMessage,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isMarkingAllRead = false,
    this.unreadOnly = false,
  });

  const NotificationCenterState.initial()
      : this(
          items: const <AppNotification>[],
          unreadCount: 0,
          hasMore: false,
          isInitialLoading: true,
        );

  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
  final int? nextBeforeId;
  final String? errorMessage;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isMarkingAllRead;
  final bool unreadOnly;

  bool get hasItems => items.isNotEmpty;

  NotificationCenterState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? hasMore,
    Object? nextBeforeId = _unset,
    Object? errorMessage = _unset,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isMarkingAllRead,
    bool? unreadOnly,
  }) {
    return NotificationCenterState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      nextBeforeId:
          identical(nextBeforeId, _unset) ? this.nextBeforeId : nextBeforeId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

const Object _unset = Object();
