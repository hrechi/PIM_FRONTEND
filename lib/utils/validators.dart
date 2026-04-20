class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? requiredEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    return email(value);
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final phoneRegex = RegExp(r'^\+?[\d\s\-]{7,15}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }

  static String? requiredPhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    return phone(value);
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? assetName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Asset name is required';
    final normalized = value.trim();

    // Allow readable names like "Kubota M7-132", "New Holland", "Tractor" and block noisy/symbol-heavy input.
    final allowedChars = RegExp(r'^[A-Za-z0-9][A-Za-z0-9\s\-_/\.]{0,79}$');
    if (!allowedChars.hasMatch(normalized)) {
      return 'Use letters/numbers and simple separators only';
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(normalized);
    if (!hasLetter) {
      return 'Asset name must include at least one letter';
    }

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    final hasMeaningfulToken = tokens.any((token) => token.length >= 2);
    if (!hasMeaningfulToken) {
      return 'Asset name must have meaningful terms (at least 2 characters each).';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
