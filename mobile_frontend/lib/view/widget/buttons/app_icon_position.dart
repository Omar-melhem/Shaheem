// Logical icon placement shared by the button widgets.

/// Where an icon sits relative to a label, in reading order.
///
/// Logical, not physical: `start` is on the right in Arabic (RTL) and on
/// the left in LTR languages, so components stay correct for future locales.
enum AppIconPosition { start, end }
