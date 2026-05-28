class ContentSafety {
  ContentSafety._();

  static List<String> checkForPatientIdentifiers(String text) {
    final warnings = <String>[];
    final lower = text.toLowerCase();

    if (lower.contains('dob:') || lower.contains('date of birth')) {
      warnings.add('May contain date of birth');
    }

    if (lower.contains('phone:') ||
        lower.contains('mobile:') ||
        lower.contains('contact:')) {
      warnings.add('May contain contact number');
    }

    if (lower.contains('address:') || lower.contains('resident of')) {
      warnings.add('May contain address');
    }

    final phoneRegex = RegExp(r'\b[6-9]\d{9}\b');
    if (phoneRegex.hasMatch(text)) {
      warnings.add('May contain phone number');
    }

    final aadhaarRegex = RegExp(r'\b\d{12}\b');
    if (aadhaarRegex.hasMatch(text)) {
      warnings.add('May contain Aadhaar number');
    }

    return warnings;
  }
}
