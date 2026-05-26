import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_notification_settings_model.dart';
import '../models/user_notification_settings_state.dart';
import '../services/user_notification_settings_service.dart';

class UserNotificationSettingsController
    extends StateNotifier<UserNotificationSettingsState> {
  UserNotificationSettingsController({
    required UserNotificationSettingsService service,
  })  : _service = service,
        super(const UserNotificationSettingsState.initial());

  final UserNotificationSettingsService _service;

  Future<void> load() async {
    if (state.isLoading || state.isRefreshing) {
      return;
    }

    await _loadInternal(refresh: false);
  }

  Future<void> refresh({bool discardUnsavedChanges = false}) async {
    if (state.isLoading || state.isRefreshing) {
      return;
    }

    if (state.isDirty && !discardUnsavedChanges) {
      state = state.copyWith(
        errorMessage:
            'You have unsaved changes. Save or reset before refreshing notification settings.',
      );
      return;
    }

    if (discardUnsavedChanges && state.preferences != null) {
      state = state.copyWith(
        draftPreferences: state.preferences,
        errorMessage: null,
      );
    }

    final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(refreshKey: refreshKey);
    await _loadInternal(refresh: true, refreshKey: refreshKey);
  }

  Future<void> save() async {
    if (state.isSaving) {
      return;
    }

    final draft = state.draftPreferences;
    if (draft == null || !state.isDirty) {
      return;
    }

    final validationError = _validateOverspeed(draft);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    final savingDraft = draft;
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
    );

    try {
      final saved = _normalizePreferences(
        await _service.savePreferences(savingDraft),
      );
      if (!mounted) {
        return;
      }

      final didChangeDuringSave = state.draftPreferences != savingDraft;
      state = state.copyWith(
        preferences: saved,
        draftPreferences:
            didChangeDuringSave ? (state.draftPreferences ?? saved) : saved,
        isSaving: false,
        errorMessage: null,
        lastSavedAt: DateTime.now(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: _toErrorMessage(error),
      );
    }
  }

  void reset() {
    final saved = state.preferences;
    if (saved == null) {
      return;
    }

    state = state.copyWith(
      draftPreferences: saved,
      errorMessage: null,
    );
  }

  void setSelectedTab(UserNotificationGroup group) {
    if (state.selectedTab == group) {
      return;
    }

    state = state.copyWith(selectedTab: group);
  }

  void updateChannel(
    UserNotificationGroup group,
    UserNotificationChannel channel,
    bool value,
  ) {
    _updateDraft((draft) {
      return draft.copyWith(
        channels: draft.channels.updateChannel(group, channel, value),
      );
    });
  }

  void updateBasicToggle(
    int vehicleId, {
    bool? ignitionEnabled,
    bool? alarmEnabled,
  }) {
    if (ignitionEnabled == null && alarmEnabled == null) {
      return;
    }

    _updateDraft((draft) {
      final rows = List<UserBasicNotificationRow>.from(draft.basic);
      final index = rows.indexWhere((item) => item.vehicleId == vehicleId);
      final current = index >= 0
          ? rows[index]
          : UserBasicNotificationRow(vehicleId: vehicleId);

      final updated = current.copyWith(
        ignitionEnabled: ignitionEnabled ?? current.ignitionEnabled,
        alarmEnabled: alarmEnabled ?? current.alarmEnabled,
      );

      if (index >= 0) {
        rows[index] = updated;
      } else {
        rows.add(updated);
      }

      return draft.copyWith(basic: rows);
    });
  }

  void updateOverspeedEnabled(int vehicleId, bool value) {
    _updateDraft((draft) {
      final rows = List<UserOverspeedNotificationRow>.from(draft.overspeed);
      final index = rows.indexWhere((item) => item.vehicleId == vehicleId);
      final current = index >= 0
          ? rows[index]
          : UserOverspeedNotificationRow(vehicleId: vehicleId);

      final updated = current.copyWith(enabled: value);
      if (index >= 0) {
        rows[index] = updated;
      } else {
        rows.add(updated);
      }

      return draft.copyWith(overspeed: rows);
    });
  }

  void updateOverspeedLimit(int vehicleId, int? speedLimitKph) {
    final normalizedLimit =
      speedLimitKph != null && speedLimitKph < 0 ? null : speedLimitKph;

    _updateDraft((draft) {
      final rows = List<UserOverspeedNotificationRow>.from(draft.overspeed);
      final index = rows.indexWhere((item) => item.vehicleId == vehicleId);
      final current = index >= 0
          ? rows[index]
          : UserOverspeedNotificationRow(vehicleId: vehicleId);

      final updated = current.copyWith(speedLimitKph: normalizedLimit);
      if (index >= 0) {
        rows[index] = updated;
      } else {
        rows.add(updated);
      }

      return draft.copyWith(overspeed: rows);
    });
  }

  void updateGeofenceToggle(int vehicleId, int geofenceId, bool value) {
    _updateDraft((draft) {
      final rows = List<UserGeofenceMatrixEntry>.from(draft.geofenceMatrix);
      final index = rows.indexWhere(
        (item) => item.vehicleId == vehicleId && item.geofenceId == geofenceId,
      );

      if (index >= 0) {
        rows[index] = rows[index].copyWith(enabled: value);
      } else {
        rows.add(
          UserGeofenceMatrixEntry(
            vehicleId: vehicleId,
            geofenceId: geofenceId,
            enabled: value,
          ),
        );
      }

      return draft.copyWith(geofenceMatrix: rows);
    });
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(errorMessage: null);
  }

  Future<void> _loadInternal({
    required bool refresh,
    String? refreshKey,
  }) async {
    final showFullLoader = !refresh && !state.hasData;

    state = state.copyWith(
      isLoading: showFullLoader,
      isRefreshing: refresh,
      errorMessage: null,
    );

    try {
      final result = _normalizePreferences(
        await _service.fetchPreferences(refreshKey: refreshKey),
      );
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        preferences: result,
        draftPreferences: result,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
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

  void _updateDraft(
    UserNotificationPreferences Function(UserNotificationPreferences draft)
        update,
  ) {
    final current = state.draftPreferences;
    if (current == null) {
      return;
    }

    state = state.copyWith(
      draftPreferences: _normalizePreferences(update(current)),
      errorMessage: null,
    );
  }

  UserNotificationPreferences _normalizePreferences(
    UserNotificationPreferences preferences,
  ) {
    final vehiclesById = <int, UserNotificationVehicle>{
      for (final vehicle in preferences.vehicles)
        if (vehicle.id > 0) vehicle.id: vehicle,
    };
    final geofencesById = <int, UserNotificationGeofence>{
      for (final geofence in preferences.geofences)
        if (geofence.id > 0) geofence.id: geofence,
    };

    final vehicles = vehiclesById.values.toList(growable: false);
    final geofences = geofencesById.values.toList(growable: false);
    final vehicleIds = vehiclesById.keys.toSet();
    final geofenceIds = geofencesById.keys.toSet();

    final basicByVehicle = <int, UserBasicNotificationRow>{};
    for (final item in preferences.basic) {
      if (item.vehicleId <= 0) {
        continue;
      }

      if (vehicleIds.isNotEmpty && !vehicleIds.contains(item.vehicleId)) {
        continue;
      }

      basicByVehicle[item.vehicleId] = item;
    }

    final overspeedByVehicle = <int, UserOverspeedNotificationRow>{};
    for (final item in preferences.overspeed) {
      if (item.vehicleId <= 0) {
        continue;
      }

      if (vehicleIds.isNotEmpty && !vehicleIds.contains(item.vehicleId)) {
        continue;
      }

      overspeedByVehicle[item.vehicleId] = item;
    }

    final geofenceMatrixByKey = <String, UserGeofenceMatrixEntry>{};
    for (final item in preferences.geofenceMatrix) {
      if (item.vehicleId <= 0 || item.geofenceId <= 0) {
        continue;
      }

      if (vehicleIds.isNotEmpty && !vehicleIds.contains(item.vehicleId)) {
        continue;
      }

      if (geofenceIds.isNotEmpty && !geofenceIds.contains(item.geofenceId)) {
        continue;
      }

      geofenceMatrixByKey['${item.vehicleId}:${item.geofenceId}'] = item;
    }

    final normalizedBasic = vehicles.isEmpty
        ? basicByVehicle.values.toList(growable: false)
        : vehicles
            .map(
              (vehicle) =>
                  basicByVehicle[vehicle.id] ??
                  UserBasicNotificationRow(vehicleId: vehicle.id),
            )
            .toList(growable: false);

    final normalizedOverspeed = vehicles.isEmpty
        ? overspeedByVehicle.values.toList(growable: false)
        : vehicles
            .map(
              (vehicle) =>
                  overspeedByVehicle[vehicle.id] ??
                  UserOverspeedNotificationRow(vehicleId: vehicle.id),
            )
            .toList(growable: false);

    final geofenceOrder = <int, int>{
      for (var index = 0; index < geofences.length; index += 1)
        geofences[index].id: index,
    };
    final vehicleOrder = <int, int>{
      for (var index = 0; index < vehicles.length; index += 1)
        vehicles[index].id: index,
    };

    final normalizedMatrix = geofenceMatrixByKey.values.toList(growable: true)
      ..sort((left, right) {
        final leftVehicle = vehicleOrder[left.vehicleId] ?? left.vehicleId;
        final rightVehicle = vehicleOrder[right.vehicleId] ?? right.vehicleId;
        final byVehicle = leftVehicle.compareTo(rightVehicle);
        if (byVehicle != 0) {
          return byVehicle;
        }

        final leftGeofence = geofenceOrder[left.geofenceId] ?? left.geofenceId;
        final rightGeofence =
            geofenceOrder[right.geofenceId] ?? right.geofenceId;
        return leftGeofence.compareTo(rightGeofence);
      });

    return preferences.copyWith(
      vehicles: vehicles,
      geofences: geofences,
      basic: normalizedBasic,
      overspeed: normalizedOverspeed,
      geofenceMatrix: normalizedMatrix,
    );
  }

  String? _validateOverspeed(UserNotificationPreferences preferences) {
    for (final row in preferences.overspeed) {
      if (!row.enabled) {
        continue;
      }

      final limit = row.speedLimitKph;
      if (limit == null || limit < 1) {
        return 'Speed limit must be at least 1 km/h for '
            '${_vehicleLabel(preferences, row.vehicleId)}.';
      }
    }

    return null;
  }

  String _vehicleLabel(UserNotificationPreferences preferences, int vehicleId) {
    for (final vehicle in preferences.vehicles) {
      if (vehicle.id != vehicleId) {
        continue;
      }

      final name = vehicle.name.trim();
      if (name.isNotEmpty) {
        return name;
      }

      final plate = vehicle.plateNumber.trim();
      if (plate.isNotEmpty) {
        return plate;
      }
      break;
    }

    return 'vehicle #$vehicleId';
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

    return raw.isEmpty ? 'Unable to load notification settings.' : raw;
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
