import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_share_track_link_model.dart';
import '../models/user_share_track_link_state.dart';
import '../services/user_share_track_link_service.dart';

class UserShareTrackLinkController
    extends StateNotifier<UserShareTrackLinkState> {
  UserShareTrackLinkController({required UserShareTrackLinkService service})
      : _service = service,
        super(const UserShareTrackLinkState.initial());

  final UserShareTrackLinkService _service;
  int _requestSerial = 0;

  Future<void> load() {
    return _loadFirstPage(refreshKey: state.refreshKey);
  }

  Future<void> refresh() {
    final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(refreshKey: refreshKey);
    return _loadFirstPage(refreshKey: refreshKey, forceRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final serial = _requestSerial;
    final nextPage = state.page + 1;
    final query = state.searchQuery;
    final refreshKey = state.refreshKey;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final page = await _service.getShareTrackLinks(
        page: nextPage,
        limit: state.limit,
        search: query,
        refreshKey: refreshKey,
      );
      if (!mounted || serial != _requestSerial) return;

      state = state.copyWith(
        links: _mergeById(state.links, page.items),
        page: page.page,
        limit: page.limit,
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
        errorMessage: null,
      );
    } catch (error) {
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> setSearchQuery(String query) async {
    final normalized = query.trim();
    if (normalized == state.searchQuery) {
      return;
    }

    state = state.copyWith(
      searchQuery: normalized,
      page: 1,
      hasMore: false,
      errorMessage: null,
    );
    await _loadFirstPage(refreshKey: state.refreshKey);
  }

  Future<String?> createLink(UserCreateShareTrackLinkRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    try {
      final result = await _service.createShareTrackLink(request);
      if (!mounted) return result.message;
      await refresh();
      if (!mounted) return result.message;
      state = state.copyWith(isCreating: false);
      return result.message;
    } catch (error) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isCreating: false,
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<String?> updateLink(
    String id,
    UserUpdateShareTrackLinkRequest request,
  ) async {
    final linkId = id.trim();
    if (linkId.isEmpty) return null;

    state = state.copyWith(
      updatingIds: _addId(state.updatingIds, linkId),
      errorMessage: null,
    );

    try {
      final result = await _service.updateShareTrackLink(
        id: linkId,
        request: request,
      );
      if (!mounted) return result.message;
      await refresh();
      if (!mounted) return result.message;
      state = state.copyWith(
        updatingIds: _removeId(state.updatingIds, linkId),
      );
      return result.message;
    } catch (error) {
      if (!mounted) rethrow;
      state = state.copyWith(
        updatingIds: _removeId(state.updatingIds, linkId),
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> deleteLink(UserShareTrackLink link) async {
    final linkId = link.endpointId.trim();
    if (linkId.isEmpty) return;

    state = state.copyWith(
      deletingIds: _addId(state.deletingIds, linkId),
      errorMessage: null,
    );

    try {
      await _service.deleteShareTrackLink(link);
      if (!mounted) return;
      await refresh();
      if (!mounted) return;
      state = state.copyWith(
        deletingIds: _removeId(state.deletingIds, linkId),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        deletingIds: _removeId(state.deletingIds, linkId),
        errorMessage: _toErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<UserShareTrackLink> getLinkDetails(String id) async {
    try {
      final link = await _service.getShareTrackLinkById(id);
      if (!mounted) return link;
      state = state.copyWith(
        links: _replaceById(state.links, link),
        errorMessage: null,
      );
      return link;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(errorMessage: _toErrorMessage(error));
      }
      rethrow;
    }
  }

  Future<List<UserShareTrackVehicle>> getVehicles() async {
    try {
      return await _service.getVehicles();
    } catch (error) {
      if (mounted) {
        state = state.copyWith(errorMessage: _toErrorMessage(error));
      }
      rethrow;
    }
  }

  Future<void> _loadFirstPage({
    required String? refreshKey,
    bool forceRefresh = false,
  }) async {
    final serial = ++_requestSerial;
    final query = state.searchQuery;
    final shouldShowLoader = state.links.isEmpty && !forceRefresh;

    state = state.copyWith(
      isLoading: shouldShowLoader,
      isRefreshing: forceRefresh || state.links.isNotEmpty,
      isLoadingMore: false,
      errorMessage: null,
    );

    try {
      final page = await _service.getShareTrackLinks(
        page: 1,
        limit: state.limit,
        search: query,
        refreshKey: refreshKey,
      );
      if (!mounted || serial != _requestSerial) return;

      state = state.copyWith(
        links: page.items,
        page: page.page,
        limit: page.limit,
        total: page.total,
        hasMore: page.hasMore,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: null,
      );
    } catch (error) {
      if (!mounted || serial != _requestSerial) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  List<UserShareTrackLink> _mergeById(
    List<UserShareTrackLink> current,
    List<UserShareTrackLink> next,
  ) {
    final seen = <String>{};
    final merged = <UserShareTrackLink>[];
    for (final link in <UserShareTrackLink>[...current, ...next]) {
      if (seen.add(link.id)) {
        merged.add(link);
      }
    }
    return merged;
  }

  List<UserShareTrackLink> _replaceById(
    List<UserShareTrackLink> links,
    UserShareTrackLink replacement,
  ) {
    var didReplace = false;
    final updated = links.map((link) {
      if (link.id != replacement.id) return link;
      didReplace = true;
      return replacement;
    }).toList(growable: true);
    if (!didReplace) {
      updated.insert(0, replacement);
    }
    return updated;
  }

  Set<String> _addId(Set<String> ids, String id) {
    return <String>{...ids, id};
  }

  Set<String> _removeId(Set<String> ids, String id) {
    return <String>{...ids}..remove(id);
  }

  String _toErrorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) return responseMessage;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isEmpty ? 'Share track links could not be loaded.' : raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }
}
