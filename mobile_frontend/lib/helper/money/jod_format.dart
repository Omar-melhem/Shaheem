// Formats Jordanian Dinar amounts stored as integer fils.

/// Formats [fils] (1 JOD = 1000 fils) as a JOD amount with exactly three
/// decimals and thousands separators, e.g. `-12345678` → `-12,345.678`.
///
/// Integer arithmetic only, never `double` (D-A25). Western digits, `,` for
/// thousands and `.` for decimals; the minus sign is kept. The result is
/// left-to-right text: place it inside an LTR isolate in RTL layouts so the
/// sign and digits keep their order.
String formatJodFils(int fils) {
  final negative = fils < 0;
  // BigInt avoids overflow for the most negative int.
  final magnitude = BigInt.from(fils).abs();
  final thousand = BigInt.from(1000);
  final whole = (magnitude ~/ thousand).toString();
  final fraction = (magnitude % thousand).toString().padLeft(3, '0');

  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '${negative ? '-' : ''}$grouped.$fraction';
}

/// Wraps [text] in Unicode left-to-right isolate marks (LRI … PDI), so an
/// amount such as `-1,000.000` is not reordered inside Arabic text.
String ltrIsolate(String text) => '\u2066$text\u2069';
