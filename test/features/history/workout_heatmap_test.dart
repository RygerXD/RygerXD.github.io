import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/workout_heatmap.dart';

void main() {
  testWidgets('renders heatmap as one painted grid and supports date taps',
      (WidgetTester tester) async {
    DateTime? selectedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: WorkoutHeatmap(
              workoutDates: <DateTime>[DateTime(2026, 2, 24)],
              daysToShow: 10,
              initialPivotDate: DateTime(2026, 3),
              onDateSelected: (DateTime date) {
                selectedDate = date;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder heatmapCanvas = find.byWidgetPredicate(
      (Widget widget) =>
          widget is CustomPaint && widget.size == const Size(76, 116),
    );
    expect(heatmapCanvas, findsOneWidget);

    final Offset gridTopLeft = tester.getTopLeft(heatmapCanvas);
    await tester.tapAt(gridTopLeft + const Offset(68, 24));
    expect(selectedDate, DateTime(2026, 3));
  });
}
