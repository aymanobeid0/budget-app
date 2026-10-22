/// The Currency the user picked in Settings. A display label only: amounts
/// are never converted.
enum Currency {
  mru('MRU', 'Mauritanian ouguiya'),
  usd('USD', 'US dollar'),
  eur('EUR', 'Euro'),
  egp('EGP', 'Egyptian pound'),
  sar('SAR', 'Saudi riyal');

  const Currency(this.code, this.label);

  /// Shown until the user picks another.
  static const fallback = Currency.mru;

  /// Shown next to amounts, e.g. "3,980 MRU".
  final String code;

  /// The full name, shown in the picker, e.g. "US dollar".
  final String label;
}

/// Amount formatting and parsing.
///
/// Amounts are shown in tabular figures with thousands separators and
/// decimals only when they carry a value (450 → "450", 1550 minor → "15.50").
class Money {
  const Money._();

  /// Parses what the user typed into minor units, without going through a
  /// double: "42" → 4200, "42.5" → 4250, "42,50" → 4250 (a comma is a decimal
  /// point). Null when [text] is not an amount: empty, more than one
  /// separator, or more than two decimals.
  static int? parseMinor(String text) {
    final match = RegExp(r'^(\d+)(?:[.,](\d{0,2}))?$').firstMatch(text.trim());
    if (match == null) return null;
    final whole = int.tryParse(match[1]!);
    if (whole == null) return null;
    final fraction = (match[2] ?? '').padRight(2, '0');
    return whole * 100 + int.parse(fraction);
  }

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
