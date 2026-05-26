import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_support_model.dart';
import '../models/superadmin_support_state.dart';
import '../services/superadmin_support_service.dart';

class SuperadminSupportController
    extends StateNotifier<SuperadminSupportState> {
  SuperadminSupportController(this._service)
      : super(const SuperadminSupportState.initial()) {
    unawaited(loadTickets());
  }

  final SuperadminSupportService _service;
  Timer? _searchDebounce;

  Future<void> loadTickets() async {
    state = state.copyWith(
      isLoadingTickets: true,
      errorMessage: null,
    );

    try {
      final tickets = await _service.getTickets(
        status: state.statusFilter,
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery,
        refreshKey: state.refreshKey.trim().isEmpty ? null : state.refreshKey,
      );

      final selectedId = state.selectedTicketId;
      final hasSelected =
          selectedId != null && tickets.any((item) => item.id == selectedId);

      state = state.copyWith(
        tickets: tickets,
        selectedTicketId: hasSelected ? selectedId : null,
        selectedTicketDetails: hasSelected ? state.selectedTicketDetails : null,
        isLoadingTickets: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingTickets: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refreshTickets() async {
    state = state.copyWith(
      refreshKey: DateTime.now().millisecondsSinceEpoch.toString(),
      errorMessage: null,
    );

    await loadTickets();

    if (state.selectedTicketId != null) {
      await loadSelectedTicket();
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      errorMessage: null,
    );

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(loadTickets());
    });
  }

  Future<void> setStatusFilter(SuperadminSupportTicketStatus? status) async {
    state = state.copyWith(
      statusFilter: status,
      errorMessage: null,
    );

    await loadTickets();
  }

  Future<void> selectTicket(int id) async {
    if (id <= 0) {
      return;
    }

    if (state.selectedTicketId == id && state.selectedTicketDetails != null) {
      return;
    }

    state = state.copyWith(
      selectedTicketId: id,
      selectedTicketDetails: null,
      detailsErrorMessage: null,
    );

    await loadSelectedTicket();
  }

  void clearSelectedTicket() {
    state = state.copyWith(
      selectedTicketId: null,
      selectedTicketDetails: null,
      detailsErrorMessage: null,
    );
  }

  Future<void> loadSelectedTicket() async {
    final ticketId = state.selectedTicketId;
    if (ticketId == null || ticketId <= 0) {
      return;
    }

    state = state.copyWith(
      isLoadingDetails: true,
      detailsErrorMessage: null,
    );

    try {
      final details = await _service.getTicketById(
        ticketId,
        refreshKey: state.refreshKey.trim().isEmpty ? null : state.refreshKey,
      );

      if (state.selectedTicketId != ticketId) {
        return;
      }

      state = state.copyWith(
        selectedTicketDetails: details,
        isLoadingDetails: false,
        detailsErrorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDetails: false,
        detailsErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> loadAdminsForCreateTicket() async {
    if (state.isLoadingAdmins) {
      return;
    }

    state = state.copyWith(
      isLoadingAdmins: true,
      errorMessage: null,
    );

    try {
      final admins = await _service.getAdminsForCreateTicket(
        refreshKey: state.refreshKey.trim().isEmpty ? null : state.refreshKey,
      );

      state = state.copyWith(
        adminsForCreateTicket: admins,
        isLoadingAdmins: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingAdmins: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<SuperadminSupportTicketCreatedResult> createTicket({
    required int adminId,
    required String title,
    required String message,
    required SuperadminSupportTicketCategory category,
    required SuperadminSupportTicketPriority priority,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
    );

    try {
      final result = await _service.createTicket(
        adminId: adminId,
        title: title,
        message: message,
        category: category,
        priority: priority,
        attachments: attachments,
      );

      state = state.copyWith(isCreating: false);

      await refreshTickets();
      if (result.ticketId > 0) {
        await selectTicket(result.ticketId);
      }

      return result;
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<SuperadminSupportMessageSentResult> sendReply({
    required int ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    state = state.copyWith(
      isReplying: true,
      detailsErrorMessage: null,
    );

    try {
      final result = await _service.sendReply(
        ticketId: ticketId,
        message: message,
        attachments: attachments,
      );

      state = state.copyWith(isReplying: false);
      await refreshTickets();
      await selectTicket(ticketId);
      return result;
    } catch (error) {
      state = state.copyWith(
        isReplying: false,
        detailsErrorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> updateStatus({
    required int id,
    required SuperadminSupportTicketStatus status,
  }) async {
    state = state.copyWith(
      isUpdatingStatus: true,
      detailsErrorMessage: null,
      errorMessage: null,
    );

    try {
      await _service.updateTicketStatus(id: id, status: status);

      final selectedDetails = state.selectedTicketDetails;
      SuperadminSupportTicketDetails? updatedDetails = selectedDetails;
      if (selectedDetails != null && state.selectedTicketId == id) {
        updatedDetails = _withUpdatedStatus(selectedDetails, status);
      }

      state = state.copyWith(
        isUpdatingStatus: false,
        selectedTicketDetails: updatedDetails,
      );

      await refreshTickets();
    } catch (error) {
      state = state.copyWith(
        isUpdatingStatus: false,
        detailsErrorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  SuperadminSupportTicketDetails _withUpdatedStatus(
    SuperadminSupportTicketDetails details,
    SuperadminSupportTicketStatus status,
  ) {
    return SuperadminSupportTicketDetails(
      id: details.id,
      ticketNo: details.ticketNo,
      title: details.title,
      status: status,
      category: details.category,
      priority: details.priority,
      fromUserId: details.fromUserId,
      toUserId: details.toUserId,
      adminUserId: details.adminUserId,
      createdAt: details.createdAt,
      updatedAt: details.updatedAt,
      closedAt: details.closedAt,
      fromUser: details.fromUser,
      messages: details.messages,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
