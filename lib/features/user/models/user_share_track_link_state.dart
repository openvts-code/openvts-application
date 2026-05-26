import 'user_share_track_link_model.dart';

class UserShareTrackLinkState {
  const UserShareTrackLinkState({
    required this.links,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.searchQuery,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isCreating,
    required this.updatingIds,
    required this.deletingIds,
    required this.errorMessage,
    required this.refreshKey,
  });

  const UserShareTrackLinkState.initial()
      : links = const <UserShareTrackLink>[],
        page = 1,
        limit = 50,
        total = 0,
        hasMore = false,
        searchQuery = '',
        isLoading = true,
        isRefreshing = false,
        isLoadingMore = false,
        isCreating = false,
        updatingIds = const <String>{},
        deletingIds = const <String>{},
        errorMessage = null,
        refreshKey = null;

  static const Object _unset = Object();

  final List<UserShareTrackLink> links;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
  final String searchQuery;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isCreating;
  final Set<String> updatingIds;
  final Set<String> deletingIds;
  final String? errorMessage;
  final String? refreshKey;

  int get visibleCount => links.length;
  int get totalCount => total;

  bool isUpdating(String id) => updatingIds.contains(id);
  bool isDeleting(String id) => deletingIds.contains(id);

  UserShareTrackLinkState copyWith({
    List<UserShareTrackLink>? links,
    int? page,
    int? limit,
    int? total,
    bool? hasMore,
    String? searchQuery,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isCreating,
    Set<String>? updatingIds,
    Set<String>? deletingIds,
    Object? errorMessage = _unset,
    Object? refreshKey = _unset,
  }) {
    return UserShareTrackLinkState(
      links: links ?? this.links,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      updatingIds: updatingIds ?? this.updatingIds,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      refreshKey: identical(refreshKey, _unset)
          ? this.refreshKey
          : refreshKey as String?,
    );
  }
}
