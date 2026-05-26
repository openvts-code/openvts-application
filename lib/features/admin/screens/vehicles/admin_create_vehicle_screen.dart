import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_searchable_dropdown.dart';
import '../../../../shared/widgets/open_vts_text_field.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_vehicle_model.dart';

class AdminCreateVehicleScreen extends ConsumerStatefulWidget {
  const AdminCreateVehicleScreen({super.key});

  @override
  ConsumerState<AdminCreateVehicleScreen> createState() =>
      _AdminCreateVehicleScreenState();
}

class _AdminCreateVehicleScreenState
    extends ConsumerState<AdminCreateVehicleScreen> {
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
      final service = ref.read(adminVehicleServiceProvider);
      final results = await Future.wait<dynamic>([
        service.getUsers(),
        service.getQuickDevices(),
        service.getVehicleTypes(),
        service.getPricingPlans(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = results[0] as List<AdminVehicleUserMini>;
        _devices = results[1] as List<AdminQuickDeviceOption>;
        _vehicleTypes = results[2] as List<AdminVehicleTypeOption>;
        _plans = results[3] as List<AdminPricingPlanOption>;
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
    final userOptions = _users
        .map(
          (item) => OpenVtsDropdownOption<String>(
            value: item.id,
            label: item.name.trim().isEmpty ? item.mobileDisplay : item.name,
            subtitle: item.mobileDisplay.trim().isEmpty ? item.email : item.mobileDisplay,
            searchText: '${item.name} ${item.email} ${item.mobileDisplay} ${item.username}',
          ),
        )
        .toList(growable: false);

    final deviceOptions = _devices
        .map(
          (item) => OpenVtsDropdownOption<String>(
            value: item.id,
            label: item.imei.trim().isEmpty ? item.name : item.imei,
            subtitle: item.simNumber.trim().isEmpty ? item.name : item.simNumber,
            searchText: '${item.imei} ${item.simNumber} ${item.name}',
          ),
        )
        .toList(growable: false);

    final planOptions = _plans
        .map(
          (item) => OpenVtsDropdownOption<String>(
            value: item.id,
            label: item.name,
            subtitle: item.price == null
                ? item.currency
                : '${item.price} ${item.currency}'.trim(),
            searchText: '${item.name} ${item.price} ${item.currency}',
          ),
        )
        .toList(growable: false);

    return _FormSection(
      icon: Icons.link_rounded,
      title: 'Assignment',
      description:
          'Link the vehicle to a primary user, GPS device, and pricing plan.',
      children: [
        OpenVtsSearchableDropdown<String>(
          label: 'Primary user',
          required: true,
          hintText:
              _users.isEmpty ? 'No users available' : 'Select primary user',
          searchHintText: 'Search user name, email, or mobile',
          sheetTitle: 'Select primary user',
          leadingIcon: Icons.person_outline_rounded,
          enabled: _users.isNotEmpty,
          options: userOptions,
          value: _userId,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Primary user is required'
              : null,
          onChanged: (value) => setState(() => _userId = value),
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'Device',
          required: true,
          hintText:
              _devices.isEmpty ? 'No devices available' : 'Select GPS device',
          searchHintText: 'Search IMEI or SIM number',
          sheetTitle: 'Select device',
          leadingIcon: Icons.router_outlined,
          enabled: _devices.isNotEmpty,
          options: deviceOptions,
          value: _deviceId,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Device is required' : null,
          onChanged: (value) => setState(() => _deviceId = value),
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'Pricing plan',
          required: true,
          hintText: _plans.isEmpty ? 'No plans available' : 'Select pricing plan',
          searchHintText: 'Search plan name',
          sheetTitle: 'Select pricing plan',
          leadingIcon: Icons.payments_outlined,
          enabled: _plans.isNotEmpty,
          options: planOptions,
          value: _planId,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Pricing plan is required'
              : null,
          onChanged: (value) => setState(() => _planId = value),
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
        _deviceId == null ||
        _vehicleTypeId == null ||
        _planId == null) {
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
              deviceId: _parseRequiredId(_deviceId, 'device'),
              vehicleTypeId: _parseRequiredId(_vehicleTypeId, 'vehicle type'),
              primaryUserId: _parseRequiredId(_userId, 'primary user'),
              planId: _parseRequiredId(_planId, 'pricing plan'),
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

  int _parseRequiredId(String? value, String fieldName) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      throw FormatException('Invalid $fieldName selected.');
    }
    return parsed;
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
            color: isDark ? OpenVtsColors.darkBackground : OpenVtsColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
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
