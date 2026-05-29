import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/superadmin_admin_details_model.dart';
import '../models/superadmin_admin_details_state.dart';
import '../models/superadmin_administrator_model.dart';
import '../models/superadmin_payments_model.dart';
import '../services/superadmin_admin_details_service.dart';
import '../services/superadmin_payments_service.dart';

class SuperadminAdminDetailsController
    extends StateNotifier<SuperadminAdminDetailsState> {
  SuperadminAdminDetailsController({
    required String adminId,
    required SuperadminAdminDetailsService detailsService,
    required SuperadminPaymentsService paymentsService,
    required this.onAdminStatusChanged,
  })  : _adminId = adminId,
        _detailsService = detailsService,
        _paymentsService = paymentsService,
        super(SuperadminAdminDetailsState.initial(adminId: adminId));

  final String _adminId;
  final SuperadminAdminDetailsService _detailsService;
  final SuperadminPaymentsService _paymentsService;

  /// Callback to sync status changes with the administrators list.
  final void Function(String adminId, bool isActive)? onAdminStatusChanged;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  Future<void> loadInitial() async {
    await refreshAdmin();
  }

  /// Seed initial vehicle count from the administrators list item.
  /// Call this from the screen when initialAdmin is available.
  void seedInitialVehicleCount(int? count) {
    if (count != null && count > 0 && state.vehicleCount == null) {
      state = state.copyWith(vehicleCount: count);
    }
  }

  /// Seed initialAdmin from the administrators list item.
  /// Call this from the screen when initialAdmin is available.
  void seedInitialAdmin(SuperadminAdministrator? admin) {
    if (admin != null && state.initialAdmin == null) {
      final resolvedLastLogin = admin.lastLoginAt;
      state = state.copyWith(
        initialAdmin: admin,
        resolvedLastLogin: resolvedLastLogin,
      );
    }
  }

  /// Seed initial data from the administrators list item.
  /// Call this from the screen when initialAdmin is available.
  void seedInitialData({int? vehicleCount, DateTime? lastLogin}) {
    if (vehicleCount != null && vehicleCount > 0 && state.vehicleCount == null) {
      state = state.copyWith(vehicleCount: vehicleCount);
    }

    if (lastLogin != null && state.resolvedLastLogin == null) {
      state = state.copyWith(resolvedLastLogin: lastLogin);
    }
  }

  Future<void> refreshAdmin() async {
    state = state.copyWith(
      isLoadingAdmin: true,
      errorMessage: null,
    );
    try {
      final admin = await _detailsService.getAdminDetails(_adminId);

      // Preserve vehicle count if detail API doesn't return it
      final preservedVehicleCount = state.vehicleCount;
      final preservedAdminCount = state.admin?.totalVehicles;
      final preservedLastLogin = state.admin?.recentLogin;
      final resolvedLastLoginFromState = state.resolvedLastLogin;

      var updatedAdmin = admin;

      // Preserve vehicle count if missing
      if (admin.totalVehicles < 0) {
        final knownCount = preservedVehicleCount ??
                          (preservedAdminCount != null && preservedAdminCount >= 0
                              ? preservedAdminCount
                              : null);
        if (knownCount != null) {
          updatedAdmin = updatedAdmin.copyWith(totalVehicles: knownCount);
        }
      }

      // Preserve last login if missing: use detail API value, or fallback to previous, or use resolved value
      if (admin.recentLogin == null) {
        final knownLastLogin = preservedLastLogin ?? resolvedLastLoginFromState;
        if (knownLastLogin != null) {
          updatedAdmin = updatedAdmin.copyWith(recentLogin: knownLastLogin);
        }
      } else {
        // Update resolved last login when detail API provides it
        state = state.copyWith(resolvedLastLogin: admin.recentLogin);
      }

      state = state.copyWith(
        admin: updatedAdmin,
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
        if (!state.hasLoadedCreditLogs && !state.isLoadingCredits) {
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
        if (!state.hasLoadedDocuments && !state.isLoadingDocuments) {
          unawaited(loadDocuments());
        }
        if (!state.hasLoadedDocumentTypes && !state.isLoadingDocumentTypes) {
          unawaited(loadDocumentTypes());
        }
        break;
      case SuperadminAdminDetailsTab.vehicles:
        if (!state.hasLoadedVehicles && !state.isLoadingVehicles) {
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
  // Ensure-loaded helpers (idempotent, safe to call from child widgets)
  // -------------------------------------------------------------------------

  Future<void> ensureCreditLogsLoaded() async {
    if (state.hasLoadedCreditLogs || state.isLoadingCredits) return;
    await loadCreditLogs();
  }

  Future<void> ensureDocumentsLoaded() async {
    if (state.hasLoadedDocuments || state.isLoadingDocuments) return;
    await loadDocuments();
  }

  Future<void> ensureDocumentTypesLoaded() async {
    if (state.hasLoadedDocumentTypes || state.isLoadingDocumentTypes) return;
    await loadDocumentTypes();
  }

  Future<void> ensureVehiclesLoaded() async {
    if (state.hasLoadedVehicles || state.isLoadingVehicles) return;
    await loadVehicles();
  }

  Future<void> ensureVehicleCountLoaded() async {
    if (state.vehicleCount != null) return;
    if (state.hasLoadedVehicles) {
      state = state.copyWith(vehicleCount: state.vehicles.length);
      return;
    }
    if (state.isLoadingVehicles) return;
    await loadVehicles();
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
    final previousValue = state.admin?.isActive;

    state = state.copyWith(
      isUpdatingStatus: true,
      sectionErrorMessage: null,
    );

    try {
      await _detailsService.setAdminActive(
        adminId: _adminId,
        isActive: isActive,
      );

      // Optimistic update
      state = state.copyWith(
        admin: state.admin?.copyWith(isActive: isActive),
        isUpdatingStatus: false,
      );

      // Sync with server; preserve the toggled status if backend response
      // omits or returns stale isActive field.
      try {
        final fresh = await _detailsService.getAdminDetails(_adminId);

        // If fresh response has explicit isActive value, use it.
        // Otherwise preserve our confirmed optimistic value.
        // Note: parser defaults to true when all status fields are missing,
        // so we can't distinguish "true from API" vs "defaulted to true".
        // Solution: always trust our optimistic value unless the fresh
        // response explicitly contradicts it.
        final shouldPreserveOptimistic =
            fresh.isActive != isActive && previousValue != null;

        if (shouldPreserveOptimistic) {
          // Backend returned stale/wrong value, keep our confirmed state
          state = state.copyWith(
            admin: fresh.copyWith(isActive: isActive),
          );
        } else {
          // Backend confirmed our value or returned different valid state
          state = state.copyWith(admin: fresh);
        }
      } catch (_) {
        // Server refresh failed — keep the optimistic state.
      }

      // Notify list controller to update cached admin status
      onAdminStatusChanged?.call(_adminId, isActive);

      return true;
    } catch (error) {
      // Rollback on failure
      state = state.copyWith(
        admin: state.admin?.copyWith(isActive: previousValue ?? true),
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

  Future<void> loadCreditLogs({bool force = false}) async {
    if (!force && state.hasLoadedCreditLogs) return;
    if (state.isLoadingCredits) return;
    state = state.copyWith(
      isLoadingCredits: true,
      creditsErrorMessage: null,
    );
    try {
      final logs = await _detailsService.getCreditLogs(_adminId);
      state = state.copyWith(
        creditLogs: logs,
        isLoadingCredits: false,
        hasLoadedCreditLogs: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCredits: false,
        creditsErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> updateCredits(SuperadminCreditUpdateRequest request) async {
    state = state.copyWith(
      isUpdatingCredits: true,
      creditsErrorMessage: null,
    );
    try {
      await _detailsService.updateCredits(
        adminId: _adminId,
        request: request,
      );
      state = state.copyWith(isUpdatingCredits: false);
      await Future.wait<void>(<Future<void>>[
        loadCreditLogs(force: true),
        refreshAdmin(),
      ]);
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingCredits: false,
        creditsErrorMessage: _errorMessage(error),
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
      final transaction = await _paymentsService.recordManualPayment(request);

      state = state.copyWith(
        isRecordingPayment: false,
        paymentsPage: 1,
      );

      final optimisticTransactions = _insertTransactionOptimistically(
        state.transactions,
        transaction,
      );

      state = state.copyWith(
        transactions: optimisticTransactions,
      );

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

  List<SuperadminTransaction> _insertTransactionOptimistically(
    List<SuperadminTransaction> current,
    SuperadminTransaction newTransaction,
  ) {
    final key = newTransaction.id.isEmpty
        ? _fallbackTransactionKey(newTransaction)
        : newTransaction.id;

    final merged = <String, SuperadminTransaction>{
      key: newTransaction,
      for (final item in current)
        if (item.id != newTransaction.id ||
            (item.id.isEmpty &&
                _fallbackTransactionKey(item) !=
                    _fallbackTransactionKey(newTransaction)))
          (item.id.isEmpty ? _fallbackTransactionKey(item) : item.id): item,
    };

    final values = merged.values.toList(growable: false)
      ..sort((left, right) {
        final leftTime = left.createdAt?.millisecondsSinceEpoch ?? 0;
        final rightTime = right.createdAt?.millisecondsSinceEpoch ?? 0;
        return rightTime.compareTo(leftTime);
      });

    return values;
  }

  String _fallbackTransactionKey(SuperadminTransaction transaction) {
    return [
      transaction.createdAtRaw,
      transaction.amount,
      transaction.reference,
      transaction.providerRef,
    ].join('|');
  }

  // -------------------------------------------------------------------------
  // Documents tab
  // -------------------------------------------------------------------------

  Future<void> loadDocuments({bool force = false}) async {
    if (!force && state.hasLoadedDocuments) return;
    if (state.isLoadingDocuments) return;
    state = state.copyWith(
      isLoadingDocuments: true,
      documentsErrorMessage: null,
    );
    try {
      final docs = await _detailsService.getAdminDocuments(_adminId);
      state = state.copyWith(
        documents: docs,
        isLoadingDocuments: false,
        hasLoadedDocuments: true,
        documentsErrorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDocuments: false,
        documentsErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> loadDocumentTypes({bool force = false}) async {
    if (!force && state.hasLoadedDocumentTypes) return;
    if (state.isLoadingDocumentTypes) return;
    state = state.copyWith(
      isLoadingDocumentTypes: true,
      documentTypesErrorMessage: null,
    );
    try {
      final types = await _detailsService.getDocumentTypes();
      state = state.copyWith(
        documentTypes: types,
        isLoadingDocumentTypes: false,
        hasLoadedDocumentTypes: true,
        documentTypesErrorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDocumentTypes: false,
        documentTypesErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> uploadDocument(SuperadminAdminDocumentRequest request) async {
    state = state.copyWith(
      isUploadingDocument: true,
      documentMutationErrorMessage: null,
    );
    try {
      await _detailsService.uploadAdminDocument(request);
      state = state.copyWith(
        isUploadingDocument: false,
        documentMutationErrorMessage: null,
      );
      await loadDocuments(force: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isUploadingDocument: false,
        documentMutationErrorMessage: _errorMessage(error),
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
      documentMutationErrorMessage: null,
    );
    try {
      await _detailsService.updateAdminDocument(
        docId: docId,
        request: request,
      );
      state = state.copyWith(
        isUploadingDocument: false,
        documentMutationErrorMessage: null,
      );
      await loadDocuments(force: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isUploadingDocument: false,
        documentMutationErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = state.copyWith(
      isDeletingDocument: true,
      documentMutationErrorMessage: null,
    );
    try {
      await _detailsService.deleteAdminDocument(docId);
      state = state.copyWith(
        isDeletingDocument: false,
        documentMutationErrorMessage: null,
      );
      await loadDocuments(force: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isDeletingDocument: false,
        documentMutationErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Vehicles tab
  // -------------------------------------------------------------------------

  Future<void> loadVehicles({bool force = false}) async {
    if (!force && state.hasLoadedVehicles) return;
    if (state.isLoadingVehicles) return;
    state = state.copyWith(
      isLoadingVehicles: true,
      vehiclesErrorMessage: null,
    );
    try {
      final vehicles = await _detailsService.getAdminVehicles(_adminId);
      state = state.copyWith(
        vehicles: vehicles,
        vehicleCount: vehicles.length,
        isLoadingVehicles: false,
        hasLoadedVehicles: true,
        admin: state.admin?.copyWith(totalVehicles: vehicles.length),
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingVehicles: false,
        vehiclesErrorMessage: _errorMessage(error),
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
    if (!state.activityHasMore ||
        state.isLoadingMoreActivity ||
        state.isLoadingActivity) {
      return;
    }
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

  // Helper: sanitize and limit messages shown to users.
  String _safeMessage(String? value, String fallback) {
    if (value == null) return fallback;
    var msg = value.trim();
    if (msg.isEmpty) return fallback;

    // Avoid raw 'Instance of' or class dumps
    if (msg.contains('Instance of')) return fallback;

    // Avoid raw JSON/maps or arrays being displayed directly
    final t = msg.trim();
    if ((t.startsWith('{') && t.endsWith('}')) ||
        (t.startsWith('[') && t.endsWith(']'))) {
      return fallback;
    }

    // If looks like a stack trace/multi-line, use the first non-empty line
    if (msg.contains('\n')) {
      final lines = msg
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      if (lines.isEmpty) return fallback;
      // If stack-trace markers exist, prefer the first line only
      if (lines.length > 1 ||
          lines.any((l) =>
              l.contains('package:') ||
              l.startsWith('#') ||
              l.contains('Stack trace'))) {
        msg = lines.first;
      } else {
        msg = lines.join(' ');
      }
    }

    msg = msg.trim();
    if (msg.isEmpty) return fallback;

    // Truncate to a safe length
    const maxLen = 220;
    if (msg.length > maxLen) msg = '${msg.substring(0, maxLen - 3)}...';

    return msg;
  }

  dynamic _valueForKeyInsensitive(Map m, String key) {
    if (m.containsKey(key)) return m[key];
    final lk = key.toLowerCase();
    for (final e in m.entries) {
      if (e.key.toString().toLowerCase() == lk) return e.value;
    }
    return null;
  }

  String? _extractMessageFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      return s.isEmpty ? null : s;
    }
    if (value is List) {
      final parts = value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      if (parts.isNotEmpty) return parts.join(', ');
      return null;
    }
    if (value is Map) {
      // Check common keys in order of priority
      final keys = ['message', 'error', 'detail', 'errors'];
      // If nested envelope under 'data'
      final dataNode = _valueForKeyInsensitive(value, 'data');
      if (dataNode != null && dataNode != value) {
        final nested = _extractMessageFromDynamic(dataNode);
        if (nested != null && nested.isNotEmpty) return nested;
      }

      for (final k in keys) {
        final v = _valueForKeyInsensitive(value, k);
        if (v != null) {
          final extracted = _extractMessageFromDynamic(v);
          if (extracted != null && extracted.isNotEmpty) return extracted;
        }
      }

      // If 'errors' is a map of field->list
      final errorsNode = _valueForKeyInsensitive(value, 'errors');
      if (errorsNode is Map) {
        final parts = <String>[];
        for (final e in errorsNode.entries) {
          final v = _extractMessageFromDynamic(e.value);
          if (v != null && v.isNotEmpty) parts.add(v);
        }
        if (parts.isNotEmpty) return parts.join(', ');
      }

      return null;
    }

    // Fallback to toString (will be sanitized by _safeMessage)
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _errorMessage(Object error) {
    const genericFallback = 'Something went wrong. Please try again.';

    // ApiException (highest priority)
    if (error is ApiException) {
      final candidates = <String>[];
      final top = error.message;
      if (top.trim().isNotEmpty) candidates.add(top.trim());
      final detailsMsg = _extractMessageFromDynamic(error.details);
      if (detailsMsg != null && detailsMsg.trim().isNotEmpty) {
        candidates.add(detailsMsg.trim());
      }
      for (final c in candidates) {
        final safe = _safeMessage(c, '');
        if (safe.isNotEmpty) return safe;
      }
      return genericFallback;
    }

    // DioException
    if (error is DioException) {
      final data = error.response?.data;
      final dataMsg = _extractMessageFromDynamic(data);
      if (dataMsg != null && dataMsg.trim().isNotEmpty) {
        final safe = _safeMessage(dataMsg, '');
        if (safe.isNotEmpty) return safe;
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        final safe = _safeMessage(error.message!.trim(), '');
        if (safe.isNotEmpty) return safe;
      }
      return 'Network error. Please try again.';
    }

    // Common Dart errors
    if (error is ArgumentError) {
      final msg = error.message?.toString();
      final safe = _safeMessage(msg, '');
      if (safe.isNotEmpty) return safe;
    }
    if (error is FormatException) {
      final safe = _safeMessage(error.message, '');
      if (safe.isNotEmpty) return safe;
    }
    if (error is StateError) {
      final safe = _safeMessage(error.message, '');
      if (safe.isNotEmpty) return safe;
    }

    // Strings
    if (error is String) {
      final safe = _safeMessage(error, '');
      if (safe.isNotEmpty) return safe;
    }

    // Generic toString() fallback
    final raw = error.toString();
    final safeRaw = _safeMessage(raw, '');
    if (safeRaw.isNotEmpty) return safeRaw;

    return genericFallback;
  }
}
