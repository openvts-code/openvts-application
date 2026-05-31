import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_searchable_dropdown.dart';
import '../../../../shared/widgets/open_vts_text_field.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_inventory_model.dart';
import '../../models/admin_plans_model.dart';
import '../../models/admin_users_model.dart';
import '../../models/admin_vehicle_model.dart';
import '../inventory/widgets/admin_inventory_add_sheet.dart';
import '../plans/widgets/admin_plan_form_sheet.dart';
import '../users/widgets/admin_create_user_sheet.dart';

class AdminCreateVehicleScreen extends ConsumerStatefulWidget {
  const AdminCreateVehicleScreen({super.key});

  @override
  ConsumerState<AdminCreateVehicleScreen> createState() =>
      _AdminCreateVehicleScreenState();
}

class _AdminCreateVehicleScreenState
    extends ConsumerState<AdminCreateVehicleScreen> {
  static const _createUserValue = '__create_user__';
  static const _createDeviceValue = '__create_device__';
  static const _createPlanValue = '__create_plan__';

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _vinController = TextEditingController();
  final _plateController = TextEditingController();

  var _users = const <AdminVehicleUserMini>[];
  var _devices = const <AdminQuickDeviceOption>[];
  var _vehicleTypes = const <AdminVehicleTypeOption>[];
  var _plans = const <AdminPricingPlanOption>[];

  String? _userId;
  String? _deviceId;
  String? _vehicleTypeId;
  String? _planId;

  bool _isCatalogLoading = true;
  String? _catalogError;
  bool _catalogPrepared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCatalog());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vinController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _prepareCatalog() async {
    if (_catalogPrepared) {
      return;
    }
    _catalogPrepared = true;

    setState(() {
      _isCatalogLoading = true;
      _catalogError = null;
    });

    try {
      final catalog = await ref
          .read(adminVehiclesControllerProvider.notifier)
          .getCreateVehicleCatalog();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = catalog.users;
        _devices = catalog.devices;
        _vehicleTypes = catalog.vehicleTypes;
        _plans = catalog.plans;
        _isCatalogLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCatalogLoading = false;
        _catalogError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      adminVehiclesControllerProvider.select((state) => state.isCreating),
    );

    return OpenVtsPageScaffold(
      title: 'Create Vehicle',
      headerMode: OpenVtsPageHeaderMode.closeable,
      onClose: () => _handleClose(context),
      padding: EdgeInsets.zero,
      body: SafeArea(
        top: false,
        child: _isCatalogLoading &&
                _users.isEmpty &&
                _devices.isEmpty &&
                _vehicleTypes.isEmpty &&
                _plans.isEmpty
            ? const Center(child: OpenVtsLoader())
            : _catalogError != null &&
                    _users.isEmpty &&
                    _devices.isEmpty &&
                    _vehicleTypes.isEmpty &&
                    _plans.isEmpty
                ? OpenVtsErrorView(
                    message: _catalogError!,
                    onRetry: () {
                      _catalogPrepared = false;
                      _prepareCatalog();
                    },
                  )
                : _buildForm(context, isSubmitting),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isSubmitting) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.sm,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.md,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IntroBanner(),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _vehicleDetailsSection(),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _assignmentSection(),
                ],
              ),
            ),
          ),
        ),
        _StickyActionBar(
          isSubmitting: isSubmitting,
          onCancel: () {
            if (isSubmitting) {
              return;
            }
            _handleClose(context);
          },
          onSubmit: isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Widget _vehicleDetailsSection() {
    return _FormSection(
      icon: Icons.local_shipping_outlined,
      title: 'Vehicle details',
      description: 'Basic identification for the new vehicle.',
      children: [
        OpenVtsTextField(
          label: 'Vehicle name',
          hintText: 'RV215',
          controller: _nameController,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, fieldName: 'Vehicle name'),
        ),
        OpenVtsTextField(
          label: 'VIN',
          hintText: 'Vehicle identification number',
          controller: _vinController,
          textInputAction: TextInputAction.next,
          validator: (value) => Validators.required(value, fieldName: 'VIN'),
        ),
        OpenVtsTextField(
          label: 'Plate number',
          hintText: 'MH85FR5664',
          controller: _plateController,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, fieldName: 'Plate number'),
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'Vehicle type',
          required: true,
          hintText: _vehicleTypes.isEmpty
              ? 'No vehicle types available'
              : 'Select vehicle type',
          searchHintText: 'Search vehicle type',
          sheetTitle: 'Select vehicle type',
          leadingIcon: Icons.category_outlined,
          enabled: _vehicleTypes.isNotEmpty,
          options: _vehicleTypes
              .map(
                (item) => OpenVtsDropdownOption<String>(
                  value: item.id,
                  label: item.name,
                  subtitle: item.slug.trim().isEmpty ? null : item.slug,
                  searchText: '${item.name} ${item.slug}',
                ),
              )
              .toList(growable: false),
          value: _vehicleTypeId,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vehicle type is required'
              : null,
          onChanged: (value) => setState(() => _vehicleTypeId = value),
        ),
      ],
    );
  }

  Widget _assignmentSection() {
    final userOptions = [
      const OpenVtsDropdownOption<String>(
        value: _createUserValue,
        label: '+ Create new user',
        subtitle: 'Create user without leaving this vehicle form',
        leading: Icon(Icons.add_circle_outline_rounded,
            size: 20, color: OpenVtsColors.brandInk),
        searchText: 'add create new user',
      ),
      ..._users
          .map(
            (item) => OpenVtsDropdownOption<String>(
              value: item.id,
              label: item.name.trim().isEmpty ? item.mobileDisplay : item.name,
              subtitle: item.mobileDisplay.trim().isEmpty
                  ? item.email
                  : item.mobileDisplay,
              searchText:
                  '${item.name} ${item.email} ${item.mobileDisplay} ${item.username}',
            ),
          )
          .toList(growable: false),
    ];

    final deviceOptions = [
      const OpenVtsDropdownOption<String>(
        value: _createDeviceValue,
        label: '+ Add new device',
        subtitle: 'Create device without leaving this form',
        leading: Icon(Icons.add_circle_outline,
            size: 20, color: OpenVtsColors.brandInk),
        searchText: 'add new create device',
      ),
      ..._devices.map(
        (item) => OpenVtsDropdownOption<String>(
          value: item.id,
          label: item.imei.trim().isEmpty ? item.name : item.imei,
          subtitle: item.simNumber.trim().isEmpty ? item.name : item.simNumber,
          searchText: '${item.imei} ${item.simNumber} ${item.name}',
        ),
      ),
    ];

    final planOptions = [
      const OpenVtsDropdownOption<String>(
        value: _createPlanValue,
        label: '+ Create new plan',
        subtitle: 'Create pricing plan without leaving this form',
        leading: Icon(Icons.add_circle_outline,
            size: 20, color: OpenVtsColors.brandInk),
        searchText: 'create new pricing plan',
      ),
      ..._plans.map(
        (item) => OpenVtsDropdownOption<String>(
          value: item.id,
          label: item.name,
          subtitle: item.price == null
              ? item.currency
              : '${item.price} ${item.currency}'.trim(),
          searchText: '${item.name} ${item.price} ${item.currency}',
        ),
      ),
    ];

    return _FormSection(
      icon: Icons.link_rounded,
      title: 'Assignment',
      description:
          'Link the vehicle to a primary user, GPS device, and pricing plan.',
      children: [
        OpenVtsSearchableDropdown<String>(
          label: 'Primary user',
          required: true,
          hintText: _isCatalogLoading
              ? 'Loading users...'
              : _catalogError != null
                  ? 'Failed to load users'
                  : _users.isEmpty
                      ? 'Create or select primary user'
                      : 'Select primary user',
          searchHintText: 'Search user name, email, or mobile',
          sheetTitle: 'Select primary user',
          leadingIcon: Icons.person_outline_rounded,
          enabled: !_isCatalogLoading && _catalogError == null,
          options: userOptions,
          value: _userId,
          validator: (value) => value == null || value.trim().isEmpty ||
                  value == _createUserValue
              ? 'Primary user is required'
              : null,
          onChanged: (value) async {
            if (value == _createUserValue) {
              await _handleCreateUser();
              return;
            }
            setState(() => _userId = value);
          },
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'Device',
          required: true,
          hintText: _devices.isEmpty && !_isCatalogLoading
              ? 'No devices available'
              : 'Select GPS device',
          searchHintText: 'Search IMEI or SIM number',
          sheetTitle: 'Select device',
          leadingIcon: Icons.router_outlined,
          enabled: !_isCatalogLoading || _devices.isNotEmpty,
          options: deviceOptions,
          value: _deviceId,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Device is required'
              : null,
          onChanged: (value) async {
            if (value == _createDeviceValue) {
              await _handleCreateDevice();
              return;
            }
            setState(() => _deviceId = value);
          },
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'Pricing plan',
          required: true,
          hintText: _plans.isEmpty && !_isCatalogLoading
              ? 'No plans available'
              : 'Select pricing plan',
          searchHintText: 'Search plan name',
          sheetTitle: 'Select pricing plan',
          leadingIcon: Icons.payments_outlined,
          enabled: !_isCatalogLoading || _plans.isNotEmpty,
          options: planOptions,
          value: _planId,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Pricing plan is required'
              : null,
          onChanged: (value) async {
            if (value == _createPlanValue) {
              await _handleCreatePlan();
              return;
            }
            setState(() => _planId = value);
          },
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      ToastHelper.showError(
        'Please fix the highlighted fields before continuing.',
        context: context,
      );
      return;
    }

    if (_userId == null ||
        _userId == _createUserValue ||
        _deviceId == null ||
        _deviceId == _createDeviceValue ||
        _vehicleTypeId == null ||
        _planId == null ||
        _planId == _createPlanValue) {
      ToastHelper.showError(
        'Primary user, device, vehicle type, and pricing plan are required.',
        context: context,
      );
      return;
    }

    try {
      await ref.read(adminVehiclesControllerProvider.notifier).createVehicle(
            AdminCreateVehicleRequest(
              name: _nameController.text.trim(),
              vin: _vinController.text.trim(),
              plateNumber: _plateController.text.trim(),
              deviceId: _deviceId!.trim(),
              vehicleTypeId: _vehicleTypeId!.trim(),
              primaryUserId: _userId!.trim(),
              planId: _planId!.trim(),
            ),
          );

      if (!mounted) {
        return;
      }

      ToastHelper.showSuccess(
        'Vehicle "${_nameController.text.trim()}" created.',
        context: context,
      );
      if (context.canPop()) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError(
        ref.read(adminVehiclesControllerProvider).errorMessage ??
            error.toString(),
        context: context,
      );
    }
  }

  Future<void> _handleCreateDevice() async {
    final createdDevice = await OpenVtsBottomSheet.show<AdminInventoryDevice?>(
      context: context,
      title: 'Add Device or SIM',
      initialChildSize: 0.80,
      minChildSize: 0.60,
      maxChildSize: 0.80,
      snap: false,
      child: const AdminInventoryAddSheet(),
    );

    if (!mounted) return;

    if (createdDevice != null) {
      await _refreshDevices();
      setState(() => _deviceId = createdDevice.id);
      ToastHelper.showSuccess('Device created and selected', context: context);
    }
  }

  Future<void> _handleCreatePlan() async {
    final createdPlan = await OpenVtsBottomSheet.show<AdminPlan?>(
      context: context,
      title: 'Create Pricing Plan',
      initialChildSize: 0.80,
      minChildSize: 0.60,
      maxChildSize: 0.80,
      snap: false,
      child: const AdminPlanFormSheet.create(),
    );

    if (!mounted) return;

    if (createdPlan != null) {
      await _refreshPlans();
      setState(() => _planId = createdPlan.id);
      ToastHelper.showSuccess('Plan created and selected', context: context);
    }
  }

  Future<void> _refreshDevices() async {
    try {
      final devices = await ref
          .read(adminVehiclesControllerProvider.notifier)
          .getQuickDevices();
      if (!mounted) return;
      setState(() => _devices = devices);
    } catch (error) {
      // Silent fail - user can retry manually
    }
  }

  Future<void> _refreshPlans() async {
    try {
      final plans = await ref
          .read(adminVehiclesControllerProvider.notifier)
          .getPricingPlans();
      if (!mounted) return;
      setState(() => _plans = plans);
    } catch (error) {
      // Silent fail - user can retry manually
    }
  }

  Future<void> _handleCreateUser() async {
    final createdUser = await OpenVtsBottomSheet.show<AdminUserListItem?>(
      context: context,
      title: 'Create User',
      initialChildSize: 0.80,
      minChildSize: 0.60,
      maxChildSize: 0.80,
      snap: false,
      child: const AdminCreateUserSheet(),
    );

    if (!mounted) return;

    if (createdUser != null) {
      await _refreshUsers();
      if (!mounted) return;
      setState(() => _userId = createdUser.id);
      ToastHelper.showSuccess('User created and selected', context: context);
    }
  }

  Future<void> _refreshUsers() async {
    try {
      final users = await ref
          .read(adminVehiclesControllerProvider.notifier)
          .getUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError('Unable to refresh users.', context: context);
    }
  }

  void _handleClose(BuildContext context) {
    final hasUnsavedInput = _nameController.text.trim().isNotEmpty ||
        _vinController.text.trim().isNotEmpty ||
        _plateController.text.trim().isNotEmpty ||
        _userId != null ||
        _deviceId != null ||
        _vehicleTypeId != null ||
        _planId != null;

    if (!hasUnsavedInput) {
      if (context.canPop()) {
        context.pop();
      }
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard new vehicle?'),
        content: const Text(
          'Your changes will be lost. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Keep editing'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: OpenVtsColors.error),
            onPressed: () {
              dialogContext.pop();
              if (context.canPop()) {
                context.pop();
              }
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(
          color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? OpenVtsColors.darkBackground
                  : OpenVtsColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_road_rounded,
              size: 18,
              color: isDark
                  ? OpenVtsColors.darkTextPrimary
                  : OpenVtsColors.brandInk,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a new vehicle',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete the sections below. Required fields are marked with an asterisk (*).',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(
          color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: icon,
            title: title,
            description: description,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: OpenVtsSpacing.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isDark ? OpenVtsColors.darkBackground : OpenVtsColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                isDark ? OpenVtsColors.darkTextPrimary : OpenVtsColors.brandInk,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Cancel',
                variant: OpenVtsButtonVariant.secondary,
                onPressed: isSubmitting ? null : onCancel,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              flex: 2,
              child: OpenVtsButton(
                label: 'Create vehicle',
                isLoading: isSubmitting,
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
