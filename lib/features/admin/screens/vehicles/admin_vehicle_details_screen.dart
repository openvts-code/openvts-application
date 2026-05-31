import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_detail_tab_strip.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_status_chip.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_vehicle_model.dart';
import '../../models/admin_vehicle_state.dart';
import 'widgets/admin_vehicle_commands_tab.dart';
import 'widgets/admin_vehicle_config_tab.dart';
import 'widgets/admin_vehicle_details_tab.dart';
import 'widgets/admin_vehicle_documents_tab.dart';
import 'widgets/admin_vehicle_edit_sheet.dart';
import 'widgets/admin_vehicle_events_tab.dart';
import 'widgets/admin_vehicle_logs_tab.dart';
import 'widgets/admin_vehicle_sensors_tab.dart';
import 'widgets/admin_vehicle_users_tab.dart';

class AdminVehicleDetailsScreen extends ConsumerWidget {
  const AdminVehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  final String vehicleId;
  final AdminVehicleListItem? initialVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminVehicleDetailsControllerProvider(vehicleId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);
    final vehicle = state.vehicle;

    return OpenVtsPageScaffold(
      title: vehicle?.name.isNotEmpty == true
          ? vehicle!.name
          : (initialVehicle?.name.isNotEmpty == true
              ? initialVehicle!.name
              : 'Vehicle Details'),
      headerMode: OpenVtsPageHeaderMode.closeable,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.adminVehicles);
          }
        },
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: state.isLoadingVehicle ? null : controller.loadVehicle,
          icon: state.isLoadingVehicle
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        PopupMenuButton<_Action>(
          onSelected: (action) => _onAction(context, ref, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: _Action.edit, child: Text('Edit')),
            PopupMenuItem(
                value: _Action.toggleStatus,
                child: Text('Activate/Deactivate')),
            PopupMenuItem(value: _Action.delete, child: Text('Delete')),
          ],
        ),
      ],
      body: RefreshIndicator(
        onRefresh: controller.refreshCurrentTab,
        child: ListView(
          padding: const EdgeInsets.only(bottom: OpenVtsSpacing.lg),
          children: [
            if (state.errorMessage != null && vehicle == null)
              OpenVtsErrorView(
                message: state.errorMessage!,
                onRetry: controller.loadInitial,
              )
            else if (state.isLoadingVehicle && vehicle == null)
              const SizedBox(height: 240, child: OpenVtsLoader())
            else if (vehicle != null) ...[
              _SummaryCard(vehicle: vehicle),
              const SizedBox(height: OpenVtsSpacing.sm),
              _TabChips(
                selected: state.selectedTab,
                onSelect: controller.selectTab,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              if (state.sectionErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                  child: OpenVtsErrorView(message: state.sectionErrorMessage!),
                ),
              _TabBody(
                state: state,
                onEdit: () => _onAction(context, ref, _Action.edit),
                onToggleStatus: () =>
                    _onAction(context, ref, _Action.toggleStatus),
                onDelete: () => _onAction(context, ref, _Action.delete),
                onLoadUsers: controller.loadUsers,
                onLinkUser: controller.linkUser,
                onUnlinkUser: controller.unlinkUser,
                onLoadLogs: () => controller.loadLogs(),
                onLoadMoreLogs: controller.loadMoreLogs,
                onSetLogRange: ({from, to}) =>
                    controller.setLogRange(from: from, to: to),
                onLoadEvents: () => controller.loadEvents(),
                onLoadMoreEvents: controller.loadMoreEvents,
                onSetEventFilters: ({
                  DateTime? from,
                  DateTime? to,
                  String? source,
                  String? severity,
                }) =>
                    controller.setEventFilters(
                  from: from,
                  to: to,
                  source: source,
                  severity: severity,
                ),
                onLoadCommands: controller.loadCommands,
                onSendCommand: ({
                  required String command,
                  String? note,
                }) =>
                    controller.sendCommand(command: command, note: note),
                onPollCommandStatus: controller.getCommandStatus,
                onFetchCommandLog: controller.getCommandLog,
                onLoadSensors: ({search}) =>
                    controller.loadSensors(search: search),
                onCreateSensor: controller.createSensor,
                onUpdateSensor: (sensorId, request) => controller.updateSensor(
                    sensorId: sensorId, request: request),
                onDeleteSensor: controller.deleteSensor,
                onRunSensor: (request) =>
                    controller.runSensor(request: request),
                onLoadDocuments: controller.loadDocuments,
                onUploadDocument: controller.uploadDocument,
                onUpdateDocument: ({required docId, required request}) =>
                    controller.updateDocument(docId: docId, request: request),
                onDeleteDocument: controller.deleteDocument,
                onUpdateConfig: controller.updateConfig,
                apiBaseUrl: apiBaseUrl,
              ),
            ] else
              const OpenVtsEmptyState(
                title: 'Vehicle unavailable',
                message: 'Vehicle record is not available.',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, _Action action) async {
    switch (action) {
      case _Action.edit:
        await _openEditSheet(context, ref);
      case _Action.toggleStatus:
        await _toggleStatus(context, ref);
      case _Action.delete:
        await _deleteVehicle(context, ref);
    }
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref) async {
    final provider = adminVehicleDetailsControllerProvider(vehicleId);
    final state = ref.read(provider);
    final vehicle = state.vehicle;
    if (vehicle == null) return;

    await OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit Vehicle',
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.94,
      child: Consumer(
        builder: (_, innerRef, __) {
          final current = innerRef.watch(provider);
          return AdminVehicleEditSheet(
            vehicle: current.vehicle ?? vehicle,
            vehicleTypes: current.vehicleTypes,
            timezones: current.timezones,
            isSubmitting: current.isUpdatingVehicle,
            onSubmit: (request) async {
              await innerRef.read(provider.notifier).updateVehicle(request);
              final next = innerRef.read(provider);
              if (next.sectionErrorMessage == null && context.mounted) {
                Navigator.of(context).pop();
                ToastHelper.showSuccess('Vehicle updated.', context: context);
              } else if (context.mounted) {
                ToastHelper.showError(
                  next.sectionErrorMessage ?? 'Unable to update vehicle.',
                  context: context,
                );
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref) async {
    final provider = adminVehicleDetailsControllerProvider(vehicleId);
    final state = ref.read(provider);
    final vehicle = state.vehicle;
    if (vehicle == null) return;
    await ref.read(provider.notifier).updateVehicleStatus(!vehicle.isActive);
    final next = ref.read(provider);
    if (!context.mounted) return;
    if (next.sectionErrorMessage == null) {
      ToastHelper.showSuccess(
        vehicle.isActive ? 'Vehicle deactivated.' : 'Vehicle activated.',
        context: context,
      );
    } else {
      ToastHelper.showError(next.sectionErrorMessage!, context: context);
    }
  }

  Future<void> _deleteVehicle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete vehicle'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final detailsProvider = adminVehicleDetailsControllerProvider(vehicleId);
    await ref.read(detailsProvider.notifier).deleteVehicle();
    final next = ref.read(detailsProvider);
    if (!context.mounted) return;
    if (next.sectionErrorMessage == null) {
      final listProvider = adminVehiclesControllerProvider;
      await ref.read(listProvider.notifier).refresh();
      if (!context.mounted) return;
      ToastHelper.showSuccess('Vehicle deleted.', context: context);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.adminVehicles);
      }
    } else {
      ToastHelper.showError(next.sectionErrorMessage!, context: context);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.vehicle});

  final AdminVehicleDetails vehicle;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_filled_rounded, size: 28),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  vehicle.name.isEmpty ? 'Untitled Vehicle' : vehicle.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OpenVtsStatusChip(
                label: vehicle.isActive ? 'Active' : 'Inactive',
                type: vehicle.isActive
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.warning,
              ),
              if (vehicle.isLicenseBlocked) ...[
                const SizedBox(width: OpenVtsSpacing.xs),
                const OpenVtsStatusChip(
                  label: 'License Blocked',
                  type: OpenVtsStatusType.error,
                ),
              ],
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text('Plate: ${_safe(vehicle.plateNumber)}'),
          Text('VIN: ${_safe(vehicle.vin)}'),
          Text('IMEI: ${_safe(vehicle.imei)}'),
          Text('SIM: ${_safe(vehicle.simNumber)}'),
          Text('Vehicle Type: ${_safe(vehicle.vehicleType?.name ?? '')}'),
          Text('Primary User: ${_safe(vehicle.primaryUser?.name ?? '')}'),
        ],
      ),
    );
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value;
}

class _TabChips extends StatelessWidget {
  const _TabChips({required this.selected, required this.onSelect});

  final AdminVehicleDetailsTab selected;
  final ValueChanged<AdminVehicleDetailsTab> onSelect;

  static const Map<AdminVehicleDetailsTab, String> _labels = {
    AdminVehicleDetailsTab.details: 'Vehicle Details',
    AdminVehicleDetailsTab.users: 'Users',
    AdminVehicleDetailsTab.logs: 'Logs',
    AdminVehicleDetailsTab.commands: 'Commands',
    AdminVehicleDetailsTab.sensors: 'Sensors',
    AdminVehicleDetailsTab.documents: 'Documents',
    AdminVehicleDetailsTab.config: 'Config',
    AdminVehicleDetailsTab.events: 'Events',
  };

  @override
  Widget build(BuildContext context) {
    final tabs = AdminVehicleDetailsTab.values
        .map(
          (tab) => OpenVtsDetailTabOption<AdminVehicleDetailsTab>(
            value: tab,
            label: _labels[tab] ?? tab.name,
          ),
        )
        .toList(growable: false);

    return OpenVtsDetailTabStrip<AdminVehicleDetailsTab>(
      tabs: tabs,
      selected: selected,
      onChanged: onSelect,
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.state,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onLoadUsers,
    required this.onLinkUser,
    required this.onUnlinkUser,
    required this.onLoadLogs,
    required this.onLoadMoreLogs,
    required this.onSetLogRange,
    required this.onLoadEvents,
    required this.onLoadMoreEvents,
    required this.onSetEventFilters,
    required this.onLoadCommands,
    required this.onSendCommand,
    required this.onPollCommandStatus,
    required this.onFetchCommandLog,
    required this.onLoadSensors,
    required this.onCreateSensor,
    required this.onUpdateSensor,
    required this.onDeleteSensor,
    required this.onRunSensor,
    required this.onLoadDocuments,
    required this.onUploadDocument,
    required this.onUpdateDocument,
    required this.onDeleteDocument,
    required this.onUpdateConfig,
    required this.apiBaseUrl,
  });

  final AdminVehicleDetailsState state;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final Future<void> Function() onLoadUsers;
  final Future<void> Function(String userId) onLinkUser;
  final Future<void> Function(String userId) onUnlinkUser;
  final Future<void> Function() onLoadLogs;
  final Future<void> Function() onLoadMoreLogs;
  final Future<void> Function({DateTime? from, DateTime? to}) onSetLogRange;
  final Future<void> Function() onLoadEvents;
  final Future<void> Function() onLoadMoreEvents;
  final Future<void> Function({
    DateTime? from,
    DateTime? to,
    String? source,
    String? severity,
  }) onSetEventFilters;
  final Future<void> Function() onLoadCommands;
  final Future<void> Function({
    required String command,
    String? note,
  }) onSendCommand;
  final Future<AdminCommandStatus?> Function(String cmdId) onPollCommandStatus;
  final Future<AdminVehicleCommandItem?> Function(String cmdId)
      onFetchCommandLog;
  final Future<void> Function({String? search}) onLoadSensors;
  final Future<void> Function(AdminVehicleSensorUpsertRequest request)
      onCreateSensor;
  final Future<void> Function(
    String sensorId,
    AdminVehicleSensorUpsertRequest request,
  ) onUpdateSensor;
  final Future<void> Function(String sensorId) onDeleteSensor;
  final Future<void> Function(AdminVehicleSensorRunRequest request) onRunSensor;
  final Future<void> Function() onLoadDocuments;
  final Future<void> Function(AdminVehicleDocumentRequest request)
      onUploadDocument;
  final Future<void> Function({
    required String docId,
    required AdminVehicleDocumentRequest request,
  }) onUpdateDocument;
  final Future<void> Function(String docId) onDeleteDocument;
  final Future<void> Function(AdminVehicleConfigUpdateRequest request)
      onUpdateConfig;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    switch (state.selectedTab) {
      case AdminVehicleDetailsTab.details:
        final vehicle = state.vehicle;
        if (vehicle == null) {
          return const OpenVtsEmptyState(
            title: 'No details',
            message: 'Vehicle details are unavailable.',
          );
        }
        return AdminVehicleDetailsOverviewTab(
          vehicle: vehicle,
          isUpdatingStatus: state.isUpdatingStatus,
          isDeleting: state.isDeletingVehicle,
          onEdit: onEdit,
          onToggleStatus: onToggleStatus,
          onDelete: onDelete,
        );
      case AdminVehicleDetailsTab.users:
        return AdminVehicleUsersTab(
          isLoading: state.isLoadingUsers,
          isLinking: state.isLinkingUser,
          isUnlinking: state.isUnlinkingUser,
          linkedUsers: state.linkedUsers,
          availableUsers: state.availableUsers,
          onRefresh: onLoadUsers,
          onLinkUser: onLinkUser,
          onUnlinkUser: onUnlinkUser,
        );
      case AdminVehicleDetailsTab.logs:
        return AdminVehicleLogsTab(
          imei: state.vehicle?.imei ?? '',
          logs: state.logs,
          nextCursor: state.logNextCursor,
          isLoading: state.isLoadingLogs,
          isLoadingMore: state.isLoadingMoreLogs,
          onLoad: onLoadLogs,
          onLoadMore: onLoadMoreLogs,
          onApplyRange: (from, to) => onSetLogRange(from: from, to: to),
        );
      case AdminVehicleDetailsTab.commands:
        final vehicle = state.vehicle;
        if (vehicle == null) {
          return const OpenVtsEmptyState(
            title: 'Vehicle unavailable',
            message: 'Cannot load commands without vehicle details.',
          );
        }
        return AdminVehicleCommandsTab(
          vehicle: vehicle,
          customCommands: state.customCommands,
          systemVariables: state.systemVariables,
          history: state.commandHistory,
          isLoading: state.isLoadingCommands,
          isSending: state.isSendingCommand,
          onRefresh: onLoadCommands,
          onSend: onSendCommand,
          onPollStatus: onPollCommandStatus,
          onFetchCommandLog: onFetchCommandLog,
        );
      case AdminVehicleDetailsTab.sensors:
        return AdminVehicleSensorsTab(
          isLoading: state.isLoadingSensors,
          isCreating: state.isCreatingSensor,
          isUpdating: state.isUpdatingSensor,
          isDeleting: state.isDeletingSensor,
          isRunning: state.isRunningSensor,
          sensors: state.sensors,
          onLoad: onLoadSensors,
          onCreate: onCreateSensor,
          onUpdate: onUpdateSensor,
          onDelete: onDeleteSensor,
          onRun: onRunSensor,
        );
      case AdminVehicleDetailsTab.documents:
        return AdminVehicleDocumentsTab(
          vehicleId: state.vehicleId,
          apiBaseUrl: apiBaseUrl,
          documents: state.documents,
          docTypes: state.documentTypes,
          isLoading: state.isLoadingDocuments,
          isUploading: state.isUploadingDocument,
          isUpdating: state.isUpdatingDocument,
          isDeleting: state.isDeletingDocument,
          onLoad: onLoadDocuments,
          onUpload: onUploadDocument,
          onUpdate: onUpdateDocument,
          onDelete: onDeleteDocument,
        );
      case AdminVehicleDetailsTab.config:
        final vehicle = state.vehicle;
        if (vehicle == null) {
          return const OpenVtsEmptyState(
            title: 'No config',
            message: 'Vehicle details are unavailable.',
          );
        }
        return AdminVehicleConfigTab(
          vehicle: vehicle,
          isSaving: state.isUpdatingConfig,
          onSave: onUpdateConfig,
        );
      case AdminVehicleDetailsTab.events:
        return AdminVehicleEventsTab(
          imei: state.vehicle?.imei ?? '',
          events: state.events,
          nextCursor: state.eventNextCursor,
          isLoading: state.isLoadingEvents,
          isLoadingMore: state.isLoadingMoreEvents,
          onLoad: onLoadEvents,
          onLoadMore: onLoadMoreEvents,
          onApplyFilters: ({
            DateTime? from,
            DateTime? to,
            String? source,
            String? severity,
          }) =>
              onSetEventFilters(
            from: from,
            to: to,
            source: source,
            severity: severity,
          ),
        );
    }
  }
}

enum _Action { edit, toggleStatus, delete }
