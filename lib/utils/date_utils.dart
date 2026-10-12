import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateFormat.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _shortDateFormat.format(date);
  }

  static String formatDateString(String? dateIso) {
    if (dateIso == null || dateIso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateIso);
      return _dateFormat.format(dt);
    } catch (_) {
      return dateIso;
    }
  }

  static String formatShortDateString(String? dateIso) {
    if (dateIso == null || dateIso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateIso);
      return _shortDateFormat.format(dt);
    } catch (_) {
      return dateIso;
    }
  }

  static DateTime? parseDate(String? dateIso) {
    if (dateIso == null || dateIso.isEmpty) return null;
    try {
      return DateTime.parse(dateIso);
    } catch (_) {
      return null;
    }
  }

  // Formats accepted when parsing dates pasted in from outside the app
  // (e.g. a spreadsheet or a copied table), in addition to plain ISO.
  static final List<DateFormat> _flexibleFormats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('dd-MMM-yyyy'),
    DateFormat('dd MMM yyyy'),
    DateFormat('d MMM yyyy'),
    DateFormat('MMM dd, yyyy'),
    DateFormat('MMMM d, yyyy'),
  ];

  /// Parses a date typed or pasted by the user in one of several common
  /// formats (ISO, dd-MM-yyyy, dd/MM/yyyy, "12 Sep 2025", etc). Returns
  /// null if none of the accepted formats match.
  static DateTime? parseFlexible(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    for (final format in _flexibleFormats) {
      try {
        return format.parseStrict(value);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static String toIsoDate(DateTime? date) {
    if (date == null) return '';
    return date.toIso8601String().split('T').first;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }
}
