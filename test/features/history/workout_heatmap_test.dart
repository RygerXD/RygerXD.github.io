import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/workout_heatmap.dart';

void main() {
  testWidgets('renders month labels and one square for each day in range',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: WorkoutHeatmap(
              workoutDates: <DateTime>[DateTime(2026, 2, 24)],
              daysToShow: 10,
              initialPivotDate: DateTime(2026, 3),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Feb'), findsOneWidget);
    expect(find.text('Mar'), findsOneWidget);

    final Iterable<Container> daySquares = tester.widgetList<Container>(
      find.byWidgetPredicate((Widget widget) {
        if (widget is! Container) {
          return false;
        }
        final Decoration? decoration = widget.decoration;
        final BoxConstraints? constraints = widget.constraints;
        return constraints?.minWidth == 12 &&
            constraints?.maxWidth == 12 &&
            constraints?.minHeight == 12 &&
            constraints?.maxHeight == 12 &&
            decoration is BoxDecoration &&
            decoration.borderRadius != null;
      }),
    );
    expect(daySquares.length, 10);
  });
}
