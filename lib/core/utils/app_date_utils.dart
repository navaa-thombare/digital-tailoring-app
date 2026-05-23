import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String nowIso() => _dateTime.format(DateTime.now().toUtc());

  static String todayIsoDate() => _date.format(DateTime.now());

  static DateTime parseDate(String value) => _date.parseStrict(value);

  static String dateIso(DateTime value) => _date.format(value);

  static String addDaysIso(String startDate, int days) {
    return dateIso(parseDate(startDate).add(Duration(days: days)));
  }

  static int daysBetweenIsoDates(String from, String to) {
    final start = DateTime.parse(from);
    final end = DateTime.parse(to);
    return end.difference(start).inDays;
  }
}
