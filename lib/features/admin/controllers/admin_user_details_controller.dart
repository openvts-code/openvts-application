import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_user_details_model.dart';
import '../models/admin_user_details_state.dart';
import '../services/admin_user_details_service.dart';

class AdminUserDetailsController extends StateNotifier<AdminUserDetailsState> {
  AdminUserDetailsController({
    required String userId,
    required AdminUserDetailsService service,
    AdminUserDetails? initialUser,
  })  : _userId = userId,
        _service = service,
        super(
          AdminUserDetailsState.initial(
            userId: userId,
            initialUser: initialUser,
          ),
        );

  final String _userId;
  final AdminUserDetailsService _service;
  final Set<AdminUserDetailsTab> _loadedTabs = <AdminUserDetailsTab>{};

  /// Seed initial data from list item to preserve values that detail API may omit.
  void seedInitialData({
    int? vehicleCount,
    DateTime? lastLogin,
  }) {
    // Only seed if we don't have detail data yet
    if (state.user != null) return;

    // Store these values so they can be used by resolvers
    // The state.initialUser already holds the list item data
    // No action needed here - resolvers use state.initialUser directly
  }

  Future<void> loadInitial() async {
    await loadProfile();
  }

  void selectTab(AdminUserDetailsTab tab) {
    if (state.selectedTab == tab) {
      return;
    }
    state = state.copyWith(
      selectedTab: tab,
      sectionErrorMessage: null,
    );
    _lazyLoadForTab(tab);
  }

  Future<void> refreshCurrentTab() async {
    switch (state.selectedTab) {
      case AdminUserDetailsTab.profile:
        await loadProfile();
        break;
      case AdminUserDetailsTab.vehicles:
        await loadVehicles();
        break;
      case AdminUserDetailsTab.drivers:
        await loadDrivers();
        break;
      case AdminUserDetailsTab.documents:
        await loadDocuments();
        break;
      case AdminUserDetailsTab.tickets:
        await loadTickets();
        break;
      case AdminUserDetailsTab.payments:
        await loadPayments();
        break;
      case AdminUserDetailsTab.logs:
        await loadLogs();
        break;
    }
  }

  void _lazyLoadForTab(AdminUserDetailsTab tab) {
    if (_loadedTabs.contains(tab)) {
      return;
    }

    switch (tab) {
      case AdminUserDetailsTab.profile:
        if (!state.isLoadingProfile) {
          unawaited(loadProfile());
        }
        break;
      case AdminUserDetailsTab.vehicles:
        if (!state.isLoadingVehicles) {
          unawaited(loadVehicles());
        }
        break;
      case AdminUserDetailsTab.drivers:
        if (!state.isLoadingDrivers) {
          unawaited(loadDrivers());
        }
        break;
      case AdminUserDetailsTab.documents:
        if (!state.isLoadingDocuments) {
          unawaited(loadDocuments());
        }
        break;
      case AdminUserDetailsTab.tickets:
        if (!state.isLoadingTickets) {
          unawaited(loadTickets());
        }
        break;
      case AdminUserDetailsTab.payments:
        if (!state.isLoadingPayments) {
          unawaited(loadPayments());
        }
        break;
      case AdminUserDetailsTab.logs:
        if (!state.isLoadingLogs) {
          unawaited(loadLogs());
        }
        break;
    }
  }

  Future<void> loadProfile() async {
    state = state.copyWith(
      isLoadingProfile: true,
      errorMessage: null,
      sectionErrorMessage: null,
    );
    try {
      var user = await _service.getUserDetails(_userId);

      // Preserve known status from initialUser if detail API returned default true
      // and we have explicit false from the list
      if (user.isActive == true &&
          state.initialUser != null &&
          state.initialUser!.isActive == false) {
        user = user.copyWith(isActive: false);
      }

      // Preserve known vehicle count if detail API returned 0
      // and we have a positive count from the list
      if (user.vehicleCount == 0 &&
          state.initialUser != null &&
          state.initialUser!.vehicleCount > 0) {
        user = user.copyWith(vehicleCount: state.initialUser!.vehicleCount);
      }

      _loadedTabs.add(AdminUserDetailsTab.profile);
      state = state.copyWith(
        user: user,
        isLoadingProfile: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingProfile: false,
        errorMessage: state.user == null ? _errorMessage(error) : null,
        sectionErrorMessage: state.user == null ? null : _errorMessage(error),
      );
    }
  }

