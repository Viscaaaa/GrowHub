import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String timeAgo(dynamic dateInput) {
    if (dateInput == null) return '';
    DateTime? dateTime;
    if (dateInput is DateTime) {
      dateTime = dateInput;
    } else if (dateInput is String) {
      dateTime = DateTime.tryParse(dateInput);
    }
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
    }
  }

  static String formatFull(dynamic dateInput) {
    if (dateInput == null) return '';
    DateTime? dateTime;
    if (dateInput is DateTime) {
      dateTime = dateInput;
    } else if (dateInput is String) {
      dateTime = DateTime.tryParse(dateInput);
    }
    if (dateTime == null) return '';

    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  static String formatDate(dynamic dateInput) {
    if (dateInput == null) return '';
    DateTime? dateTime;
    if (dateInput is DateTime) {
      dateTime = dateInput;
    } else if (dateInput is String) {
      dateTime = DateTime.tryParse(dateInput);
    }
    if (dateTime == null) return '';

    return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
  }
}
