enum MonthNameStyle {
  short,
  long,
}

const List<String> _shortMonthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _longMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String? optionalText(String? value) {
  final String? trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String formatDate(
  DateTime date, {
  MonthNameStyle monthStyle = MonthNameStyle.short,
}) {
  return '${formatMonthName(date.month, monthStyle: monthStyle)} ${date.day}, ${date.year}';
}

String formatMonthName(
  int month, {
  MonthNameStyle monthStyle = MonthNameStyle.short,
}) {
  final List<String> months = switch (monthStyle) {
    MonthNameStyle.short => _shortMonthNames,
    MonthNameStyle.long => _longMonthNames,
  };
  return months[month - 1];
}

String formatRelativeDateLabel(DateTime date, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final DateTime today =
      DateTime(reference.year, reference.month, reference.day);
  final DateTime targetDate = DateTime(date.year, date.month, date.day);
  final int difference = today.difference(targetDate).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  if (difference < 7) {
    return _weekdayNames[date.weekday - 1];
  }
  return formatDate(date);
}

String formatTime(DateTime date) {
  final int hour = date.hour;
  final String minute = date.minute.toString().padLeft(2, '0');
  final String period = hour >= 12 ? 'PM' : 'AM';
  final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$displayHour:$minute $period';
}

String formatDuration(
  int seconds, {
  String zeroLabel = '-',
  bool includeSeconds = true,
  bool omitZeroMinuteRemainder = false,
}) {
  if (seconds <= 0) {
    return zeroLabel;
  }

  final Duration duration = Duration(seconds: seconds);
  if (duration.inHours == 0) {
    if (!includeSeconds) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
  }

  final int minutesRemainder = duration.inMinutes.remainder(60);
  if (omitZeroMinuteRemainder && minutesRemainder == 0) {
    return '${duration.inHours}h';
  }
  return '${duration.inHours}h ${minutesRemainder}m';
}

String formatShortDuration(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  return formatDuration(seconds, zeroLabel: '0s');
}

String formatWeight(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
