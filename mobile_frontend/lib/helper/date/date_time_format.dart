// Formats server timestamps for display.

/// Formats [at] in the device's local time as `yyyy/MM/dd HH:mm` with
/// Western digits (like money amounts), e.g. `2026/11/15 09:05`.
///
/// The app has no time-zone database, so "local" is the device's zone
/// (captains use the app in Jordan, Asia/Amman). The result is
/// left-to-right text: wrap it with `ltrIsolate` inside Arabic text.
String formatLocalDateTime(DateTime at) {
  final local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}/${two(local.month)}/${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
