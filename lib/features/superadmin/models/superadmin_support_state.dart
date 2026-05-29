import 'superadmin_support_model.dart';

class SuperadminSupportState {
  const SuperadminSupportState({
    required this.tickets,
    required this.statusCounts,
    required this.allTicketCount,
    required this.selectedTicketId,
    required this.selectedTicketDetails,
    required this.adminsForCreateTicket,
    required this.searchQuery,
    required this.statusFilter,
    required this.isLoadingTickets,
    required this.isLoadingDetails,
    required this.isCreating,
    required this.isReplying,
    required this.isUpdatingStatus,
    required this.isLoadingAdmins,
    required this.errorMessage,
    required this.detailsErrorMessage,
    required this.refreshKey,
  });

  const SuperadminSupportState.initial()
      : tickets = const <SuperadminSupportTicketListItem>[],
        statusCounts = const <SuperadminSupportTicketStatus, int>{},
        allTicketCount = 0,
        selectedTicketId = null,
        selectedTicketDetails = null,
        adminsForCreateTicket = const <SuperadminSupportAdminMini>[],
        searchQuery = '',
        statusFilter = null,
        isLoadingTickets = true,
        isLoadingDetails = false,
        isCreating = false,
        isReplying = false,
        isUpdatingStatus = false,
        isLoadingAdmins = false,
        errorMessage = null,
        detailsErrorMessage = null,
        refreshKey = '';

  static const Object _unset = Object();

  final List<SuperadminSupportTicketListItem> tickets;
  final Map<SuperadminSupportTicketStatus, int> statusCounts;
  final int allTicketCount;
  final int? selectedTicketId;
  final SuperadminSupportTicketDetails? selectedTicketDetails;
  final List<SuperadminSupportAdminMini> adminsForCreateTicket;
  final String searchQuery;
  final SuperadminSupportTicketStatus? statusFilter;
  final bool isLoadingTickets;
  final bool isLoadingDetails;
  final bool isCreating;
  final bool isReplying;
  final bool isUpdatingStatus;
  final bool isLoadingAdmins;
  final String? errorMessage;
  final String? detailsErrorMessage;
  final String refreshKey;

  bool get hasTickets => tickets.isNotEmpty;

  bool get hasSelectedTicket => selectedTicketId != null;

  bool get hasDetails => selectedTicketDetails != null;

  bool get isMutating => isCreating || isReplying || isUpdatingStatus;

  SuperadminSupportTicketListItem? get selectedTicket {
    final id = selectedTicketId;
    if (id == null) {
      return null;
    }

    for (final item in tickets) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  SuperadminSupportState copyWith({
    List<SuperadminSupportTicketListItem>? tickets,
    Map<SuperadminSupportTicketStatus, int>? statusCounts,
    int? allTicketCount,
    Object? selectedTicketId = _unset,
    Object? selectedTicketDetails = _unset,
    List<SuperadminSupportAdminMini>? adminsForCreateTicket,
    String? searchQuery,
    Object? statusFilter = _unset,
    bool? isLoadingTickets,
    bool? isLoadingDetails,
    bool? isCreating,
    bool? isReplying,
    bool? isUpdatingStatus,
    bool? isLoadingAdmins,
    Object? errorMessage = _unset,
    Object? detailsErrorMessage = _unset,
    String? refreshKey,
  }) {
    return SuperadminSupportState(
      tickets: tickets ?? this.tickets,
      statusCounts: statusCounts ?? this.statusCounts,
      allTicketCount: allTicketCount ?? this.allTicketCount,
      selectedTicketId: identical(selectedTicketId, _unset)
          ? this.selectedTicketId
          : selectedTicketId as int?,
      selectedTicketDetails: identical(selectedTicketDetails, _unset)
          ? this.selectedTicketDetails
          : selectedTicketDetails as SuperadminSupportTicketDetails?,
      adminsForCreateTicket:
          adminsForCreateTicket ?? this.adminsForCreateTicket,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as SuperadminSupportTicketStatus?,
      isLoadingTickets: isLoadingTickets ?? this.isLoadingTickets,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isCreating: isCreating ?? this.isCreating,
      isReplying: isReplying ?? this.isReplying,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isLoadingAdmins: isLoadingAdmins ?? this.isLoadingAdmins,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      detailsErrorMessage: identical(detailsErrorMessage, _unset)
          ? this.detailsErrorMessage
          : detailsErrorMessage as String?,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}