  Future<bool> updateProfile(AdminUpdateUserDetailsRequest request) async {
    state = state.copyWith(
      isSavingProfile: true,
      sectionErrorMessage: null,
    );
    try {
      final user = await _service.updateUserDetails(_userId, request);
      state = state.copyWith(
        user: user,
        isSavingProfile: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingProfile: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateStatus(bool isActive) async {
    state = state.copyWith(
      isUpdatingStatus: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateUserStatus(_userId, isActive);
      state = state.copyWith(
        user: state.user?.copyWith(isActive: isActive),
        isUpdatingStatus: false,
      );
      if (state.user == null) {
        await loadProfile();
      }
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingStatus: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(
      isChangingPassword: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateUserPassword(_userId, newPassword);
      state = state.copyWith(isChangingPassword: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isChangingPassword: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateCompany(AdminUpdateUserCompanyRequest request) async {
    state = state.copyWith(
      isSavingCompany: true,
      sectionErrorMessage: null,
    );
    try {
      final user = await _service.updateCompanyDetails(_userId, request);
      state = state.copyWith(
        user: user,
        isSavingCompany: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingCompany: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<AdminUserCompany?> getCompanyDetails() async {
    try {
      return await _service.getCompanyDetails(_userId);
    } catch (error) {
      state = state.copyWith(sectionErrorMessage: _errorMessage(error));
      rethrow;
    }
  }

  Future<void> loadVehicles() async {
    state = state.copyWith(
      isLoadingVehicles: true,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<List<AdminUserVehicle>>([
        _service.getLinkedVehicles(_userId),
        _service.getUnlinkedVehicles(_userId),
      ]);
      _loadedTabs.add(AdminUserDetailsTab.vehicles);
      state = state.copyWith(
        linkedVehicles: results[0],
        availableVehicles: results[1],
        isLoadingVehicles: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingVehicles: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> linkVehicle(String vehicleId) async {
    state = state.copyWith(
      isLinkingVehicle: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.linkVehicle(_userId, vehicleId);
      state = state.copyWith(isLinkingVehicle: false);
      await loadVehicles();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLinkingVehicle: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> unlinkVehicle(String vehicleId) async {
    state = state.copyWith(
      isUnlinkingVehicle: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.unlinkVehicle(_userId, vehicleId);
      state = state.copyWith(isUnlinkingVehicle: false);
      await loadVehicles();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUnlinkingVehicle: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadDrivers() async {
    state = state.copyWith(
      isLoadingDrivers: true,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<List<AdminUserDriver>>([
        _service.getLinkedDrivers(_userId),
        _service.getUnlinkedDrivers(_userId),
      ]);
      _loadedTabs.add(AdminUserDetailsTab.drivers);
      state = state.copyWith(
        linkedDrivers: results[0],
        availableDrivers: results[1],
        isLoadingDrivers: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDrivers: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> linkDriver(String driverId) async {
    state = state.copyWith(
      isLinkingDriver: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.linkDriver(_userId, driverId);
      state = state.copyWith(isLinkingDriver: false);
      await loadDrivers();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLinkingDriver: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> unlinkDriver(String driverId) async {
    state = state.copyWith(
      isUnlinkingDriver: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.unlinkDriver(_userId, driverId);
      state = state.copyWith(isUnlinkingDriver: false);
      await loadDrivers();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUnlinkingDriver: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadDocuments() async {
    final shouldLoadTypes = state.documentTypes.isEmpty;
    state = state.copyWith(
      isLoadingDocuments: true,
      isLoadingDocumentTypes: shouldLoadTypes,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<dynamic>([
        _service.getDocuments(_userId),
        if (shouldLoadTypes)
          _service.getDocumentTypes()
        else
          Future<List<AdminDocumentTypeOption>>.value(state.documentTypes),
      ]);
      _loadedTabs.add(AdminUserDetailsTab.documents);
      state = state.copyWith(
        documents: results[0] as List<AdminUserDocument>,
        documentTypes: results[1] as List<AdminDocumentTypeOption>,
        isLoadingDocuments: false,
        isLoadingDocumentTypes: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDocuments: false,
        isLoadingDocumentTypes: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> uploadDocument(AdminUserDocumentRequest request) async {
    state = state.copyWith(
      isUploadingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.uploadDocument(request);
      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUploadingDocument: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateDocument({
    required String docId,
    required AdminUserDocumentRequest request,
  }) async {
    state = state.copyWith(
      isUpdatingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateDocument(docId: docId, request: request);
      state = state.copyWith(isUpdatingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingDocument: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = state.copyWith(
      isDeletingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.deleteDocument(docId);
      state = state.copyWith(isDeletingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      state = state.copyWith(
        isDeletingDocument: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadTickets() async {
    state = state.copyWith(
      isLoadingTickets: true,
      sectionErrorMessage: null,
    );
    try {
      final tickets = await _service.getTickets(_userId);
      _loadedTabs.add(AdminUserDetailsTab.tickets);
      state = state.copyWith(
        tickets: tickets,
        isLoadingTickets: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingTickets: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> openTicket(String ticketId) async {
    state = state.copyWith(
      isLoadingTicketDetails: true,
      sectionErrorMessage: null,
    );
    try {
      final ticket = await _service.getTicketById(ticketId);
      state = state.copyWith(
        selectedTicket: ticket,
        tickets: _replaceTicket(state.tickets, ticket),
        isLoadingTicketDetails: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingTicketDetails: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> createTicket({
    required String title,
    required String message,
    required String category,
    required String priority,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    state = state.copyWith(
      isCreatingTicket: true,
      sectionErrorMessage: null,
    );
    try {
      final ticket = await _service.createTicket(
        userId: _userId,
        title: title,
        message: message,
        category: category,
        priority: priority,
        attachments: attachments,
      );
      state = state.copyWith(
        selectedTicket: ticket,
        tickets: _replaceTicket(state.tickets, ticket),
        isCreatingTicket: false,
      );
      await loadTickets();
      return true;
    } catch (error) {
      state = state.copyWith(
        isCreatingTicket: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> replyTicket({
    required String ticketId,
    required String message,
    List<PlatformFile> attachments = const <PlatformFile>[],
  }) async {
    state = state.copyWith(
      isReplyingTicket: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.replyTicket(
        ticketId: ticketId,
        message: message,
        attachments: attachments,
      );
      state = state.copyWith(isReplyingTicket: false);
      await openTicket(ticketId);
      await loadTickets();
      return true;
    } catch (error) {
      state = state.copyWith(
        isReplyingTicket: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateTicketStatus(String ticketId, String status) async {
    state = state.copyWith(
      isUpdatingTicketStatus: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateTicketStatus(ticketId, status);
      state = state.copyWith(isUpdatingTicketStatus: false);
      await openTicket(ticketId);
      await loadTickets();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingTicketStatus: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadPayments({
    int page = 1,
    int limit = 100,
    String? status,
    DateTime? from,
    DateTime? to,
    String? q,
  }) async {
    state = state.copyWith(
      isLoadingPayments: true,
      sectionErrorMessage: null,
    );
    try {
      final paymentPage = await _service.getPayments(
        userId: _userId,
        page: page,
        limit: limit,
        status: status,
        from: _formatDateForApi(from),
        to: _formatDateForApi(to),
        q: q,
      );
      _loadedTabs.add(AdminUserDetailsTab.payments);
      state = state.copyWith(
        payments: paymentPage.items,
        paymentsPage: paymentPage,
        isLoadingPayments: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingPayments: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> renewVehiclesPayment(
    AdminRenewVehiclesPaymentRequest request,
  ) async {
    state = state.copyWith(
      isRenewingPayment: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.renewVehiclesPayment(request);
      state = state.copyWith(isRenewingPayment: false);
      await Future.wait<void>([
        loadPayments(),
        loadVehicles(),
      ]);
      return true;
    } catch (error) {
      state = state.copyWith(
        isRenewingPayment: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadLogs({int limit = 20}) async {
    state = state.copyWith(
      isLoadingLogs: true,
      sectionErrorMessage: null,
    );
    try {
      final page = await _service.getActivityLogs(
        userId: _userId,
        limit: limit,
        q: state.logSearch,
        actionPrefix: state.logActionPrefix,
        from: _formatDateForApi(state.logFrom),
        to: _formatDateForApi(state.logTo),
      );
      _loadedTabs.add(AdminUserDetailsTab.logs);
      state = state.copyWith(
        logs: page.items,
        logsNextCursorId: page.nextCursorId,
        logsHasMore: page.hasMore,
        isLoadingLogs: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingLogs: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> loadMoreLogs({int limit = 20}) async {
    if (!state.logsHasMore || state.isLoadingMoreLogs || state.isLoadingLogs) {
      return;
    }
    state = state.copyWith(isLoadingMoreLogs: true);
    try {
      final page = await _service.getActivityLogs(
        userId: _userId,
        limit: limit,
        cursorId: state.logsNextCursorId,
        q: state.logSearch,
        actionPrefix: state.logActionPrefix,
        from: _formatDateForApi(state.logFrom),
        to: _formatDateForApi(state.logTo),
      );
      state = state.copyWith(
        logs: <AdminUserActivityLog>[
          ...state.logs,
          ...page.items,
        ],
        logsNextCursorId: page.nextCursorId,
        logsHasMore: page.hasMore,
        isLoadingMoreLogs: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMoreLogs: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  void setLogFilters({
    String? q,
    String? actionPrefix,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    state = state.copyWith(
      logSearch: q ?? state.logSearch,
      logActionPrefix: actionPrefix ?? state.logActionPrefix,
      logFrom: clearFrom ? null : from ?? state.logFrom,
      logTo: clearTo ? null : to ?? state.logTo,
      logs: const <AdminUserActivityLog>[],
      logsNextCursorId: null,
      logsHasMore: false,
      sectionErrorMessage: null,
    );
    _loadedTabs.remove(AdminUserDetailsTab.logs);
  }

  List<AdminUserTicket> _replaceTicket(
    List<AdminUserTicket> tickets,
    AdminUserTicket ticket,
  ) {
    final id = ticket.id.trim();
    if (id.isEmpty) {
      return tickets;
    }
    var replaced = false;
    final next = tickets.map((item) {
      if (item.id == id) {
        replaced = true;
        return ticket;
      }
      return item;
    }).toList(growable: false);
    if (replaced) {
      return next;
    }
    return <AdminUserTicket>[ticket, ...tickets];
  }

  String? _formatDateForApi(DateTime? value) {
    if (value == null) {
      return null;
    }
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is List && message.isNotEmpty) {
          return message.join(', ');
        }
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Network error. Please try again.';
    }
    if (error is ArgumentError) {
      final message = error.message?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    return error.toString();
  }
}
