import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../models/superadmin_server_model.dart';

class SuperadminServerService {
  SuperadminServerService(this._apiClient);

  final ApiClient _apiClient;

  Future<SuperadminServerOverview> getOverview() async {
    if (AppConfig.useMockData) {
      return SuperadminServerOverview.mock();
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.serverOverview,
      queryParameters: <String, dynamic>{
        'rk': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      parser: (json) => json,
    );

    return SuperadminServerOverview.fromJson(response.data);
  }

  Future<SuperadminServerJob> createAction({
    required String componentId,
    required String action,
  }) async {
    if (AppConfig.useMockData) {
      return SuperadminServerJob(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        componentId: componentId,
        componentName: serverComponentNameForId(componentId),
        action: action,
        status: SuperadminServerJobStatus.running,
        message:
            '${serverActionLabel(action)} requested for ${serverComponentNameForId(componentId)}',
        updatedAt: DateTime.now(),
        logLines: <String>[
          '${serverActionLabel(action)} action queued',
        ],
      );
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.serverActions,
      data: <String, dynamic>{
        'componentId': componentId,
        'action': action,
      },
      parser: (json) => json,
    );

    return SuperadminServerJob.fromJson(
      response.data,
      fallbackComponentId: componentId,
      fallbackComponentName: serverComponentNameForId(componentId),
      fallbackAction: action,
      fallbackMessage: response.message,
    );
  }

  Future<SuperadminServerJob> getJob(String jobId) async {
    if (AppConfig.useMockData) {
      return SuperadminServerJob(
        id: jobId,
        componentId: 'listener',
        componentName: 'Listener',
        action: 'restart',
        status: SuperadminServerJobStatus.success,
        message: 'Server action completed successfully',
        updatedAt: DateTime.now(),
        logLines: const <String>[
          'Server action completed successfully',
        ],
      );
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.serverJob(jobId),
      parser: (json) => json,
    );

    return SuperadminServerJob.fromJson(
      response.data,
      fallbackId: jobId,
      fallbackMessage: response.message,
    );
  }

  Stream<SuperadminServerJob> streamJob(String jobId) async* {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      yield SuperadminServerJob(
        id: jobId,
        componentId: 'listener',
        componentName: 'Listener',
        action: 'restart',
        status: SuperadminServerJobStatus.success,
        message: 'Mock stream completed',
        updatedAt: DateTime.now(),
        logLines: const <String>['Mock stream completed'],
      );
      return;
    }

    final response = await _apiClient.get<ResponseBody>(
      ApiEndpoints.superadmin.serverJobStream(jobId),
      options: Options(responseType: ResponseType.stream),
      parser: (json) => json as ResponseBody,
    );

    yield* _parseServerSentEvents(response.data.stream, jobId);
  }

  Stream<SuperadminServerJob> _parseServerSentEvents(
    Stream<List<int>> byteStream,
    String jobId,
  ) async* {
    String? eventName;
    var dataLines = <String>[];

    Future<SuperadminServerJob?> flush() async {
      if (dataLines.isEmpty) {
        eventName = null;
        dataLines = <String>[];
        return null;
      }

      final raw = dataLines.join('\n').trim();
      eventName = null;
      dataLines = <String>[];
      if (raw.isEmpty) {
        return null;
      }

      dynamic payload = raw;
      try {
        payload = jsonDecode(raw);
      } catch (_) {
        payload = raw;
      }

      final job = SuperadminServerJob.fromJson(
        payload,
        fallbackId: jobId,
        fallbackMessage: raw,
      );

      if (job.message.isEmpty && eventName != null && eventName!.isNotEmpty) {
        return job.copyWith(message: eventName!);
      }

      return job;
    }

    await for (final line
        in byteStream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) {
        final job = await flush();
        if (job != null) {
          yield job;
        }
        continue;
      }

      if (line.startsWith('event:')) {
        eventName = line.substring('event:'.length).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trimLeft());
      }
    }

    final job = await flush();
    if (job != null) {
      yield job;
    }
  }
}
