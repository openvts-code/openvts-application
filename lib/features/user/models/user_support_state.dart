import 'package:file_picker/file_picker.dart';

import 'user_support_model.dart';

class UserSupportState {
  const UserSupportState({
    required this.tickets,
    required this.filteredTickets,
    required this.selectedTicket,
    required this.selectedStatusFilter,
    required this.searchQuery,
    required this.preparedAttachments,
    required this.isLoadingList,
    required this.isRefreshingList,
    required this.isLoadingDetail,
    required this.isCreating,
    required this.isReplying,
    required this.errorMessage,
    required this.detailErrorMessage,
    required this.refreshKey,
  });

  const UserSupportState.initial()
      : tickets = const <UserSupportTicketListItem>[],
        filteredTickets = const <UserSupportTicketListItem>[],
        selectedTicket = null,
        selectedStatusFilter = null,
        searchQuery = '',
        preparedAttachments = const <PlatformFile>[],
        isLoadingList = true,
        isRefreshingList = false,
        isLoadingDetail = false,
        isCreating = false,
        isReplying = false,
        errorMessage = null,
        detailErrorMessage = null,
        refreshKey = null;

  static const Object _unset = Object();

  final List<UserSupportTicketListItem> tickets;
  final List<UserSupportTicketListItem> filteredTickets;
  final UserSupportTicketDetail? selectedTicket;
  final UserSupportTicketStatus? selectedStatusFilter;
  final String searchQuery;
  final List<PlatformFile> preparedAttachments;
  final bool isLoadingList;
  final bool isRefreshingList;
  final bool isLoadingDetail;
  final bool isCreating;
  final bool isReplying;
  final String? errorMessage;
  final String? detailErrorMessage;
  final String? refreshKey;

  bool get hasTickets => tickets.isNotEmpty;
  bool get hasFilteredTickets => filteredTickets.isNotEmpty;
  bool get hasSelectedTicket => selectedTicket != null;
  bool get isMutating => isCreating || isReplying;
  bool get hasActiveFilters {
    return selectedStatusFilter != null || searchQuery.trim().isNotEmpty;
  }

  UserSupportTicketListItem? ticketById(String ticketId) {
    final normalized = ticketId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    for (final ticket in tickets) {
      if (ticket.id == normalized) {
        return ticket;
      }
    }

    return null;
  }

  UserSupportState copyWith({
    List<UserSupportTicketListItem>? tickets,
    List<UserSupportTicketListItem>? filteredTickets,
    Object? selectedTicket = _unset,
    Object? selectedStatusFilter = _unset,
    String? searchQuery,
    List<PlatformFile>? preparedAttachments,
    bool? isLoadingList,
    bool? isRefreshingList,
    bool? isLoadingDetail,
    bool? isCreating,
    bool? isReplying,
    Object? errorMessage = _unset,
    Object? detailErrorMessage = _unset,
    Object? refreshKey = _unset,
  }) {
    return UserSupportState(
      tickets: tickets ?? this.tickets,
      filteredTickets: filteredTickets ?? this.filteredTickets,
      selectedTicket: identical(selectedTicket, _unset)
          ? this.selectedTicket
          : selectedTicket as UserSupportTicketDetail?,
      selectedStatusFilter: identical(selectedStatusFilter, _unset)
          ? this.selectedStatusFilter
          : selectedStatusFilter as UserSupportTicketStatus?,
      searchQuery: searchQuery ?? this.searchQuery,
      preparedAttachments: preparedAttachments ?? this.preparedAttachments,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isCreating: isCreating ?? this.isCreating,
      isReplying: isReplying ?? this.isReplying,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      detailErrorMessage: identical(detailErrorMessage, _unset)
          ? this.detailErrorMessage
          : detailErrorMessage as String?,
      refreshKey: identical(refreshKey, _unset)
          ? this.refreshKey
          : refreshKey as String?,
    );
  }
}
