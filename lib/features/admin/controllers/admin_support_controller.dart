import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_support_model.dart';
import '../models/admin_support_state.dart';
import '../services/admin_support_service.dart';

class AdminSupportController extends StateNotifier<AdminSupportState> {
  AdminSupportController(this._service)
      : super(const AdminSupportState.initial()) {
    unawaited(loadInitial());
  }

  final AdminSupportService _service;

  Future<void> loadInitial() async {
    await loadUserTickets();
  }

  Future<void> selectTab(AdminSupportTab tab) async {
    state = state.copyWith(selectedTab: tab, errorMessage: null);
    if (tab == AdminSupportTab.myTickets &&
        state.myTickets.isEmpty &&
        !state.isLoadingMyTickets) {
      await loadMyTickets();
    }
  }

  Future<void> refreshCurrentTab() async {
    if (state.selectedTab == AdminSupportTab.userTickets) {
      await refreshUserTickets();
    } else {
      await refreshMyTickets();
    }
  }

  Future<void> refreshUserTickets() async {
    state = state.copyWith(
      userRefreshKey: DateTime.now().millisecondsSinceEpoch.toString(),
      errorMessage: null,
    );
    await loadUserTickets();
    if (state.selectedTicketTab == AdminSupportTab.userTickets &&
        state.selectedTicketId != null) {
      await loadTicketDetails(
        tab: AdminSupportTab.userTickets,
        ticketId: state.selectedTicketId!,
      );
    }
  }

  Future<void> refreshMyTickets() async {
    state = state.copyWith(
      myRefreshKey: DateTime.now().millisecondsSinceEpoch.toString(),
      errorMessage: null,
    );
    await loadMyTickets();
    if (state.selectedTicketTab == AdminSupportTab.myTickets &&
        state.selectedTicketId != null) {
      await loadTicketDetails(
        tab: AdminSupportTab.myTickets,
        ticketId: state.selectedTicketId!,
      );
    }
  }

