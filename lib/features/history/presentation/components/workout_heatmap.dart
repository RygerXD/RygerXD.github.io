import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';

class WorkoutHeatmap extends StatefulWidget {
  const WorkoutHeatmap({
    super.key,
    required this.workoutDates,
    this.daysToShow = 180, // Show roughly 6 months by default
    this.selectedDate,
    this.onDateSelected,
    @visibleForTesting this.initialPivotDate,
  });

  final List<DateTime> workoutDates;
  final int daysToShow;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? initialPivotDate;

  @override
  State<WorkoutHeatmap> createState() => _WorkoutHeatmapState();
}

class _WorkoutHeatmapState extends State<WorkoutHeatmap> {
  static const double _cellStep = 14;
  static const double _cellSize = 12;
  static const double _monthLabelHeight = 18;
  static const double _weekdayLabelWidth = 30;
  static const double _gridGap = AppSpacing.xs;
  static const double _heatmapHeight = _monthLabelHeight + (_cellStep * 7);

  late final ScrollController _scrollController;
  late DateTime _pivotDate;

  @override
  void initState() {
    super.initState();
    final DateTime pivot = widget.initialPivotDate ?? DateTime.now();
    _pivotDate = DateTime(pivot.year, pivot.month, pivot.day);
    _scrollController = ScrollController();
    _scrollToLatestAfterLayout();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    setState(() {
      _pivotDate = _pivotDate.subtract(const Duration(days: 30));
    });
    _scrollToLatestAfterLayout();
  }

  void _navigateForward() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime newDate = _pivotDate.add(const Duration(days: 30));

    setState(() {
      _pivotDate = newDate.isAfter(today) ? today : newDate;
    });
    _scrollToLatestAfterLayout();
  }

  void _scrollToLatestAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime rangeStart = _pivotDate.subtract(
      Duration(days: widget.daysToShow - 1),
    );
    final List<_HeatmapWeek> weeks =
        _buildCalendarWeeks(rangeStart, _pivotDate);
    final Set<DateTime> workoutDays = widget.workoutDates
        .map((DateTime date) => DateTime(date.year, date.month, date.day))
        .toSet();

    final bool canGoForward = _pivotDate.isBefore(today);
    final double heatmapWidth =
        _weekdayLabelWidth + _gridGap + (weeks.length * _cellStep);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Workout Frequency',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.outline,
                      ),
                ),
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _navigateBack,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Previous',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: canGoForward ? _navigateForward : null,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: _heatmapHeight,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget heatmap = _HeatmapCanvas(
                width: heatmapWidth,
                height: _heatmapHeight,
                weeks: weeks,
                workoutDays: workoutDays,
                selectedDate: widget.selectedDate,
                colorScheme: colorScheme,
                textDirection: Directionality.of(context),
                onDateSelected: widget.onDateSelected,
                dateAtOffset: (Offset offset) => _dateAtOffset(offset, weeks),
              );
              const EdgeInsets padding =
                  EdgeInsets.symmetric(horizontal: AppSpacing.md);
              if (heatmapWidth + padding.horizontal <= constraints.maxWidth) {
                return Padding(
                  padding: padding,
                  child: heatmap,
                );
              }

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: padding,
                child: heatmap,
              );
            },
          ),
        ),
      ],
    );
  }

  List<_HeatmapWeek> _buildCalendarWeeks(
      DateTime rangeStart, DateTime rangeEnd) {
    final DateTime calendarStart = rangeStart.subtract(
      Duration(days: rangeStart.weekday % DateTime.daysPerWeek),
    );
    final int rangeEndWeekday = rangeEnd.weekday % DateTime.daysPerWeek;
    final DateTime calendarEnd = rangeEnd.add(
      Duration(days: DateTime.saturday - rangeEndWeekday),
    );
    final List<_HeatmapWeek> weeks = <_HeatmapWeek>[];

    DateTime weekStart = calendarStart;
    while (!weekStart.isAfter(calendarEnd)) {
      final List<_HeatmapDay> days = List<_HeatmapDay>.generate(
        DateTime.daysPerWeek,
        (int index) {
          final DateTime date = weekStart.add(Duration(days: index));
          return _HeatmapDay(
            date: date,
            isInRange: !date.isBefore(rangeStart) && !date.isAfter(rangeEnd),
          );
        },
      );

      weeks.add(
        _HeatmapWeek(
          days: days,
          monthLabel: _monthLabelForWeek(days, rangeStart),
        ),
      );
      weekStart = weekStart.add(const Duration(days: DateTime.daysPerWeek));
    }

    return weeks;
  }

  String? _monthLabelForWeek(List<_HeatmapDay> days, DateTime rangeStart) {
    for (final _HeatmapDay day in days) {
      if (!day.isInRange) {
        continue;
      }
      if (_isSameDay(day.date, rangeStart) || day.date.day == 1) {
        return formatMonthName(day.date.month);
      }
    }
    return null;
  }

  DateTime? _dateAtOffset(Offset offset, List<_HeatmapWeek> weeks) {
    final double gridX = offset.dx - _weekdayLabelWidth - _gridGap;
    final double gridY = offset.dy - _monthLabelHeight;
    if (gridX < 0 || gridY < 0) {
      return null;
    }

    final int weekIndex = gridX ~/ _cellStep;
    final int dayIndex = gridY ~/ _cellStep;
    if (weekIndex < 0 ||
        weekIndex >= weeks.length ||
        dayIndex < 0 ||
        dayIndex >= DateTime.daysPerWeek) {
      return null;
    }

    final _HeatmapDay day = weeks[weekIndex].days[dayIndex];
    return day.isInRange ? day.date : null;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _HeatmapCanvas extends StatelessWidget {
  const _HeatmapCanvas({
    required this.width,
    required this.height,
    required this.weeks,
    required this.workoutDays,
    required this.selectedDate,
    required this.colorScheme,
    required this.textDirection,
    required this.onDateSelected,
    required this.dateAtOffset,
  });

  final double width;
  final double height;
  final List<_HeatmapWeek> weeks;
  final Set<DateTime> workoutDays;
  final DateTime? selectedDate;
  final ColorScheme colorScheme;
  final TextDirection textDirection;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? Function(Offset offset) dateAtOffset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: onDateSelected == null
          ? null
          : (TapUpDetails details) {
              final DateTime? date = dateAtOffset(details.localPosition);
              if (date != null) {
                onDateSelected!(date);
              }
            },
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          painter: _HeatmapPainter(
            weeks: weeks,
            workoutDays: workoutDays,
            selectedDate: selectedDate,
            colorScheme: colorScheme,
            textDirection: textDirection,
          ),
        ),
      ),
    );
  }
}

