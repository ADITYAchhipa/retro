/// Industrial-grade form validators for Rentaly app
/// Provides comprehensive validation for all form inputs
class FormValidators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // RFC 5322 compliant email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    // Check for common typos
    final domain = value.split('@').last.toLowerCase();
    
    if (domain == 'gmail.con' || domain == 'gmail.co') {
      return 'Did you mean gmail.com?';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (value.length > 128) {
      return 'Password is too long';
    }
    
    // Check for password strength
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!hasDigits) {
      return 'Password must contain at least one number';
    }
    
    if (!hasSpecialCharacters) {
      return 'Password must contain at least one special character';
    }
    
    // Check for common weak passwords
    final weakPasswords = [
      'password', 'Password123!', '12345678', 'qwerty123',
      'admin123', 'letmein123', 'welcome123'
    ];
    
    if (weakPasswords.any((weak) => value.toLowerCase().contains(weak.toLowerCase()))) {
      return 'This password is too common. Please choose a stronger password';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }
    
    // Basic international phone number validation
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    
    if (!phoneRegex.hasMatch(digitsOnly)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return '$fieldName is too long';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    
    if (!nameRegex.hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    // Check for proper capitalization
    if (value[0] != value[0].toUpperCase()) {
      return '$fieldName should start with a capital letter';
    }
    
    return null;
  }
  
  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 10) {
      return 'Please enter a complete address';
    }
    
    if (value.length > 200) {
      return 'Address is too long';
    }
    
    // Check for minimum components (should have numbers and letters)
    bool hasNumbers = value.contains(RegExp(r'[0-9]'));
    bool hasLetters = value.contains(RegExp(r'[a-zA-Z]'));
    
    if (!hasNumbers || !hasLetters) {
      return 'Please enter a valid street address';
    }
    
    return null;
  }
  
  // Postal/ZIP code validation
  static String? validatePostalCode(String? value, {String? countryCode = 'US'}) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }
    
    // US ZIP code validation
    if (countryCode == 'US') {
      final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
      if (!zipRegex.hasMatch(value)) {
        return 'Please enter a valid ZIP code (e.g., 12345 or 12345-6789)';
      }
    }
    
    // Canadian postal code validation
    else if (countryCode == 'CA') {
      final postalRegex = RegExp(r'^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$');
      if (!postalRegex.hasMatch(value)) {
        return 'Please enter a valid Canadian postal code';
      }
    }
    
    // UK postcode validation
    else if (countryCode == 'UK') {
      final postcodeRegex = RegExp(
        r'^[A-Z]{1,2}[0-9]{1,2}[A-Z]?\s?[0-9][A-Z]{2}$',
        caseSensitive: false,
      );
      if (!postcodeRegex.hasMatch(value)) {
        return 'Please enter a valid UK postcode';
      }
    }
    
    // Indian PIN code validation
    else if (countryCode == 'IN') {
      final pinRegex = RegExp(r'^\d{6}$');
      if (!pinRegex.hasMatch(value)) {
        return 'Please enter a valid 6-digit PIN code';
      }
    }
    
    // Generic validation for other countries
    else {
      if (value.length < 3 || value.length > 10) {
        return 'Please enter a valid postal code';
      }
    }
    
    return null;
  }
  
  // Credit card validation
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    // Remove spaces and dashes
    final cardNumber = value.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Invalid card number length';
    }
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cardNumber)) {
      return 'Card number can only contain digits';
    }
    
    // Luhn algorithm validation
    if (!_luhnCheck(cardNumber)) {
      return 'Invalid card number';
    }
    
    return null;
  }
  
  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }
  
  // Expiry date validation
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    // Expected format: MM/YY or MM/YYYY
    final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$');
    
    if (!expiryRegex.hasMatch(value)) {
      return 'Invalid format (MM/YY)';
    }
    
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1].length == 2 ? '20${parts[1]}' : parts[1]);
    
    final now = DateTime.now();
    final expiry = DateTime(year, month);
    
    if (expiry.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    
    if (expiry.isAfter(DateTime(now.year + 20, now.month))) {
      return 'Expiry date is too far in the future';
    }
    
    return null;
  }
  
  // Amount validation
  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.replaceAll(',', ''));
    
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (min != null && amount < min) {
      return 'Minimum amount is \$$min';
    }
    
    if (max != null && amount > max) {
      return 'Maximum amount is \$$max';
    }
    
    return null;
  }
  
  // Date validation
  static String? validateDate(String? value, {
    DateTime? minDate,
    DateTime? maxDate,
    bool allowPast = true,
    bool allowFuture = true,
  }) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    DateTime? date;
    try {
      date = DateTime.parse(value);
    } catch (e) {
      return 'Invalid date format';
    }
    
    final now = DateTime.now();
    
    if (!allowPast && date.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'Date cannot be in the past';
    }
    
    if (!allowFuture && date.isAfter(DateTime(now.year, now.month, now.day))) {
      return 'Date cannot be in the future';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return 'Date must be after ${minDate.toString().split(' ')[0]}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return 'Date must be before ${maxDate.toString().split(' ')[0]}';
    }
    
    return null;
  }
  
  // URL validation
  static String? validateURL(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
  
  // Generic required field validation
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Luhn algorithm for credit card validation
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
  
  // Property-specific validators
  static String? validatePropertyTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Property title is required';
    }
    
    if (value.length < 10) {
      return 'Title must be at least 10 characters';
    }
    
    if (value.length > 100) {
      return 'Title is too long (max 100 characters)';
    }
    
    return null;
  }
  
  static String? validatePropertyDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 50) {
      return 'Description must be at least 50 characters';
    }
    
    if (value.length > 2000) {
      return 'Description is too long (max 2000 characters)';
    }
    
    return null;
  }
  
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value.replaceAll(',', ''));
    
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    
    if (price > 100000) {
      return 'Price seems too high. Please verify';
    }
    
    return null;
  }
}
