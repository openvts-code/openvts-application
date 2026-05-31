class Validators {
  const Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _numericRegex = RegExp(r'^\d+$');

  // Character limits matching backend constraints
  static const int maxNameLength = 120;
  static const int maxEmailLength = 254;
  static const int maxUsernameLength = 50;
  static const int maxPasswordLength = 100;
  static const int minPasswordLength = 8;
  static const int maxMobilePrefixLength = 10;
  static const int maxMobileNumberLength = 20;
  static const int minMobileNumberLength = 7;
  static const int maxCompanyNameLength = 200;
  static const int maxAddressLength = 200;
  static const int maxPincodeLength = 20;

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
    if (s.length > maxEmailLength) {
      return 'Email must be $maxEmailLength characters or fewer';
    }
    if (!_emailRegex.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Admin form validators
  // ---------------------------------------------------------------------------

  static String? adminName(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Full name is required';
    if (s.length > maxNameLength) {
      return 'Full name must be $maxNameLength characters or fewer';
    }
    return null;
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
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Username is required';
    if (s.length > maxUsernameLength) {
      return 'Username must be $maxUsernameLength characters or fewer';
    }
    return null;
  }

  static String? adminPassword(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < minPasswordLength) {
      return 'Minimum $minPasswordLength characters';
    }
    if (s.length > maxPasswordLength) {
      return 'Password must be $maxPasswordLength characters or fewer';
    }
    return null;
  }

  static String? adminConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm the password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? companyName(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Company name is required';
    if (s.length > maxCompanyNameLength) {
      return 'Company name must be $maxCompanyNameLength characters or fewer';
    }
    return null;
  }

  static String? address(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Address is required';
    if (s.length > maxAddressLength) {
      return 'Address must be $maxAddressLength characters or fewer';
    }
    return null;
  }

  static String? mobilePrefix(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Mobile prefix is required';
    if (s.length > maxMobilePrefixLength) {
      return 'Mobile prefix must be $maxMobilePrefixLength characters or fewer';
    }
    return null;
  }

  static String? mobileNumber(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Mobile number is required';
    if (!_numericRegex.hasMatch(s)) {
      return 'Mobile number must be numeric';
    }
    if (s.length < minMobileNumberLength) {
      return 'Mobile number must be at least $minMobileNumberLength digits';
    }
    if (s.length > maxMobileNumberLength) {
      return 'Mobile number must be $maxMobileNumberLength digits or fewer';
    }
    return null;
  }

  static String? pincodeOptional(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_numericRegex.hasMatch(s)) return 'Pincode must be numeric';
    if (s.length > maxPincodeLength) {
      return 'Pincode must be $maxPincodeLength characters or fewer';
    }
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
