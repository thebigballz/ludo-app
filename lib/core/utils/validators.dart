class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required';
    if (!RegExp(r'^254[0-9]{9}$').hasMatch(value)) {
      return 'Format: 2547XXXXXXXX';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name too short';
    return null;
  }

  static String? amount(String? value, {double min = 10, double max = 5000}) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = double.tryParse(value);
    if (amount == null) return 'Invalid amount';
    if (amount < min) return 'Minimum KES $min';
    if (amount > max) return 'Maximum KES $max';
    return null;
  }
}