/// Currency converter for catalogue price display.
///
/// All animal prices are stored in TND (Tunisian Dinar) by the backend.
/// When a catalogue is set to display in a different currency,
/// prices are converted on the fly using these rates.
///
/// ⚠️  WARNING: Rates are static approximations — last updated 2025-01.
/// For production use, replace with a live exchange-rate API
/// (e.g., exchangerate-api.com or fixer.io).
/// Base currency: TND
class CurrencyConverter {
  /// Date when the rates below were last manually updated.
  /// Visible in the UI to warn users that prices are approximate.
  static const String ratesLastUpdated = '2025-01';

  // ── Exchange rates relative to TND ───────────────────────────────────────
  // 1 TND = X [currency]
  // ⚠️  Static — update periodically or integrate a live API.
  static const Map<String, double> _ratesFromTND = {
    'TND': 1.0,
    'USD': 0.32,   // 1 TND ≈ 0.32 USD
    'EUR': 0.30,   // 1 TND ≈ 0.30 EUR
    'GBP': 0.25,   // 1 TND ≈ 0.25 GBP
    'MAD': 3.20,   // 1 TND ≈ 3.20 MAD (Moroccan Dirham)
    'DZD': 43.0,   // 1 TND ≈ 43 DZD (Algerian Dinar)
    'SAR': 1.20,   // 1 TND ≈ 1.20 SAR (Saudi Riyal)
    'AED': 1.18,   // 1 TND ≈ 1.18 AED (UAE Dirham)
    'LYD': 1.55,   // 1 TND ≈ 1.55 LYD (Libyan Dinar)
    'EGP': 9.80,   // 1 TND ≈ 9.80 EGP (Egyptian Pound)
  };

  // ── Currency symbols ──────────────────────────────────────────────────────
  static const Map<String, String> _symbols = {
    'TND': 'TND',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'MAD': 'MAD',
    'DZD': 'DA',
    'SAR': 'SAR',
    'AED': 'AED',
    'LYD': 'LYD',
    'EGP': 'EGP',
  };

  /// Convert a price from TND to the target currency.
  /// Returns the converted amount rounded to the nearest integer.
  static double convert(double amountInTND, String targetCurrency) {
    final rate = _ratesFromTND[targetCurrency.toUpperCase()] ?? 1.0;
    return amountInTND * rate;
  }

  /// Format a TND price for display in the target currency.
  /// Example: formatPrice(1000, 'EUR') → '300 €'
  static String formatPrice(double amountInTND, String targetCurrency) {
    final currency = targetCurrency.toUpperCase();
    final converted = convert(amountInTND, currency);
    final symbol = _symbols[currency] ?? currency;

    // Currencies that go before the amount
    const prefixCurrencies = {'USD', 'GBP'};
    final rounded = converted.round();

    if (prefixCurrencies.contains(currency)) {
      return '$symbol$rounded';
    }
    return '$rounded $symbol';
  }

  /// Format with both the converted price AND the original TND price.
  /// Example: '300 € (1 000 TND)'
  static String formatWithOriginal(double amountInTND, String targetCurrency) {
    if (targetCurrency.toUpperCase() == 'TND') {
      return '${amountInTND.round()} TND';
    }
    final converted = formatPrice(amountInTND, targetCurrency);
    final tnd = '${amountInTND.round()} TND';
    return '$converted  ≈  $tnd';
  }

  /// Get the symbol for a currency code.
  static String symbol(String currency) =>
      _symbols[currency.toUpperCase()] ?? currency;

  /// List of supported currencies for the dropdown.
  static const List<String> supported = [
    'TND', 'USD', 'EUR', 'GBP', 'MAD', 'DZD', 'SAR', 'AED', 'LYD', 'EGP',
  ];
}
