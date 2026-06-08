import 'package:intl/intl.dart';

/// Locale-aware formatting helpers for dates, distance, volume and money.
class Fmt {
  Fmt._();

  static String date(DateTime d, {String locale = 'en'}) =>
      DateFormat('d MMM yyyy', locale).format(d);

  static String monthYear(DateTime d, {String locale = 'en'}) =>
      DateFormat('MMM yyyy', locale).format(d);

  static String shortDate(DateTime d, {String locale = 'en'}) =>
      DateFormat('d MMM', locale).format(d);

  static String number(num value, {int decimals = 0, String locale = 'en'}) {
    final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
    return NumberFormat(pattern, locale).format(value);
  }

  static String money(num value, {required String currency, String locale = 'en'}) {
    final n = NumberFormat('#,##0', locale).format(value);
    return locale == 'ar' ? '$n $currency' : '$currency $n';
  }

  static String distance(num km, {String unit = 'km', String locale = 'en'}) =>
      '${number(km, locale: locale)} $unit';

  /// "in 12 days" / "5 days ago" / "Today" style relative description.
  static String relativeDays(DateTime target, {String locale = 'en'}) {
    final now = DateTime.now();
    final diff = DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (locale == 'ar') {
      if (diff == 0) return 'اليوم';
      if (diff > 0) return 'خلال $diff يوم';
      return 'منذ ${-diff} يوم';
    }
    if (diff == 0) return 'Today';
    if (diff > 0) return 'in $diff days';
    return '${-diff} days ago';
  }
}
