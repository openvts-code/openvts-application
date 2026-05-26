import 'package:intl/intl.dart';

class DateTimeFormatter {
  const DateTimeFormatter();

  String formatDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  String formatDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value);
  }

  String formatTime(DateTime value) {
    return DateFormat('hh:mm a').format(value);
  }
}
