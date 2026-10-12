class AppValidators {
  // Regular expression for Indian Permanent Account Number (PAN)
  static final RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  // Basic URL Validation
  static final RegExp urlRegex = RegExp(
    r'^(https?:\/\/)?([\w\d\-_]+\.)+[\w\d\-_]+(\/[\w\d\-_%#?&=.]*)?$',
    caseSensitive: false,
  );

  static String? validateAccountHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account holder name is required';
    }
    return null;
  }

  static String? validateAccountNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account nickname is required';
    }
    return null;
  }

  static String? validatePan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN number is required';
    }
    final upperVal = value.trim().toUpperCase();
    if (!panRegex.hasMatch(upperVal)) {
      return 'Invalid PAN format. Example: ABCDE1234F';
    }
    return null;
  }

  static String? validateBrokerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Broker name is required';
    }
    return null;
  }

  static String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL (e.g. https://linkintime.co.in)';
    }
    return null;
  }

  static String maskPan(String? pan) {
    if (pan == null || pan.length != 10) return '**********';
    final upper = pan.toUpperCase();
    return '${upper.substring(0, 5)}****${upper.substring(9)}';
  }
}