class _HeatmapDay {
  const _HeatmapDay({
    required this.date,
    required this.isInRange,
  });

  final DateTime date;
  final bool isInRange;
}

class _HeatmapWeek {
  const _HeatmapWeek({
    required this.days,
    required this.monthLabel,
  });

  final List<_HeatmapDay> days;
  final String? monthLabel;
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.weeks,
    required this.workoutDays,
    required this.selectedDate,
    required this.colorScheme,
    required this.textDirection,
  });

  final List<_HeatmapWeek> weeks;
  final Set<DateTime> workoutDays;
  final DateTime? selectedDate;
  final ColorScheme colorScheme;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    _paintWeekdayLabels(canvas);
    _paintMonthLabels(canvas);
    _paintDays(canvas);
  }

  void _paintWeekdayLabels(Canvas canvas) {
    final TextStyle labelStyle = TextStyle(
      fontSize: 9,
      color: colorScheme.outline.withValues(alpha: 0.7),
    );
    const Map<int, String> labels = <int, String>{
      1: 'Mon',
      3: 'Wed',
      5: 'Fri',
    };
    for (final MapEntry<int, String> label in labels.entries) {
      _paintText(
        canvas,
        text: label.value,
        offset: Offset(
          0,
          _WorkoutHeatmapState._monthLabelHeight +
              (label.key * _WorkoutHeatmapState._cellStep),
        ),
        width: _WorkoutHeatmapState._weekdayLabelWidth,
        height: _WorkoutHeatmapState._cellStep,
        style: labelStyle,
        alignment: Alignment.center,
      );
    }
  }

  void _paintMonthLabels(Canvas canvas) {
    final TextStyle labelStyle = TextStyle(
      fontSize: 10,
      color: colorScheme.outline.withValues(alpha: 0.75),
    );
    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final String? label = weeks[weekIndex].monthLabel;
      if (label == null) {
        continue;
      }
      _paintText(
        canvas,
        text: label,
        offset:
            Offset(_gridLeft + (weekIndex * _WorkoutHeatmapState._cellStep), 0),
        width: _WorkoutHeatmapState._cellStep * 4,
        height: _WorkoutHeatmapState._monthLabelHeight,
        style: labelStyle,
        alignment: Alignment.centerLeft,
      );
    }
  }

  void _paintDays(Canvas canvas) {
    final Paint inactivePaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final Paint activePaint = Paint()..color = colorScheme.primary;
    final Paint selectedPaint = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const Radius radius = Radius.circular(2);

    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final _HeatmapWeek week = weeks[weekIndex];
      for (int dayIndex = 0; dayIndex < week.days.length; dayIndex++) {
        final _HeatmapDay day = week.days[dayIndex];
        if (!day.isInRange) {
          continue;
        }

        final RRect rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            _gridLeft + (weekIndex * _WorkoutHeatmapState._cellStep) + 1,
            _WorkoutHeatmapState._monthLabelHeight +
                (dayIndex * _WorkoutHeatmapState._cellStep) +
                1,
            _WorkoutHeatmapState._cellSize,
            _WorkoutHeatmapState._cellSize,
          ),
          radius,
        );
        canvas.drawRRect(
          rect,
          workoutDays.contains(day.date) ? activePaint : inactivePaint,
        );
        if (_isSameDay(day.date, selectedDate)) {
          canvas.drawRRect(rect, selectedPaint);
        }
      }
    }
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double width,
    required double height,
    required TextStyle style,
    required Alignment alignment,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: 1,
    )..layout(maxWidth: width);
    final Offset alignedOffset = Offset(
      offset.dx + ((width - painter.width) * (alignment.x + 1) / 2),
      offset.dy + ((height - painter.height) * (alignment.y + 1) / 2),
    );
    painter.paint(canvas, alignedOffset);
  }

  double get _gridLeft =>
      _WorkoutHeatmapState._weekdayLabelWidth + _WorkoutHeatmapState._gridGap;

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.weeks != weeks ||
        oldDelegate.workoutDays != workoutDays ||
        !_isSameDay(oldDelegate.selectedDate, selectedDate) ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.textDirection != textDirection;
  }
}

bool _isSameDay(DateTime? first, DateTime? second) {
  return first != null &&
      second != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
