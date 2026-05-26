import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_support_model.dart';
import '../models/user_support_state.dart';
import '../services/user_support_service.dart';

class UserSupportController extends StateNotifier<UserSupportState> {
  UserSupportController({required UserSupportService service})
      : _service = service,
        super(const UserSupportState.initial());

  final UserSupportService _service;
  int _listRequestSerial = 0;
  int _detailRequestSerial = 0;

  Future<void> loadTickets() {
    return _loadTickets(refreshKey: state.refreshKey);
  }

  Future<void> refreshTickets() async {
    final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(refreshKey: refreshKey);

    await _loadTickets(refreshKey: refreshKey, forceRefresh: true);

    final selectedTicketId = state.selectedTicket?.id.trim();
    if (selectedTicketId != null && selectedTicketId.isNotEmpty) {
      await selectTicket(selectedTicketId, force: true);
    }
  }

  Future<UserSupportTicketDetail?> selectTicket(
    String ticketId, {
    bool force = false,
  }) async {
    final id = ticketId.trim();
    if (id.isEmpty) {
      return null;
    }

    final current = state.selectedTicket;
    if (!force && current != null && current.id == id) {
      return current;
    }

    final serial = ++_detailRequestSerial;
    state = state.copyWith(
      selectedTicket: current?.id == id ? current : null,
      isLoadingDetail: true,
      detailErrorMessage: null,
    );

    try {
      final detail = await _service.fetchTicketById(id);
      if (!mounted || serial != _detailRequestSerial) {
        return detail;
      }

      state = _withFiltered(
        state.copyWith(
          selectedTicket: detail,
          tickets: _replaceTicket(state.tickets, detail),
          isLoadingDetail: false,
          detailErrorMessage: null,
        ),
      );
      return detail;
    } catch (error) {
      if (!mounted || serial != _detailRequestSerial) {
        return null;
      }
      state = state.copyWith(
        isLoadingDetail: false,
        detailErrorMessage: _toErrorMessage(error),
      );
      return null;
    }
  }

  Future<UserSupportTicketDetail?> createTicket({
    required String title,
    required String message,
    UserSupportTicketCategory category = UserSupportTicketCategory.other,
    UserSupportTicketPriority priority = UserSupportTicketPriority.medium,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    if (state.isCreating) {
      return null;
    }

    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
      detailErrorMessage: null,
      preparedAttachments: attachments,
    );

    try {
      final detail = await _service.createTicket(
        title: title,
        message: message,
        category: category,
        priority: priority,
        attachments: attachments,
      );
      if (!mounted) {
        return detail;
      }

      state = _withFiltered(
        state.copyWith(
          selectedTicket: detail.id.trim().isEmpty ? null : detail,
          tickets: _replaceTicket(state.tickets, detail),
          isCreating: false,
          preparedAttachments: const <PlatformFile>[],
          errorMessage: null,
          detailErrorMessage: null,
        ),
      );

      final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
      state = state.copyWith(refreshKey: refreshKey);
      await _loadTickets(refreshKey: refreshKey, forceRefresh: true);

      final createdTicketId = detail.id.trim();
      if (mounted && createdTicketId.isNotEmpty) {
        return selectTicket(createdTicketId, force: true);
      }

      return detail;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      state = state.copyWith(
        isCreating: false,
        errorMessage: _toErrorMessage(error),
      );
      return null;
    }
  }

  Future<UserSupportTicketDetail?> replyToTicket({
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    final id = ticketId.trim();
    if (id.isEmpty || state.isReplying) {
      return null;
    }

    if (_isClosedTicket(id)) {
      state = state.copyWith(
        detailErrorMessage: 'Closed tickets cannot be replied to.',
      );
      return null;
    }

    state = state.copyWith(
      isReplying: true,
      detailErrorMessage: null,
      preparedAttachments: attachments,
    );

    try {
      final detail = await _service.replyToTicket(
        ticketId: id,
        message: message,
        attachments: attachments,
      );
      if (!mounted) {
        return detail;
      }

      state = _withFiltered(
        state.copyWith(
          selectedTicket: detail,
          tickets: _replaceTicket(state.tickets, detail),
          isReplying: false,
          preparedAttachments: const <PlatformFile>[],
          detailErrorMessage: null,
        ),
      );

      final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
      state = state.copyWith(refreshKey: refreshKey);
      await _loadTickets(refreshKey: refreshKey, forceRefresh: true);
      return state.selectedTicket ?? detail;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      state = state.copyWith(
        isReplying: false,
        detailErrorMessage: _toErrorMessage(error),
      );
      return null;
    }
  }

  void setStatusFilter(UserSupportTicketStatus? status) {
    state = _withFiltered(
      state.copyWith(
        selectedStatusFilter: status,
        errorMessage: null,
      ),
    );
  }

  void setSearchQuery(String query) {
    state = _withFiltered(
      state.copyWith(
        searchQuery: query.trim(),
        errorMessage: null,
      ),
    );
  }

  void setPreparedAttachments(List<PlatformFile> attachments) {
    state = state.copyWith(preparedAttachments: attachments);
  }

  void clearPreparedAttachments() {
    state = state.copyWith(preparedAttachments: const <PlatformFile>[]);
  }

  void clearError() {
    state = state.copyWith(
      errorMessage: null,
      detailErrorMessage: null,
    );
  }

  Future<void> _loadTickets({
    required String? refreshKey,
    bool forceRefresh = false,
  }) async {
    final serial = ++_listRequestSerial;
    final shouldShowLoader = state.tickets.isEmpty && !forceRefresh;

    state = state.copyWith(
      isLoadingList: shouldShowLoader,
      isRefreshingList: forceRefresh || state.tickets.isNotEmpty,
      errorMessage: null,
    );

    try {
      final tickets = await _service.fetchTickets(refreshKey: refreshKey);
      if (!mounted || serial != _listRequestSerial) {
        return;
      }

      state = _withFiltered(
        state.copyWith(
          tickets: tickets,
          isLoadingList: false,
          isRefreshingList: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted || serial != _listRequestSerial) {
        return;
      }
      state = state.copyWith(
        isLoadingList: false,
        isRefreshingList: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  UserSupportState _withFiltered(UserSupportState next) {
    final query = next.searchQuery.trim().toLowerCase();
    final status = next.selectedStatusFilter;

    final filteredTickets = next.tickets.where((ticket) {
      final matchesStatus = status == null || ticket.status == status;
      if (!matchesStatus) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return ticket.searchContent.contains(query);
    }).toList(growable: false);

    return next.copyWith(filteredTickets: filteredTickets);
  }

  List<UserSupportTicketListItem> _replaceTicket(
    List<UserSupportTicketListItem> tickets,
    UserSupportTicketDetail detail,
  ) {
    final id = detail.id.trim();
    if (id.isEmpty) {
      return tickets;
    }

    final replacement = detail.toListItem();
    var didReplace = false;
    final updated = tickets.map((ticket) {
      if (ticket.id != id) {
        return ticket;
      }
      didReplace = true;
      return replacement;
    }).toList(growable: true);

    if (!didReplace) {
      updated.insert(0, replacement);
    }

    updated.sort(UserSupportTicketListItem.compareInboxOrder);
    return updated;
  }

  bool _isClosedTicket(String ticketId) {
    final selected = state.selectedTicket;
    if (selected != null && selected.id == ticketId) {
      return selected.isClosed;
    }

    return state.ticketById(ticketId)?.isClosed ?? false;
  }

  String _toErrorMessage(Object error) {
    if (error is ArgumentError) {
      final message = error.message?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

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
    return raw.isEmpty ? 'Support tickets could not be loaded.' : raw;
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
