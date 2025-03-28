class Validator {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name cannot be empty.';
    }
    final nameRegExp = RegExp(
      r"^[\p{L}\s'-]+(?:\.\s?[\p{L}]+)*$",
      unicode: true,
    );
    if (!nameRegExp.hasMatch(value)) {
      return 'Enter a valid name.';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number cannot be empty.';
    }
    final phoneRegExp = RegExp(r'^09\d{9}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String firebaseError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
        return 'Email not found in our records.';
      default:
        return 'An error occurred. Try again later.';
    }
  }
}
