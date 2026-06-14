import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/exercises/application/exercise_catalog.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WorkoutPlan>> plansState =
        ref.watch(loadedWorkoutPlansNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
      ),
      body: plansState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text('Error loading exercises: $error')),
        data: (List<WorkoutPlan> plans) {
          final List<ReferencedExerciseEntry> exercises =
              collectReferencedExercises(plans);
          final List<ReferencedExerciseEntry> filteredExercises =
              _filteredExercises(exercises);
          if (exercises.isEmpty) {
            return const _EmptyState(
              message: 'No exercises yet. Import or create a plan to add some.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search exercises',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (String value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filteredExercises.isEmpty)
                const _EmptyState(message: 'No matching exercises.')
              else
                for (final ReferencedExerciseEntry entry in filteredExercises)
                  _ExerciseCard(
                    entry: entry,
                    onTap: () => _editExercise(context, ref, plans, entry),
                  ),
            ],
          );
        },
      ),
    );
  }

  List<ReferencedExerciseEntry> _filteredExercises(
    List<ReferencedExerciseEntry> exercises,
  ) {
    return filterByFuzzyExerciseName<ReferencedExerciseEntry>(
      entries: exercises,
      query: _query,
      exerciseFor: (ReferencedExerciseEntry entry) => entry.exercise,
    );
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutPlan> plans,
    ReferencedExerciseEntry entry,
  ) async {
    final Exercise? updatedExercise = await showDialog<Exercise>(
      context: context,
      builder: (BuildContext context) => _EditExerciseDialog(
        exercise: entry.exercise,
        sourcePlanNames: entry.planNames,
      ),
    );

    if (updatedExercise == null) {
      return;
    }

    try {
      for (final WorkoutPlan plan in plans) {
        final int exerciseIndex = plan.exercises.indexWhere(
          (Exercise exercise) =>
              exercise.exerciseId == updatedExercise.exerciseId,
        );
        if (exerciseIndex < 0) {
          continue;
        }

        final List<Exercise> updatedExercises =
            List<Exercise>.from(plan.exercises);
        updatedExercises[exerciseIndex] = updatedExercise;
        await ref
            .read(loadedWorkoutPlansNotifierProvider.notifier)
            .loadPlan(plan.copyWith(exercises: updatedExercises));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated ${updatedExercise.name}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating exercise: $error')),
        );
      }
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.entry,
    required this.onTap,
  });

  final ReferencedExerciseEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Exercise exercise = entry.exercise;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              MediaThumbnail(
                imageUrl: optionalText(exercise.imageUrl),
                fallbackIcon: Icons.fitness_center,
                backgroundColor: colors.primaryContainer,
                iconColor: colors.onPrimaryContainer,
                dimension: 56,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (exercise.description != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        exercise.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditExerciseDialog extends StatefulWidget {
  const _EditExerciseDialog({
    required this.exercise,
    required this.sourcePlanNames,
  });

  final Exercise exercise;
  final List<String> sourcePlanNames;

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.exercise.name);
  late final TextEditingController _imageUrlController =
      TextEditingController(text: widget.exercise.imageUrl ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.exercise.description ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Edit Exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'From: ${widget.sourcePlanNames.join(', ')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an exercise name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
                ImageOrGifUrlField(
                  controller: _imageUrlController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              widget.exercise.copyWith(
                name: _nameController.text.trim(),
                imageUrl: optionalText(_imageUrlController.text),
                description: optionalText(_descriptionController.text),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
