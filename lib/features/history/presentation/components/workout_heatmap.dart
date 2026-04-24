import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';

class WorkoutHeatmap extends StatefulWidget {
  const WorkoutHeatmap({
    super.key,
    required this.workoutDates,
    this.daysToShow = 180, // Show roughly 6 months by default
  });

  final List<DateTime> workoutDates;
  final int daysToShow;

  @override
  State<WorkoutHeatmap> createState() => _WorkoutHeatmapState();
}

class _WorkoutHeatmapState extends State<WorkoutHeatmap> {
  late DateTime _pivotDate;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _pivotDate = DateTime(now.year, now.month, now.day);
  }

  void _navigateBack() {
    setState(() {
      _pivotDate = _pivotDate.subtract(const Duration(days: 30));
    });
  }

  void _navigateForward() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime newDate = _pivotDate.add(const Duration(days: 30));
    
    setState(() {
      _pivotDate = newDate.isAfter(today) ? today : newDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    // Generate dates to show based on _pivotDate
    final List<DateTime> dates = List<DateTime>.generate(widget.daysToShow, (int index) {
      return _pivotDate.subtract(Duration(days: widget.daysToShow - 1 - index));
    });

    // Group dates into weeks (Sunday to Saturday)
    final List<List<DateTime?>> weeks = <List<DateTime?>>[];
    List<DateTime?> currentWeek = List<DateTime?>.filled(7, null);
    
    for (final DateTime date in dates) {
      final int weekday = date.weekday % 7; // 0 for Sunday, 6 for Saturday
      currentWeek[weekday] = date;
      
      if (weekday == 6 || date == dates.last) {
        weeks.add(List<DateTime?>.from(currentWeek));
        currentWeek = List<DateTime?>.filled(7, null);
      }
    }

    final bool canGoForward = _pivotDate.isBefore(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Workout Frequency',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.outline,
                ),
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _navigateBack,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Previous',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: canGoForward ? _navigateForward : null,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Start from the most recent date
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Weekday labels - precisely aligned with squares (14px per row)
                const Column(
                  children: <Widget>[
                    SizedBox(height: 14), // Sun
                    _WeekdayLabel('Mon'), // Mon
                    SizedBox(height: 14), // Tue
                    _WeekdayLabel('Wed'), // Wed
                    SizedBox(height: 14), // Thu
                    _WeekdayLabel('Fri'), // Fri
                    SizedBox(height: 14), // Sat
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                // Heatmap grid
                Row(
                  children: weeks.map((List<DateTime?> week) {
                    return Column(
                      children: week.map((DateTime? date) {
                        if (date == null) {
                          return const _HeatmapSquare(isEmpty: true);
                        }
                        
                        final bool hasWorkout = widget.workoutDates.any((DateTime d) => 
                          d.year == date.year && 
                          d.month == date.month && 
                          d.day == date.day
                        );
                        
                        return _HeatmapSquare(
                          hasWorkout: hasWorkout,
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      width: 28,
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

class _HeatmapSquare extends StatelessWidget {
  const _HeatmapSquare({
    this.hasWorkout = false,
    this.isEmpty = false,
  });

  static const double _size = 12;

  final bool hasWorkout;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    if (isEmpty) {
      return const SizedBox(width: _size + 2, height: _size + 2);
    }

    return Container(
      width: _size,
      height: _size,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: hasWorkout 
            ? colorScheme.primary 
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
