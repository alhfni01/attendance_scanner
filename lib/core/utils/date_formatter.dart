import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  static String formatFullDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd - HH:mm').format(dt);
  }
}