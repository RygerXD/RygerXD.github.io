import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('app shell renders and navigates between tabs', (WidgetTester tester) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final WorkoutRepository workoutRepository = InMemoryWorkoutRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(<WorkoutSessionEntity>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          workoutRepositoryProvider.overrideWithValue(workoutRepository),
        ],
        child: const WorkoutApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Import Workout JSON'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('All Plans'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Audio cues'), findsOneWidget);
  });
}
