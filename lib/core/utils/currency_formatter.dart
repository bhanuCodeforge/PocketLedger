import '../../features/settings/data/user_profile_repository.dart';

class CurrencyFormatter {
  static const _noDecimals = {'JPY', 'KRW', 'VND', 'IDR', 'HUF'};

  /// Format using a full [UserProfile] (respects currency code decimals).
  static String format(double amount, UserProfile profile) {
    final symbol = profile.currencySymbol;
    final code = profile.currencyCode;
    final decimals = _noDecimals.contains(code) ? 0 : 2;
    final formatted = amount.abs().toStringAsFixed(decimals);
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol$formatted';
  }

  /// Format using a currency Map from [currencyProvider] ({symbol, code}).
  static String formatAmount(double amount, Map<String, String> currency) {
    final symbol = currency['symbol'] ?? '₹';
    final code = currency['code'] ?? 'INR';
    final decimals = _noDecimals.contains(code) ? 0 : 2;
    final formatted = amount.abs().toStringAsFixed(decimals);
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol$formatted';
  }

  /// Format using only a symbol string (assumes 2 decimal places).
  static String formatSimple(double amount, String symbol) {
    final formatted = amount.abs().toStringAsFixed(2);
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol$formatted';
  }

  /// Compact format: 1500 → ₹1.5K, 1200000 → ₹1.2M
  static String compact(double amount, String symbol) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000) return '$sign$symbol${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$sign$symbol${(abs / 1000).toStringAsFixed(1)}K';
    return '$sign$symbol${abs.toStringAsFixed(2)}';
  }
}