  Future<void> loadUserTickets() async {
    state = state.copyWith(isLoadingUserTickets: true, errorMessage: null);

    try {
      final tickets = await _service.getUserTickets(
        refreshKey: state.userRefreshKey,
      );

      final keepSelection =
          state.selectedTicketTab == AdminSupportTab.userTickets &&
              state.selectedTicketId != null &&
              tickets.any((t) => t.id == state.selectedTicketId);

      state = state.copyWith(
        userTickets: tickets,
        isLoadingUserTickets: false,
        errorMessage: null,
        userVisibleCount: 10,
        selectedTicketId: keepSelection ? state.selectedTicketId : null,
        selectedTicketTab: keepSelection ? state.selectedTicketTab : null,
        selectedTicketDetails:
            keepSelection ? state.selectedTicketDetails : null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingUserTickets: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> loadMyTickets() async {
    state = state.copyWith(isLoadingMyTickets: true, errorMessage: null);

    try {
      final tickets = await _service.getMyTickets(
        refreshKey: state.myRefreshKey,
      );

      final keepSelection =
          state.selectedTicketTab == AdminSupportTab.myTickets &&
              state.selectedTicketId != null &&
              tickets.any((t) => t.id == state.selectedTicketId);

      state = state.copyWith(
        myTickets: tickets,
        isLoadingMyTickets: false,
        errorMessage: null,
        myVisibleCount: 10,
        selectedTicketId: keepSelection ? state.selectedTicketId : null,
        selectedTicketTab: keepSelection ? state.selectedTicketTab : null,
        selectedTicketDetails:
            keepSelection ? state.selectedTicketDetails : null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMyTickets: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  void setSearchQuery(AdminSupportTab tab, String value) {
    if (tab == AdminSupportTab.userTickets) {
      state = state.copyWith(userSearch: value, userVisibleCount: 10);
      return;
    }

    state = state.copyWith(mySearch: value, myVisibleCount: 10);
  }

  Future<void> setStatusFilter(
    AdminSupportTab tab,
    AdminSupportTicketStatus? status,
  ) async {
    if (tab == AdminSupportTab.userTickets) {
      state = state.copyWith(userStatusFilter: status, userVisibleCount: 10);
      return;
    }

    state = state.copyWith(myStatusFilter: status, myVisibleCount: 10);
  }

  void loadMore(AdminSupportTab tab) {
    if (tab == AdminSupportTab.userTickets) {
      final next = (state.userVisibleCount + 10)
          .clamp(0, state.filteredUserTickets.length);
      state = state.copyWith(userVisibleCount: next);
      return;
    }
    final next =
        (state.myVisibleCount + 10).clamp(0, state.filteredMyTickets.length);
    state = state.copyWith(myVisibleCount: next);
  }

  Future<void> loadUsers() async {
    if (state.isLoadingUsers) return;

    state = state.copyWith(isLoadingUsers: true, errorMessage: null);
    try {
      final users = await _service.getUsers(
        refreshKey: state.userRefreshKey,
      );
      state = state.copyWith(isLoadingUsers: false, users: users);
    } catch (error) {
      state = state.copyWith(
        isLoadingUsers: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<AdminSupportTicketCreatedResult> createUserTicket(
    AdminSupportCreateTicketRequest request,
  ) async {
    if (state.isCreatingUserTicket) {
      throw StateError('Ticket creation is already in progress.');
    }

    state = state.copyWith(isCreatingUserTicket: true, errorMessage: null);
    try {
      final created = await _service.createUserTicket(request);
      state = state.copyWith(isCreatingUserTicket: false);
      await refreshUserTickets();
      return created;
    } catch (error) {
      state = state.copyWith(
        isCreatingUserTicket: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<AdminSupportTicketCreatedResult> createMyTicket(
    AdminSupportCreateTicketRequest request,
  ) async {
    if (state.isCreatingMyTicket) {
      throw StateError('Ticket creation is already in progress.');
    }

    state = state.copyWith(isCreatingMyTicket: true, errorMessage: null);
    try {
      final created = await _service.createMyTicket(request);
      state = state.copyWith(isCreatingMyTicket: false);
      await refreshMyTickets();
      return created;
    } catch (error) {
      state = state.copyWith(
        isCreatingMyTicket: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> openTicket({
    required AdminSupportTab tab,
    required String ticketId,
  }) async {
    state = state.copyWith(
      selectedTicketId: ticketId,
      selectedTicketTab: tab,
      selectedTicketDetails: null,
      detailsErrorMessage: null,
    );
    await loadTicketDetails(tab: tab, ticketId: ticketId);
  }

  Future<void> loadTicketDetails({
    required AdminSupportTab tab,
    required String ticketId,
  }) async {
    if (ticketId.trim().isEmpty) return;

    state = state.copyWith(
      isLoadingDetails: true,
      detailsErrorMessage: null,
    );

    try {
      final detail = tab == AdminSupportTab.userTickets
          ? await _service.getUserTicketById(ticketId,
              refreshKey: state.userRefreshKey)
          : await _service.getMyTicketById(ticketId,
              refreshKey: state.myRefreshKey);

      if (state.selectedTicketId != ticketId ||
          state.selectedTicketTab != tab) {
        return;
      }

      state = state.copyWith(
        selectedTicketDetails: detail,
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

  Future<void> sendReply({
    required AdminSupportTab tab,
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    if (state.isReplying) return;

    state = state.copyWith(isReplying: true, detailsErrorMessage: null);
    try {
      if (tab == AdminSupportTab.userTickets) {
        await _service.sendUserTicketReply(
          ticketId: ticketId,
          message: message,
          attachments: attachments,
        );
      } else {
        await _service.sendMyTicketReply(
          ticketId: ticketId,
          message: message,
          attachments: attachments,
        );
      }

      state = state.copyWith(isReplying: false);
      if (tab == AdminSupportTab.userTickets) {
        await refreshUserTickets();
      } else {
        await refreshMyTickets();
      }
      await loadTicketDetails(tab: tab, ticketId: ticketId);
    } catch (error) {
      state = state.copyWith(
        isReplying: false,
        detailsErrorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> updateTicketStatus({
    required AdminSupportTab tab,
    required String ticketId,
    required AdminSupportTicketStatus status,
  }) async {
    if (state.isUpdatingStatus) return;

    state = state.copyWith(isUpdatingStatus: true, detailsErrorMessage: null);
    try {
      if (tab == AdminSupportTab.userTickets) {
        await _service.updateUserTicketStatus(id: ticketId, status: status);
        await refreshUserTickets();
      } else {
        await _service.updateMyTicketStatus(id: ticketId, status: status);
        await refreshMyTickets();
      }
      await loadTicketDetails(tab: tab, ticketId: ticketId);
      state = state.copyWith(isUpdatingStatus: false);
    } catch (error) {
      state = state.copyWith(
        isUpdatingStatus: false,
        detailsErrorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final nested = data['message'] ??
            (data['data'] is Map ? (data['data'] as Map)['message'] : null);
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
      final msg = error.message?.trim();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    if (error is ArgumentError) {
      final msg = error.message?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
