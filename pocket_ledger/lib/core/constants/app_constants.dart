abstract final class AppConstants {
  // App
  static const String appName = 'PocketLedger';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'pocket_ledger.db';
  static const int dbVersion = 1;

  // Security
  static const int pinLength = 6;
  static const int maxWrongAttempts = 5;

  // Auto-lock options (minutes)
  static const List<int> autoLockOptions = [0, 1, 5, 15, 30];

  // Currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  ];

  // Timezones
  static const String defaultTimezone = 'Asia/Kolkata';

  // Backup
  static const List<String> backupFrequencies = ['daily', 'weekly', 'monthly'];
}
