import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_driver_details_model.dart';
import '../models/admin_driver_details_state.dart';
import '../services/admin_drivers_service.dart';

class AdminDriverDetailsController
    extends StateNotifier<AdminDriverDetailsState> {
  AdminDriverDetailsController({
    required String driverId,
    required AdminDriversService service,
  })  : _driverId = driverId,
        _service = service,
        super(AdminDriverDetailsState.initial(driverId: driverId));

  final String _driverId;
  final AdminDriversService _service;
  final Set<AdminDriverDetailsTab> _loadedTabs = <AdminDriverDetailsTab>{};

  Future<void> loadInitial() async {
    await loadProfile();
  }

  void selectTab(AdminDriverDetailsTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, sectionErrorMessage: null);
    _lazyLoad(tab);
  }

  Future<void> refreshCurrentTab() async {
    switch (state.selectedTab) {
      case AdminDriverDetailsTab.profile:
        await loadProfile(refreshing: true);
        break;
      case AdminDriverDetailsTab.documents:
        await loadDocuments();
        break;
      case AdminDriverDetailsTab.users:
        await loadUsers();
        break;
    }
  }

  Future<void> loadProfile({bool refreshing = false}) async {
    state = state.copyWith(
      isLoadingDriver: !state.hasDriver && !refreshing,
      isRefreshingDriver: state.hasDriver || refreshing,
      errorMessage: null,
      sectionErrorMessage: null,
    );

    try {
      final driver = await _service.getDriverById(_driverId);
      _loadedTabs.add(AdminDriverDetailsTab.profile);
      state = state.copyWith(
        driver: driver,
        isLoadingDriver: false,
        isRefreshingDriver: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDriver: false,
        isRefreshingDriver: false,
        errorMessage: state.driver == null ? _toErrorMessage(error) : null,
        sectionErrorMessage:
            state.driver == null ? null : _toErrorMessage(error),
      );
    }
  }

  Future<bool> updateProfile(AdminDriverUpdateRequest request) async {
    state = state.copyWith(isSavingProfile: true, sectionErrorMessage: null);
    try {
      final driver = await _service.updateDriver(
        id: _driverId,
        request: request,
      );
      state = state.copyWith(driver: driver, isSavingProfile: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingProfile: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateStatus(bool isActive) async {
    state = state.copyWith(isUpdatingStatus: true, sectionErrorMessage: null);
    try {
      await _service.updateDriverStatus(id: _driverId, isActive: isActive);
      await loadProfile(refreshing: true);
      state = state.copyWith(isUpdatingStatus: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingStatus: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    state = state.copyWith(isUpdatingPassword: true, sectionErrorMessage: null);
    try {
      await _service.updateDriverPassword(id: _driverId, password: password);
      await loadProfile(refreshing: true);
      state = state.copyWith(isUpdatingPassword: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingPassword: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteDriver() async {
    state = state.copyWith(isDeletingDriver: true, sectionErrorMessage: null);
    try {
      await _service.deleteDriver(_driverId);
      state = state.copyWith(isDeletingDriver: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isDeletingDriver: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoadingDocuments: true, sectionErrorMessage: null);
    try {
      final documents = await _service.getDriverDocuments(_driverId);
      final documentTypes = await _service.getDriverDocumentTypes();
      _loadedTabs.add(AdminDriverDetailsTab.documents);
      state = state.copyWith(
        documents: documents,
        documentTypes: documentTypes,
        isLoadingDocuments: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDocuments: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> uploadDocument(AdminDriverDocumentUpsertRequest request) async {
    state = state.copyWith(
      isUploadingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.uploadDriverDocument(request);
      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUploadingDocument: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateDocument({
    required String docId,
    required AdminDriverDocumentUpsertRequest request,
  }) async {
    state = state.copyWith(
      isUploadingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateDriverDocument(docId: docId, request: request);
      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      state = state.copyWith(
        isUploadingDocument: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = state.copyWith(isDeletingDocument: true, sectionErrorMessage: null);
    try {
      await _service.deleteDriverDocument(docId);
      state = state.copyWith(isDeletingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      state = state.copyWith(
        isDeletingDocument: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoadingUsers: true, sectionErrorMessage: null);
    try {
      final linkedUsers = await _service.getLinkedUsers(_driverId);
      final unlinkedUsers = await _service.getUnlinkedUsers(_driverId);
      _loadedTabs.add(AdminDriverDetailsTab.users);
      state = state.copyWith(
        linkedUsers: linkedUsers,
        unlinkedUsers: unlinkedUsers,
        isLoadingUsers: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingUsers: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<bool> assignUser(String userId) async {
    state = state.copyWith(isAssigningUser: true, sectionErrorMessage: null);
    try {
      await _service.assignUserToDriver(driverId: _driverId, userId: userId);
      state = state.copyWith(isAssigningUser: false);
      await loadUsers();
      return true;
    } catch (error) {
      state = state.copyWith(
        isAssigningUser: false,
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> unassignUser(String userId) async {
    final nextIds = <String>{...state.unassigningUserIds, userId};
    state = state.copyWith(
      unassigningUserIds: nextIds,
      sectionErrorMessage: null,
    );
    try {
      await _service.unassignUserFromDriver(
        driverId: _driverId,
        userId: userId,
      );
      state = state.copyWith(
        unassigningUserIds:
            state.unassigningUserIds.where((id) => id != userId).toSet(),
      );
      await loadUsers();
      return true;
    } catch (error) {
      state = state.copyWith(
        unassigningUserIds:
            state.unassigningUserIds.where((id) => id != userId).toSet(),
        sectionErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  void _lazyLoad(AdminDriverDetailsTab tab) {
    if (_loadedTabs.contains(tab)) return;
    switch (tab) {
      case AdminDriverDetailsTab.profile:
        if (!state.isLoadingDriver) {
          unawaited(loadProfile());
        }
        break;
      case AdminDriverDetailsTab.documents:
        if (!state.isLoadingDocuments) {
          unawaited(loadDocuments());
        }
        break;
      case AdminDriverDetailsTab.users:
        if (!state.isLoadingUsers) {
          unawaited(loadUsers());
        }
        break;
    }
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      final message = _extractResponseMessage(error.response?.data);
      if (message != null) {
        return message;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }
      final fallback = error.message?.trim();
      if (fallback != null && fallback.isNotEmpty) return fallback;
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
      }
      final nested = data['data'];
      if (!identical(nested, data)) {
        return _extractResponseMessage(nested);
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
