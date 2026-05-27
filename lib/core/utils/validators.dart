class Validators {
  const Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _numericRegex = RegExp(r'^\d+$');

  // ---------------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------------

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Admin form validators
  // ---------------------------------------------------------------------------

  static String? adminName(String? value) {
    return required(value, fieldName: 'Full name');
  }

  static String? adminEmailRequired(String? value) {
    return email(value);
  }

  static String? adminEmailOptional(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_emailRegex.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  static String? adminUsername(String? value) {
    return required(value, fieldName: 'Username');
  }

  static String? adminPassword(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? adminConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm the password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? companyName(String? value) {
    return required(value, fieldName: 'Company name');
  }

  static String? address(String? value) {
    return required(value, fieldName: 'Address');
  }

  static String? mobilePrefix(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile prefix is required';
    }
    return null;
  }

  static String? mobileNumber(String? value) {
    return required(value, fieldName: 'Mobile number');
  }

  static String? pincodeOptional(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_numericRegex.hasMatch(s)) return 'Pincode must be numeric';
    if (s.length > 10) return 'Pincode is too long';
    return null;
  }

  static String? credits(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    final parsed = int.tryParse(s);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Credits cannot be negative';
    return null;
  }
}
