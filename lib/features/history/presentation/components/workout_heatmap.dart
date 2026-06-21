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
  static const double _monthLabelHeight = 18;
  static const double _weekdayLabelWidth = 30;
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
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Column(
                  children: <Widget>[
                    SizedBox(height: _monthLabelHeight),
                    SizedBox(height: _cellStep),
                    _WeekdayLabel('Mon'),
                    SizedBox(height: _cellStep),
                    _WeekdayLabel('Wed'),
                    SizedBox(height: _cellStep),
                    _WeekdayLabel('Fri'),
                    SizedBox(height: _cellStep),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: weeks
                          .map((_HeatmapWeek week) =>
                              _MonthLabel(week.monthLabel))
                          .toList(),
                    ),
                    Row(
                      children: weeks.map((_HeatmapWeek week) {
                        return Column(
                          children: week.days.map((_HeatmapDay day) {
                            return _HeatmapSquare(
                              date: day.date,
                              hasWorkout: workoutDays.contains(day.date),
                              isEmpty: !day.isInRange,
                              isSelected: _isSameDay(
                                day.date,
                                widget.selectedDate ?? DateTime(0),
                              ),
                              onTap: widget.onDateSelected,
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
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

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _WorkoutHeatmapState._cellStep,
      width: _WorkoutHeatmapState._weekdayLabelWidth,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel(this.label);

  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _WorkoutHeatmapState._monthLabelHeight,
      width: _WorkoutHeatmapState._cellStep,
      child: label == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label!,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.75),
                ),
              ),
            ),
    );
  }
}

class _HeatmapSquare extends StatelessWidget {
  const _HeatmapSquare({
    required this.date,
    this.hasWorkout = false,
    this.isEmpty = false,
    this.isSelected = false,
    this.onTap,
  });

  static const double _size = 12;

  final DateTime date;
  final bool hasWorkout;
  final bool isEmpty;
  final bool isSelected;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (isEmpty) {
      return const SizedBox(width: _size + 2, height: _size + 2);
    }

    return Tooltip(
      message: '${date.month}/${date.day}/${date.year}',
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(date),
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: _size,
          height: _size,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: hasWorkout
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
            border: isSelected
                ? Border.all(color: colorScheme.onSurface, width: 1.5)
                : null,
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
