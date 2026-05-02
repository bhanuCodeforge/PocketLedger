import '../../features/settings/data/user_profile_repository.dart';

class CurrencyFormatter {
  static String format(double amount, UserProfile profile) {
    final symbol = profile.currencySymbol;
    final code = profile.currencyCode;

    // Currencies with no decimal places
    const noDecimals = {'JPY', 'KRW', 'VND', 'IDR', 'HUF'};
    final decimals = noDecimals.contains(code) ? 0 : 2;

    final formatted = amount.abs().toStringAsFixed(decimals);
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol$formatted';
  }

  static String formatSimple(double amount, String symbol) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
