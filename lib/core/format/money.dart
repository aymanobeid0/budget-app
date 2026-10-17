/// Amount formatting for the Calm Ledger UI.
///
/// Amounts are shown in Geist Mono with thousands separators and decimals
/// only when they carry a value (450 → "450", 1550 minor → "15.50").
/// The Currency the user picked in Settings. A display label only: amounts
/// are never converted.
enum Currency {
  mru('MRU'),
  usd('USD'),
  eur('EUR'),
  egp('EGP'),
  sar('SAR');

  const Currency(this.code);

  /// Shown next to amounts, e.g. "3,980 MRU".
  final String code;
}

class Money {
  const Money._();

  /// Formats an amount stored in minor units.
  static String format(int amountMinor) {
    final negative = amountMinor < 0;
    final abs = amountMinor.abs();
    final whole = abs ~/ 100;
    final fraction = abs % 100;

    final digits = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    if (fraction != 0) {
      buf.write('.');
      buf.write(fraction.toString().padLeft(2, '0'));
    }
    return '${negative ? '-' : ''}$buf';
  }

  /// Formats with the Currency code, e.g. "3,980 MRU".
  static String withLabel(int amountMinor, Currency currency) => '${format(amountMinor)} ${currency.code}';
}
