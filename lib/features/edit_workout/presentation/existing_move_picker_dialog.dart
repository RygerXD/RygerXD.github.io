import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/exercises/application/exercise_catalog.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ExistingMovePickerDialog extends StatefulWidget {
  const ExistingMovePickerDialog({
    super.key,
    required this.plans,
  });

  final List<WorkoutPlan> plans;

  @override
  State<ExistingMovePickerDialog> createState() =>
      _ExistingMovePickerDialogState();
}

class _ExistingMovePickerDialogState extends State<ExistingMovePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final List<Exercise> _exercises = _collectExercises();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Exercise> filteredExercises = _filteredExercises();

    return AlertDialog(
      title: const Text('Select Existing Exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
              onChanged: (String value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _exercises.isEmpty
                  ? const Center(child: Text('No existing exercises found.'))
                  : filteredExercises.isEmpty
                      ? const Center(child: Text('No matching exercises.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredExercises.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Exercise exercise = filteredExercises[index];
                            return ListTile(
                              leading: _ExerciseThumbnail(
                                imageUrl: optionalText(exercise.imageUrl),
                              ),
                              title: Text(exercise.name),
                              onTap: () => Navigator.of(context).pop(exercise),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<Exercise> _collectExercises() {
    return collectUniqueReferencedExercisesByName(widget.plans);
  }

  List<Exercise> _filteredExercises() {
    return filterByFuzzyExerciseName<Exercise>(
      entries: _exercises,
      query: _query,
      exerciseFor: (Exercise exercise) => exercise,
    );
  }
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return MediaThumbnail(
      imageUrl: imageUrl,
      fallbackIcon: Icons.fitness_center,
      backgroundColor: colors.surfaceContainerHighest,
      iconColor: colors.onSurfaceVariant,
      dimension: 40,
      isCircular: true,
    );
  }
}
