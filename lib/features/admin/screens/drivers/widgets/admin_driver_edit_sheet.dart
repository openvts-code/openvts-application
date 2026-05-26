import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_model.dart';
import '../../../models/admin_driver_details_state.dart';

Future<void> showDriverEditSheet({
  required BuildContext context,
  required AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
          AdminDriverDetailsState>
      provider,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: 'Edit Profile',
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.96,
    child: _DriverEditSheet(provider: provider),
  );
}

class _DriverEditSheet extends ConsumerStatefulWidget {
  const _DriverEditSheet({required this.provider});

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;

  @override
  ConsumerState<_DriverEditSheet> createState() => _DriverEditSheetState();
}

class _DriverEditSheetState extends ConsumerState<_DriverEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobilePrefix;
  late final TextEditingController _mobile;
  late final TextEditingController _username;
  late final TextEditingController _address;
  late final TextEditingController _countryCode;
  late final TextEditingController _stateCode;
  late final TextEditingController _city;
  late final TextEditingController _pincode;
  final List<_AttrRow> _attrs = <_AttrRow>[];

  @override
  void initState() {
    super.initState();
    final driver = ref.read(widget.provider).driver;
    _name = TextEditingController(text: driver?.name ?? '');
    _email = TextEditingController(
      text: driver?.email == '-' ? '' : (driver?.email ?? ''),
    );
    _mobilePrefix = TextEditingController(text: driver?.mobilePrefix ?? '');
    _mobile = TextEditingController(text: driver?.mobile ?? '');
    _username = TextEditingController(text: driver?.username ?? '');
    _address = TextEditingController(
      text: driver?.address.addressLine == '-'
          ? ''
          : (driver?.address.addressLine ?? ''),
    );
    _countryCode = TextEditingController(
      text: driver?.address.countryCode == '-'
          ? ''
          : (driver?.address.countryCode ?? ''),
    );
    _stateCode = TextEditingController(
      text: driver?.address.stateCode == '-'
          ? ''
          : (driver?.address.stateCode ?? ''),
    );
    _city = TextEditingController(
      text: driver?.address.cityId == '-' ? '' : (driver?.address.cityId ?? ''),
    );
    _pincode = TextEditingController(
      text:
          driver?.address.pincode == '-' ? '' : (driver?.address.pincode ?? ''),
    );
    final attrs = driver?.attributes ?? const <String, dynamic>{};
    if (attrs.isEmpty) {
      _attrs.add(_AttrRow());
    } else {
      for (final entry in attrs.entries) {
        _attrs.add(
          _AttrRow(key: entry.key, value: entry.value?.toString() ?? ''),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobilePrefix.dispose();
    _mobile.dispose();
    _username.dispose();
    _address.dispose();
    _countryCode.dispose();
    _stateCode.dispose();
    _city.dispose();
    _pincode.dispose();
    for (final row in _attrs) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final isSubmitting = state.isSavingProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OpenVtsTextField(
              label: 'Name',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return null;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
                return ok ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Mobile Prefix',
              controller: _mobilePrefix,
              validator: (v) => _mobile.text.trim().isNotEmpty &&
                      (v == null || v.trim().isEmpty)
                  ? 'Mobile prefix is required'
                  : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Mobile',
              controller: _mobile,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Mobile is required' : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Username',
              controller: _username,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Username is required'
                  : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(label: 'Address', controller: _address),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(label: 'Country Code', controller: _countryCode),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(label: 'State Code', controller: _stateCode),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(label: 'City', controller: _city),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(label: 'Pincode', controller: _pincode),
            const SizedBox(height: OpenVtsSpacing.sm),
            const Text('Attributes'),
            const SizedBox(height: OpenVtsSpacing.xs),
            ..._attrs.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: row.key,
                        decoration: const InputDecoration(hintText: 'Key'),
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Expanded(
                      child: TextFormField(
                        controller: row.value,
                        decoration: const InputDecoration(hintText: 'Value'),
                      ),
                    ),
                    IconButton(
                      onPressed: _attrs.length == 1
                          ? null
                          : () {
                              setState(() {
                                _attrs.removeAt(index).dispose();
                              });
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _attrs.add(_AttrRow())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add attribute'),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Save Profile',
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final attributes = <String, dynamic>{};
    final seen = <String>{};
    for (final row in _attrs) {
      final key = row.key.text.trim();
      final value = row.value.text.trim();
      if (key.isEmpty) continue;
      if (!seen.add(key.toLowerCase())) {
        ToastHelper.showError(
          'Attribute keys must be unique.',
          context: context,
        );
        return;
      }
      attributes[key] = value;
    }

    final request = AdminDriverUpdateRequest(
      name: _name.text,
      mobilePrefix: _mobilePrefix.text,
      mobile: _mobile.text,
      email: _email.text,
      username: _username.text,
      countryCode: _countryCode.text,
      stateCode: _stateCode.text,
      city: _city.text,
      address: _address.text,
      pincode: _pincode.text,
      attributes: attributes,
    );

    final ok = await ref.read(widget.provider.notifier).updateProfile(request);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess('Profile updated.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(widget.provider).sectionErrorMessage ??
            'Unable to update profile.',
        context: context,
      );
    }
  }
}

class _AttrRow {
  _AttrRow({String? key, String? value})
      : key = TextEditingController(text: key ?? ''),
        value = TextEditingController(text: value ?? '');

  final TextEditingController key;
  final TextEditingController value;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}
