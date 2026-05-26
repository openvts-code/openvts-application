import 'admin_support_model.dart';

class AdminSupportState {
  const AdminSupportState({
    required this.selectedTab,
    required this.userTickets,
    required this.myTickets,
    required this.userSearch,
    required this.mySearch,
    required this.userStatusFilter,
    required this.myStatusFilter,
    required this.selectedTicketId,
    required this.selectedTicketTab,
    required this.selectedTicketDetails,
    required this.users,
    required this.isLoadingUserTickets,
    required this.isLoadingMyTickets,
    required this.isLoadingDetails,
    required this.isCreatingUserTicket,
    required this.isCreatingMyTicket,
    required this.isReplying,
    required this.isUpdatingStatus,
    required this.isLoadingUsers,
    required this.errorMessage,
    required this.detailsErrorMessage,
    required this.userRefreshKey,
    required this.myRefreshKey,
    required this.userVisibleCount,
    required this.myVisibleCount,
  });

  const AdminSupportState.initial()
      : selectedTab = AdminSupportTab.userTickets,
        userTickets = const <AdminSupportTicketListItem>[],
        myTickets = const <AdminSupportTicketListItem>[],
        userSearch = '',
        mySearch = '',
        userStatusFilter = null,
        myStatusFilter = null,
        selectedTicketId = null,
        selectedTicketTab = null,
        selectedTicketDetails = null,
        users = const <AdminSupportUserMini>[],
        isLoadingUserTickets = true,
        isLoadingMyTickets = false,
        isLoadingDetails = false,
        isCreatingUserTicket = false,
        isCreatingMyTicket = false,
        isReplying = false,
        isUpdatingStatus = false,
        isLoadingUsers = false,
        errorMessage = null,
        detailsErrorMessage = null,
        userRefreshKey = '',
        myRefreshKey = '',
        userVisibleCount = 10,
        myVisibleCount = 10;

  static const Object _unset = Object();

  final AdminSupportTab selectedTab;
  final List<AdminSupportTicketListItem> userTickets;
  final List<AdminSupportTicketListItem> myTickets;
  final String userSearch;
  final String mySearch;
  final AdminSupportTicketStatus? userStatusFilter;
  final AdminSupportTicketStatus? myStatusFilter;
  final String? selectedTicketId;
  final AdminSupportTab? selectedTicketTab;
  final AdminSupportTicketDetails? selectedTicketDetails;
  final List<AdminSupportUserMini> users;
  final bool isLoadingUserTickets;
  final bool isLoadingMyTickets;
  final bool isLoadingDetails;
  final bool isCreatingUserTicket;
  final bool isCreatingMyTicket;
  final bool isReplying;
  final bool isUpdatingStatus;
  final bool isLoadingUsers;
  final String? errorMessage;
  final String? detailsErrorMessage;
  final String userRefreshKey;
  final String myRefreshKey;
  final int userVisibleCount;
  final int myVisibleCount;

  bool get isLoadingCurrentTab => selectedTab == AdminSupportTab.userTickets
      ? isLoadingUserTickets
      : isLoadingMyTickets;

  List<AdminSupportTicketListItem> get filteredUserTickets =>
      _applyLocalFilters(userTickets, userSearch, userStatusFilter);

  List<AdminSupportTicketListItem> get filteredMyTickets =>
      _applyLocalFilters(myTickets, mySearch, myStatusFilter);

  List<AdminSupportTicketListItem> get currentFilteredTickets =>
      selectedTab == AdminSupportTab.userTickets
          ? filteredUserTickets
          : filteredMyTickets;

  int get currentVisibleCount => selectedTab == AdminSupportTab.userTickets
      ? userVisibleCount
      : myVisibleCount;

  bool get hasMoreVisible {
    final total = currentFilteredTickets.length;
    return currentVisibleCount < total;
  }

