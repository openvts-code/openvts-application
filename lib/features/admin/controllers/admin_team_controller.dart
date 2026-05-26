import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../models/admin_team_model.dart';
import '../models/admin_team_state.dart';
import '../services/admin_team_service.dart';

class AdminTeamController extends StateNotifier<AdminTeamState> {
  AdminTeamController({required AdminTeamService service})
      : _service = service,
        super(const AdminTeamState.initial());

  final AdminTeamService _service;

  Future<void> load() async {
    await _fetchTeams(
      refreshKey: state.refreshKey == 0 ? null : state.refreshKey.toString(),
      refreshing: state.hasTeams,
    );
  }

  Future<void> refresh() async {
    final nextRefreshKey = state.refreshKey + 1;
    state = state.copyWith(refreshKey: nextRefreshKey);
    await _fetchTeams(refreshKey: nextRefreshKey.toString(), refreshing: true);
  }

  void setSearchQuery(String value) {
    state = _withFilteredTeams(
      state.copyWith(searchQuery: value, currentPage: 1, errorMessage: null),
    );
  }

  void setStatusFilter(AdminTeamStatusFilter value) {
    state = _withFilteredTeams(
      state.copyWith(statusFilter: value, currentPage: 1, errorMessage: null),
    );
  }

  void setSortOption(AdminTeamSortOption value) {
    state = _withFilteredTeams(
      state.copyWith(sortOption: value, currentPage: 1, errorMessage: null),
    );
  }

  void setRecordsPerPage(int value) {
    state = state.copyWith(recordsPerPage: value, currentPage: 1);
  }

  void goToPage(int value) {
    state = state.copyWith(currentPage: value);
  }

  void clearFilters() {
    state = _withFilteredTeams(
      state.copyWith(
        searchQuery: '',
        statusFilter: AdminTeamStatusFilter.all,
        sortOption: AdminTeamSortOption.newest,
        currentPage: 1,
        errorMessage: null,
      ),
    );
  }

  Future<bool> createTeam(AdminCreateTeamRequest request) async {
    if (state.isCreating) {
      return false;
    }

    state = state.copyWith(
      isCreating: true,
      createErrorMessage: null,
      errorMessage: null,
    );

    try {
      await _service.createTeam(request);
      if (!mounted) {
        return false;
      }

      state = state.copyWith(isCreating: false, createErrorMessage: null);
      await refresh();
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isCreating: false,
        createErrorMessage: _toErrorMessage(error),
      );
      return false;
    }
  }

  Future<List<AdminTeamMobilePrefixOption>> getMobilePrefixes() {
    return _service.getMobilePrefixes();
  }

  Future<void> _fetchTeams({
    String? refreshKey,
    required bool refreshing,
  }) async {
    final hasExistingTeams = state.hasTeams;
    state = state.copyWith(
      isLoading: !hasExistingTeams && !refreshing,
      isRefreshing: hasExistingTeams || refreshing,
      errorMessage: null,
    );

    try {
      final teams = await _service.getTeams(refreshKey: refreshKey);
      if (!mounted) {
        return;
      }

      state = _withFilteredTeams(
        state.copyWith(
          teams: teams,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  AdminTeamState _withFilteredTeams(AdminTeamState nextState) {
    return nextState.copyWith(filteredTeams: _filterTeams(nextState));
  }

  List<AdminTeamListItem> _filterTeams(AdminTeamState nextState) {
    final filtered = nextState.teams.where((team) {
      final matchesSearch = team.matchesQuery(nextState.searchQuery);
      final matchesStatus = switch (nextState.statusFilter) {
        AdminTeamStatusFilter.all => true,
        AdminTeamStatusFilter.active => team.isActive,
        AdminTeamStatusFilter.inactive => !team.isActive,
      };

      return matchesSearch && matchesStatus;
    }).toList(growable: false);

    if (filtered.length < 2) {
      return filtered;
    }

    switch (nextState.sortOption) {
      case AdminTeamSortOption.newest:
        filtered.sort((left, right) {
          final leftDate = left.createdAt;
          final rightDate = right.createdAt;
          if (leftDate == null && rightDate == null) {
            return left.teamName.toLowerCase().compareTo(
                  right.teamName.toLowerCase(),
                );
          }
          if (leftDate == null) return 1;
          if (rightDate == null) return -1;
          return rightDate.compareTo(leftDate);
        });
      case AdminTeamSortOption.nameAsc:
        filtered.sort((left, right) {
          return left.teamName.toLowerCase().compareTo(
                right.teamName.toLowerCase(),
              );
        });
      case AdminTeamSortOption.activeFirst:
        filtered.sort((left, right) {
          final activeCompare =
              (right.isActive ? 1 : 0).compareTo(left.isActive ? 1 : 0);
          if (activeCompare != 0) return activeCompare;
          return left.teamName.toLowerCase().compareTo(
                right.teamName.toLowerCase(),
              );
        });
    }

    return filtered;
  }

  String _toErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
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
