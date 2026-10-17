import 'dart:math';

final _random = Random();

/// A new local record id: [prefix] plus 16 random hex digits, e.g.
/// `exp_3f9a…`. Unique enough for one person's records on one phone.
String randomId(String prefix) {
  const chars = '0123456789abcdef';
  final buffer = StringBuffer(prefix);
  for (var i = 0; i < 16; i++) {
    buffer.write(chars[_random.nextInt(chars.length)]);
  }
  return buffer.toString();
}
