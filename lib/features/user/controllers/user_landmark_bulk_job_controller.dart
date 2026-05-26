import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_landmark_model.dart';
import '../models/user_landmark_state.dart';
import '../services/user_landmark_service.dart';

/// Owns the lifecycle of a single landmark bulk-import job.
///
/// Creates the job through the service, then polls real status until the
/// server reports a terminal state. Polling cadence is bounded so the job
/// stays responsive without hammering the API.
class UserLandmarkBulkJobController
    extends StateNotifier<UserLandmarkBulkJobState> {
  UserLandmarkBulkJobController({required UserLandmarkService service})
      : _service = service,
        super(const UserLandmarkBulkJobState.initial());

  final UserLandmarkService _service;
  Timer? _pollTimer;

  static const Duration _pollInterval = Duration(milliseconds: 1500);
  static const Duration _pollIntervalSlow = Duration(seconds: 3);
  static const int _slowAfterPolls = 20;

  /// Starts a new job. Resolves once the job reaches a terminal status or
  /// throws if the initial create call fails.
  Future<UserLandmarkBulkJob> start(
    CreateUserLandmarkBulkJobRequest request,
  ) async {
    _cancelPolling();
    state = state.copyWith(
      job: null,
      isUploading: true,
      isLoading: false,
      errorMessage: null,
    );
    try {
      final created = await _service.createBulkJob(request);
      state = state.copyWith(
        job: created,
        isUploading: false,
        isLoading: !created.isTerminal,
      );
      if (created.isTerminal) return created;
      return await _pollUntilTerminal(created.id);
    } catch (error) {
      state = state.copyWith(
        isUploading: false,
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<UserLandmarkBulkJob> _pollUntilTerminal(String id) {
    final completer = Completer<UserLandmarkBulkJob>();
    var pollCount = 0;

    void scheduleNext() {
      final interval =
          pollCount >= _slowAfterPolls ? _pollIntervalSlow : _pollInterval;
      _pollTimer = Timer(interval, () async {
        if (!mounted) {
          if (!completer.isCompleted) {
            completer.completeError(StateError('Controller disposed'));
          }
          return;
        }
        pollCount++;
        try {
          final next = await _service.fetchBulkJob(id);
          if (!mounted) return;
          state = state.copyWith(
            job: next,
            isLoading: !next.isTerminal,
            errorMessage: null,
          );
          if (next.isTerminal) {
            if (!completer.isCompleted) completer.complete(next);
            return;
          }
          scheduleNext();
        } catch (error) {
          if (!mounted) return;
          state = state.copyWith(
            isLoading: false,
            errorMessage: error.toString(),
          );
          if (!completer.isCompleted) completer.completeError(error);
        }
      });
    }

    scheduleNext();
    return completer.future;
  }

  /// Returns the relative path of the failed-rows CSV for this job, or null
  /// when no failed rows exist.
  Future<String?> failedCsvPath() async {
    final job = state.job;
    if (job == null || job.failed <= 0) return null;
    return _service.failedCsvUrl(job.id);
  }

  void reset() {
    _cancelPolling();
    state = const UserLandmarkBulkJobState.initial();
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _cancelPolling();
    super.dispose();
  }
}