  List<AdminSupportTicketListItem> get visibleCurrentTickets {
    final tickets = currentFilteredTickets;
    final take = currentVisibleCount.clamp(0, tickets.length);
    return tickets.take(take).toList(growable: false);
  }

  AdminSupportState copyWith({
    AdminSupportTab? selectedTab,
    List<AdminSupportTicketListItem>? userTickets,
    List<AdminSupportTicketListItem>? myTickets,
    String? userSearch,
    String? mySearch,
    Object? userStatusFilter = _unset,
    Object? myStatusFilter = _unset,
    Object? selectedTicketId = _unset,
    Object? selectedTicketTab = _unset,
    Object? selectedTicketDetails = _unset,
    List<AdminSupportUserMini>? users,
    bool? isLoadingUserTickets,
    bool? isLoadingMyTickets,
    bool? isLoadingDetails,
    bool? isCreatingUserTicket,
    bool? isCreatingMyTicket,
    bool? isReplying,
    bool? isUpdatingStatus,
    bool? isLoadingUsers,
    Object? errorMessage = _unset,
    Object? detailsErrorMessage = _unset,
    String? userRefreshKey,
    String? myRefreshKey,
    int? userVisibleCount,
    int? myVisibleCount,
  }) {
    return AdminSupportState(
      selectedTab: selectedTab ?? this.selectedTab,
      userTickets: userTickets ?? this.userTickets,
      myTickets: myTickets ?? this.myTickets,
      userSearch: userSearch ?? this.userSearch,
      mySearch: mySearch ?? this.mySearch,
      userStatusFilter: identical(userStatusFilter, _unset)
          ? this.userStatusFilter
          : userStatusFilter as AdminSupportTicketStatus?,
      myStatusFilter: identical(myStatusFilter, _unset)
          ? this.myStatusFilter
          : myStatusFilter as AdminSupportTicketStatus?,
      selectedTicketId: identical(selectedTicketId, _unset)
          ? this.selectedTicketId
          : selectedTicketId as String?,
      selectedTicketTab: identical(selectedTicketTab, _unset)
          ? this.selectedTicketTab
          : selectedTicketTab as AdminSupportTab?,
      selectedTicketDetails: identical(selectedTicketDetails, _unset)
          ? this.selectedTicketDetails
          : selectedTicketDetails as AdminSupportTicketDetails?,
      users: users ?? this.users,
      isLoadingUserTickets: isLoadingUserTickets ?? this.isLoadingUserTickets,
      isLoadingMyTickets: isLoadingMyTickets ?? this.isLoadingMyTickets,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isCreatingUserTicket: isCreatingUserTicket ?? this.isCreatingUserTicket,
      isCreatingMyTicket: isCreatingMyTicket ?? this.isCreatingMyTicket,
      isReplying: isReplying ?? this.isReplying,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      detailsErrorMessage: identical(detailsErrorMessage, _unset)
          ? this.detailsErrorMessage
          : detailsErrorMessage as String?,
      userRefreshKey: userRefreshKey ?? this.userRefreshKey,
      myRefreshKey: myRefreshKey ?? this.myRefreshKey,
      userVisibleCount: userVisibleCount ?? this.userVisibleCount,
      myVisibleCount: myVisibleCount ?? this.myVisibleCount,
    );
  }

  static List<AdminSupportTicketListItem> _applyLocalFilters(
    List<AdminSupportTicketListItem> source,
    String query,
    AdminSupportTicketStatus? status,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty && status == null) return source;
    return source.where((item) {
      final matchesStatus = status == null || item.status == status;
      if (!matchesStatus) {
        return false;
      }

      if (normalized.isEmpty) {
        return true;
      }

      final hay = [
        item.title,
        item.displayTicketNo,
        item.status.label,
        item.category.label,
        item.priority.label,
        item.fromUser?.displayName ?? '',
        item.toUser?.displayName ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(normalized);
    }).toList(growable: false);
  }
}
