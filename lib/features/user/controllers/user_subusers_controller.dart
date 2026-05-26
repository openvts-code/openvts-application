import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_subuser_model.dart';
import '../models/user_subusers_state.dart';
import '../services/user_subuser_service.dart';

class UserSubUsersController extends StateNotifier<UserSubUsersState> {
  UserSubUsersController({required UserSubUserService service})
      : _service = service,
        super(const UserSubUsersState.initial());

  final UserSubUserService _service;

  Timer? _searchDebounce;
  int _requestSerial = 0;

  Future<void> loadInitial() async {
    state = state.copyWith(
      page: 1,
      refreshKey: _newRefreshKey(),
      errorMessage: null,
    );

    await _loadSubUsers(
      targetPage: 1,
      append: false,
      isRefresh: false,
    );
  }

  Future<void> loadSubUsers() async {
    await _loadSubUsers(
      targetPage: 1,
      append: false,
      isRefresh: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      page: 1,
      refreshKey: _newRefreshKey(),
      errorMessage: null,
    );

    await _loadSubUsers(
      targetPage: 1,
      append: false,
      isRefresh: true,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoading ||
        state.isRefreshing ||
        state.isLoadingMore) {
      return;
    }

    await _loadSubUsers(
      targetPage: state.page + 1,
      append: true,
      isRefresh: false,
    );
  }

  Future<UserSubUser?> createSubUser(CreateUserSubUserRequest request) async {
    if (state.isCreating) {
      return null;
    }

    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
    );

    try {
      final created = await _service.createSubUser(request);
      if (!mounted) {
        return created;
      }

      state = state.copyWith(
        subUsers: _upsertSubUser(state.subUsers, created),
        isCreating: false,
        total: state.total + 1,
      );

      await refresh();
      return created;
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

  Future<bool> toggleStatus(String subUserId) async {
    final id = subUserId.trim();
    if (id.isEmpty || state.togglingIds.contains(id)) {
      return false;
    }

    final index = state.subUsers.indexWhere((item) => item.id == id);
    if (index < 0) {
      return false;
    }

    final previousUsers = state.subUsers;
    final previous = previousUsers[index];
    final optimistic = previous.copyWith(
      isActive: !previous.isActive,
      status: previous.isActive ? 'inactive' : 'active',
    );

    final optimisticUsers = previousUsers.toList(growable: true);
    optimisticUsers[index] = optimistic;

    final nextToggling = <String>{...state.togglingIds, id};
    state = state.copyWith(
      subUsers: optimisticUsers,
      togglingIds: nextToggling,
      errorMessage: null,
    );

    try {
      final updated = await _service.updateSubUser(
        id,
        UpdateUserSubUserRequest(isActive: optimistic.isActive),
      );

      if (!mounted) {
        return true;
      }

      final replaced = _upsertSubUser(state.subUsers, updated);
      final afterToggle = <String>{...state.togglingIds}..remove(id);
      state = state.copyWith(
        subUsers: replaced,
        togglingIds: afterToggle,
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      final afterToggle = <String>{...state.togglingIds}..remove(id);
      state = state.copyWith(
        subUsers: previousUsers,
        togglingIds: afterToggle,
        errorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query.trim(),
      page: 1,
      errorMessage: null,
    );

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }

      unawaited(loadSubUsers());
    });
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _loadSubUsers({
    required int targetPage,
    required bool append,
    required bool isRefresh,
  }) async {
    final serial = ++_requestSerial;
    final page = targetPage < 1 ? 1 : targetPage;

    state = state.copyWith(
      isLoading: !append && !isRefresh,
      isRefreshing: isRefresh,
      isLoadingMore: append,
      errorMessage: null,
    );

    try {
      final response = await _service.fetchSubUsers(
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery,
        page: page,
        limit: state.limit,
        refreshKey: _currentRefreshKey,
      );

      if (!mounted || serial != _requestSerial) {
        return;
      }

      final merged = append
          ? _mergeSubUsers(state.subUsers, response.items)
          : response.items;

      final nextPage = response.page <= 0 ? page : response.page;
      final nextLimit = response.limit <= 0 ? state.limit : response.limit;
      final nextTotal =
          response.total < merged.length ? merged.length : response.total;

      state = state.copyWith(
        subUsers: merged,
        page: nextPage,
        limit: nextLimit,
        total: nextTotal,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
      );
    } catch (error) {
      if (!mounted || serial != _requestSerial) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  List<UserSubUser> _mergeSubUsers(
    List<UserSubUser> current,
    List<UserSubUser> incoming,
  ) {
    final merged = <String, UserSubUser>{
      for (final item in current) item.id: item,
    };

    for (final item in incoming) {
      final id = item.id.trim();
      if (id.isEmpty) {
        continue;
      }
      merged[id] = item;
    }

    return merged.values.toList(growable: false);
  }

  List<UserSubUser> _upsertSubUser(
    List<UserSubUser> current,
    UserSubUser incoming,
  ) {
    final id = incoming.id.trim();
    if (id.isEmpty) {
      return current;
    }

    var replaced = false;
    final next = current.map((item) {
      if (item.id != id) {
        return item;
      }
      replaced = true;
      return incoming;
    }).toList(growable: true);

    if (!replaced) {
      next.insert(0, incoming);
    }

    return next;
  }

  String get _currentRefreshKey {
    final normalized = state.refreshKey?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    final next = _newRefreshKey();
    state = state.copyWith(refreshKey: next);
    return next;
  }

  String _newRefreshKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
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

    return raw.isEmpty ? 'Sub users could not be loaded.' : raw;
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
