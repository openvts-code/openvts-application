import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin_server_model.dart';
import '../models/superadmin_server_state.dart';
import '../services/superadmin_server_service.dart';

class SuperadminServerController extends StateNotifier<SuperadminServerState> {
  SuperadminServerController(this._service)
      : super(const SuperadminServerState.initial()) {
    load();
  }

  final SuperadminServerService _service;

  Timer? _jobPollTimer;
  StreamSubscription<SuperadminServerJob>? _jobStreamSubscription;
  bool _isPollingJob = false;

  Future<void> load({bool refresh = false}) async {
    final hasData = state.hasData;

    state = state.copyWith(
      isInitialLoading: !hasData,
      isRefreshing: hasData || refresh,
      errorMessage: null,
    );

    try {
      final overview = await _service.getOverview();
      state = state.copyWith(
        overview: overview,
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> runAction({
    required String componentId,
    required String action,
  }) async {
    if (state.pendingActionKey != null) {
      return;
    }

    final actionKey =
        '${componentId.trim().toLowerCase()}:${action.trim().toLowerCase()}';
    final component = state.overview?.componentById(componentId);

    state = state.copyWith(
      pendingActionKey: actionKey,
      errorMessage: null,
    );

    try {
      final createdJob = await _service.createAction(
        componentId: componentId,
        action: action,
      );
      final seededJob = createdJob.copyWith(
        componentId: createdJob.componentId.isNotEmpty
            ? createdJob.componentId
            : componentId,
        componentName: createdJob.componentName.isNotEmpty
            ? createdJob.componentName
            : (component?.name ?? serverComponentNameForId(componentId)),
        action: createdJob.action.isNotEmpty ? createdJob.action : action,
        status: createdJob.status == SuperadminServerJobStatus.unknown
            ? SuperadminServerJobStatus.queued
            : createdJob.status,
        updatedAt: createdJob.updatedAt ?? DateTime.now(),
      );

      state = state.copyWith(
        activeJob: seededJob,
        pendingActionKey: actionKey,
        errorMessage: null,
      );

      if (seededJob.id.isEmpty) {
        state = state.copyWith(pendingActionKey: null);
        await load(refresh: true);
        return;
      }

      _startJobMonitoring(seededJob.id, fallbackJob: seededJob);
    } catch (error) {
      state = state.copyWith(
        pendingActionKey: null,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  void _startJobMonitoring(
    String jobId, {
    required SuperadminServerJob fallbackJob,
  }) {
    _stopJobMonitoring();

    _jobStreamSubscription = _service.streamJob(jobId).listen(
      (job) => _applyJobUpdate(_decorateJob(job, fallbackJob)),
      onError: (_) {
        // Polling remains the reliable fallback.
      },
    );

    _jobPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_pollJob(jobId, fallbackJob)),
    );

    unawaited(_pollJob(jobId, fallbackJob));
  }

  Future<void> _pollJob(
    String jobId,
    SuperadminServerJob fallbackJob,
  ) async {
    if (_isPollingJob) {
      return;
    }

    _isPollingJob = true;
    try {
      final job = await _service.getJob(jobId);
      _applyJobUpdate(_decorateJob(job, fallbackJob));
    } catch (error) {
      state = state.copyWith(
        errorMessage: _toErrorMessage(error),
      );
    } finally {
      _isPollingJob = false;
    }
  }

  SuperadminServerJob _decorateJob(
    SuperadminServerJob job,
    SuperadminServerJob fallbackJob,
  ) {
    return job.copyWith(
      id: job.id.isNotEmpty ? job.id : fallbackJob.id,
      componentId: job.componentId.isNotEmpty
          ? job.componentId
          : fallbackJob.componentId,
      componentName: job.componentName.isNotEmpty
          ? job.componentName
          : fallbackJob.componentName,
      action: job.action.isNotEmpty ? job.action : fallbackJob.action,
      message: job.message.isNotEmpty ? job.message : fallbackJob.message,
      updatedAt: job.updatedAt ?? fallbackJob.updatedAt ?? DateTime.now(),
      logLines: job.logLines.isNotEmpty ? job.logLines : fallbackJob.logLines,
    );
  }

  void _applyJobUpdate(SuperadminServerJob nextJob) {
    final currentJob = state.activeJob;
    final merged = currentJob == null ? nextJob : currentJob.merge(nextJob);

    state = state.copyWith(
      activeJob: merged,
      pendingActionKey: merged.isTerminal ? null : state.pendingActionKey,
      errorMessage: null,
    );

    if (merged.isTerminal) {
      _stopJobMonitoring();
      unawaited(load(refresh: true));
    }
  }

  void _stopJobMonitoring() {
    _jobPollTimer?.cancel();
    _jobPollTimer = null;
    _jobStreamSubscription?.cancel();
    _jobStreamSubscription = null;
    _isPollingJob = false;
  }

  @override
  void dispose() {
    _stopJobMonitoring();
    super.dispose();
  }

  String _toErrorMessage(Object error) {
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
