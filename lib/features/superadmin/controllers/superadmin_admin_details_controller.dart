import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_admin_details_model.dart';
import '../models/superadmin_admin_details_state.dart';
import '../models/superadmin_payments_model.dart';
import '../services/superadmin_admin_details_service.dart';
import '../services/superadmin_payments_service.dart';

class SuperadminAdminDetailsController
    extends StateNotifier<SuperadminAdminDetailsState> {
  SuperadminAdminDetailsController({
    required String adminId,
    required SuperadminAdminDetailsService detailsService,
    required SuperadminPaymentsService paymentsService,
  })  : _adminId = adminId,
        _detailsService = detailsService,
        _paymentsService = paymentsService,
        super(SuperadminAdminDetailsState.initial(adminId: adminId));

  final String _adminId;
  final SuperadminAdminDetailsService _detailsService;
  final SuperadminPaymentsService _paymentsService;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  Future<void> loadInitial() async {
    await refreshAdmin();
  }

  Future<void> refreshAdmin() async {
    state = state.copyWith(
      isLoadingAdmin: true,
      errorMessage: null,
    );
    try {
      final admin = await _detailsService.getAdminDetails(_adminId);
      state = state.copyWith(
        admin: admin,
        isLoadingAdmin: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingAdmin: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  void selectTab(SuperadminAdminDetailsTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(
      selectedTab: tab,
      sectionErrorMessage: null,
    );
    _lazyLoadForTab(tab);
  }

  void _lazyLoadForTab(SuperadminAdminDetailsTab tab) {
    switch (tab) {
      case SuperadminAdminDetailsTab.profile:
        break;
      case SuperadminAdminDetailsTab.creditHistory:
        if (state.creditLogs.isEmpty && !state.isLoadingCredits) {
          unawaited(loadCreditLogs());
        }
        break;
      case SuperadminAdminDetailsTab.payments:
        if (state.transactions.isEmpty &&
            state.transactionAnalytics == null &&
            !state.isLoadingPayments) {
          unawaited(loadPayments());
        }
        break;
      case SuperadminAdminDetailsTab.documents:
        if (state.documents.isEmpty && !state.isLoadingDocuments) {
          unawaited(loadDocuments());
        }
        if (state.documentTypes.isEmpty && !state.isLoadingDocumentTypes) {
          unawaited(loadDocumentTypes());
        }
        break;
      case SuperadminAdminDetailsTab.vehicles:
        if (state.vehicles.isEmpty && !state.isLoadingVehicles) {
          unawaited(loadVehicles());
        }
        break;
      case SuperadminAdminDetailsTab.adminActivity:
        if (state.activityLogs.isEmpty && !state.isLoadingActivity) {
          unawaited(loadActivity());
        }
        break;
    }
  }

  // -------------------------------------------------------------------------
  // Profile tab
  // -------------------------------------------------------------------------

  Future<bool> updateProfile(SuperadminUpdateAdminRequest request) async {
    state = state.copyWith(
      isSavingProfile: true,
      sectionErrorMessage: null,
    );
    try {
      final admin = await _detailsService.updateAdminDetails(
        adminId: _adminId,
        request: request,
      );
      state = state.copyWith(
        admin: admin,
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
      await _detailsService.setAdminActive(
        adminId: _adminId,
        isActive: isActive,
      );
      final admin = state.admin?.copyWith(isActive: isActive);
      state = state.copyWith(
        admin: admin,
        isUpdatingStatus: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingStatus: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(
      isChangingPassword: true,
      sectionErrorMessage: null,
    );
    try {
      await _detailsService.updateAdminPassword(
        adminId: _adminId,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
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

  Future<bool> updateCompany(
    SuperadminAdminCompanyUpdateRequest request,
  ) async {
    state = state.copyWith(
      isSavingCompany: true,
      sectionErrorMessage: null,
    );
    try {
      final admin = await _detailsService.updateAdminCompany(
        adminId: _adminId,
        request: request,
      );
      state = state.copyWith(
        admin: admin,
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

  Future<bool> deleteAdmin() async {
    state = state.copyWith(
      isDeletingAdmin: true,
      sectionErrorMessage: null,
    );
    try {
      await _detailsService.deleteAdmin(_adminId);
      state = state.copyWith(isDeletingAdmin: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isDeletingAdmin: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Credit history tab
  // -------------------------------------------------------------------------

  Future<void> loadCreditLogs() async {
    state = state.copyWith(
      isLoadingCredits: true,
      sectionErrorMessage: null,
    );
    try {
      final logs = await _detailsService.getCreditLogs(_adminId);
      state = state.copyWith(
        creditLogs: logs,
        isLoadingCredits: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCredits: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> updateCredits(SuperadminCreditUpdateRequest request) async {
    state = state.copyWith(
      isUpdatingCredits: true,
      sectionErrorMessage: null,
    );
    try {
      await _detailsService.updateCredits(
        adminId: _adminId,
        request: request,
      );
      state = state.copyWith(isUpdatingCredits: false);
      await Future.wait<void>(<Future<void>>[
        loadCreditLogs(),
        refreshAdmin(),
      ]);
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingCredits: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Payments tab
  // -------------------------------------------------------------------------

  static const int _paymentsLimit = 50;

  String _formatYmd(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  ({DateTime from, DateTime to}) _defaultPaymentsRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month, now.day);
    return (from: from, to: to);
  }

  Future<void> loadPayments({DateTime? from, DateTime? to}) async {
    final range = _defaultPaymentsRange();
    final resolvedFrom = from ?? state.paymentsFrom ?? range.from;
    final resolvedTo = to ?? state.paymentsTo ?? range.to;

    state = state.copyWith(
      isLoadingPayments: true,
      sectionErrorMessage: null,
      paymentsFrom: resolvedFrom,
      paymentsTo: resolvedTo,
    );
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _paymentsService.getTransactions(
          adminId: _adminId,
          page: 1,
          limit: _paymentsLimit,
        ),
        _paymentsService.getTransactionsAnalytics(
          adminId: _adminId,
          from: _formatYmd(resolvedFrom),
          to: _formatYmd(resolvedTo),
        ),
      ]);
      final page = results[0] as SuperadminTransactionPage;
      final analytics = results[1] as SuperadminTransactionsAnalytics;
      state = state.copyWith(
        transactions: page.items,
        transactionAnalytics: analytics,
        paymentsPage: page.page,
        paymentsHasMore: page.hasMore,
        isLoadingPayments: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingPayments: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> loadMorePayments() async {
    if (state.isLoadingMorePayments ||
        state.isLoadingPayments ||
        !state.paymentsHasMore) {
      return;
    }
    final nextPage = state.paymentsPage + 1;
    state = state.copyWith(isLoadingMorePayments: true);
    try {
      final page = await _paymentsService.getTransactions(
        adminId: _adminId,
        page: nextPage,
        limit: _paymentsLimit,
      );
      state = state.copyWith(
        transactions: <SuperadminTransaction>[
          ...state.transactions,
          ...page.items,
        ],
        paymentsPage: page.page,
        paymentsHasMore: page.hasMore,
        isLoadingMorePayments: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMorePayments: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> recordManualPayment(
    SuperadminRecordPaymentRequest request,
  ) async {
    state = state.copyWith(
      isRecordingPayment: true,
      sectionErrorMessage: null,
    );
    try {
      await _paymentsService.recordManualPayment(request);
      state = state.copyWith(isRecordingPayment: false);
      await Future.wait<void>(<Future<void>>[
        loadPayments(),
        refreshAdmin(),
      ]);
      return true;
    } catch (error) {
      state = state.copyWith(
        isRecordingPayment: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Documents tab
  // -------------------------------------------------------------------------

  Future<void> loadDocuments() async {
    state = state.copyWith(
      isLoadingDocuments: true,
      sectionErrorMessage: null,
    );
    try {
      final docs = await _detailsService.getAdminDocuments(_adminId);
      state = state.copyWith(
        documents: docs,
        isLoadingDocuments: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDocuments: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> loadDocumentTypes() async {
    state = state.copyWith(isLoadingDocumentTypes: true);
    try {
      final types = await _detailsService.getDocumentTypes();
      state = state.copyWith(
        documentTypes: types,
        isLoadingDocumentTypes: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDocumentTypes: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> uploadDocument(SuperadminAdminDocumentRequest request) async {
    state = state.copyWith(
      isUploadingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _detailsService.uploadAdminDocument(request);
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
    required SuperadminAdminDocumentRequest request,
  }) async {
    state = state.copyWith(
      isUploadingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _detailsService.updateAdminDocument(
        docId: docId,
        request: request,
      );
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

  Future<bool> deleteDocument(String docId) async {
    state = state.copyWith(
      isDeletingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _detailsService.deleteAdminDocument(docId);
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

  // -------------------------------------------------------------------------
  // Vehicles tab
  // -------------------------------------------------------------------------

  Future<void> loadVehicles() async {
    state = state.copyWith(
      isLoadingVehicles: true,
      sectionErrorMessage: null,
    );
    try {
      final vehicles = await _detailsService.getAdminVehicles(_adminId);
      state = state.copyWith(
        vehicles: vehicles,
        isLoadingVehicles: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingVehicles: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Activity tab
  // -------------------------------------------------------------------------

  Future<void> loadActivity() async {
    state = state.copyWith(
      isLoadingActivity: true,
      sectionErrorMessage: null,
    );
    try {
      final page = await _detailsService.getAdminActivityLogs(
        adminId: _adminId,
        q: state.activitySearch,
        actionPrefix: state.activityActionPrefix,
        from: _formatDateForApi(state.activityFrom),
        to: _formatDateForApi(state.activityTo),
      );
      state = state.copyWith(
        activityLogs: page.items,
        activityNextCursorId: page.nextCursorId,
        activityHasMore: page.hasMore,
        isLoadingActivity: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingActivity: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> loadMoreActivity() async {
    if (!state.activityHasMore || state.isLoadingMoreActivity) return;
    state = state.copyWith(isLoadingMoreActivity: true);
    try {
      final page = await _detailsService.getAdminActivityLogs(
        adminId: _adminId,
        q: state.activitySearch,
        actionPrefix: state.activityActionPrefix,
        from: _formatDateForApi(state.activityFrom),
        to: _formatDateForApi(state.activityTo),
        cursorId: state.activityNextCursorId,
      );
      final combined = <SuperadminAdminActivityLog>[
        ...state.activityLogs,
        ...page.items,
      ];
      state = state.copyWith(
        activityLogs: combined,
        activityNextCursorId: page.nextCursorId,
        activityHasMore: page.hasMore,
        isLoadingMoreActivity: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMoreActivity: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  void setActivitySearch(String value) {
    state = state.copyWith(activitySearch: value);
  }

  void setActivityActionPrefix(String value) {
    state = state.copyWith(activityActionPrefix: value);
  }

  void setActivityDateRange({DateTime? from, DateTime? to}) {
    state = state.copyWith(
      activityFrom: from,
      activityTo: to,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String? _formatDateForApi(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
      return 'Network error. Please try again.';
    }
    if (error is ArgumentError) {
      final message = error.message?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    }
    return error.toString();
  }
}
