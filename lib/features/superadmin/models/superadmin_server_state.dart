import 'superadmin_server_model.dart';

class SuperadminServerState {
  const SuperadminServerState({
    required this.overview,
    required this.activeJob,
    required this.pendingActionKey,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.errorMessage,
  });

  const SuperadminServerState.initial()
      : overview = null,
        activeJob = null,
        pendingActionKey = null,
        isInitialLoading = true,
        isRefreshing = false,
        errorMessage = null;

  static const _unset = Object();

  final SuperadminServerOverview? overview;
  final SuperadminServerJob? activeJob;
  final String? pendingActionKey;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  bool get hasData => overview != null;

  bool isSubmitting(String componentId, String action) {
    return pendingActionKey == _actionKey(componentId, action);
  }

  bool isBusyComponent(String componentId) {
    final job = activeJob;
    if (job == null || job.isTerminal) {
      return false;
    }
    return job.componentId == componentId;
  }

  SuperadminServerState copyWith({
    Object? overview = _unset,
    Object? activeJob = _unset,
    Object? pendingActionKey = _unset,
    bool? isInitialLoading,
    bool? isRefreshing,
    Object? errorMessage = _unset,
  }) {
    return SuperadminServerState(
      overview: identical(overview, _unset)
          ? this.overview
          : overview as SuperadminServerOverview?,
      activeJob: identical(activeJob, _unset)
          ? this.activeJob
          : activeJob as SuperadminServerJob?,
      pendingActionKey: identical(pendingActionKey, _unset)
          ? this.pendingActionKey
          : pendingActionKey as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

String _actionKey(String componentId, String action) {
  return '${componentId.trim().toLowerCase()}:${action.trim().toLowerCase()}';
}
