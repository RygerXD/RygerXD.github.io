import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/core/media/exercise_media_image.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/core/media/keyboard_media_saver.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/add_move_dialog.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/existing_move_picker_dialog.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class EditWorkoutScreen extends ConsumerStatefulWidget {
  const EditWorkoutScreen({
    super.key,
    required this.planId,
    this.workoutId,
  });

  final String planId;
  final String? workoutId;

  @override
  ConsumerState<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends ConsumerState<EditWorkoutScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final List<WorkoutSet> _sets = <WorkoutSet>[];
  final Map<String, Exercise> _exercisesById = <String, Exercise>{};

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      _loadExistingWorkout();
    }
  }

  void _loadExistingWorkout() {
    if (widget.workoutId == null) {
      // Creating a new workout. Start with one empty set.
      _addSet();
      return;
    }

    final List<WorkoutPlan> plans =
        ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];
    final WorkoutPlan? plan =
        plans.where((WorkoutPlan p) => p.planId == widget.planId).firstOrNull;

    if (plan != null) {
      _cacheExercises(plan.exercises);
      final Workout? workout = plan.workouts
          .where((Workout w) => w.workoutId == widget.workoutId)
          .firstOrNull;
      if (workout != null) {
        _titleController.text = workout.title;
        _imageUrlController.text = workout.imageUrl ?? '';
        _sets.addAll(workout.sets);
      } else {
        _addSet();
      }
    } else {
      _addSet();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addSet() {
    setState(() {
      _sets.add(
        WorkoutSet(
          setId: const Uuid().v4(),
          name: 'Set ${_sets.length + 1}',
          loopCount: 1,
          restBetweenLoopsSeconds: 60,
          moves: <Move>[],
        ),
      );
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });
  }

  void _removeMove(int setIndex, int moveIndex) {
    _updateSetMoves(setIndex, (List<Move> moves) => moves..removeAt(moveIndex));
  }

  void _reorderMove(int setIndex, int oldIndex, int newIndex) {
    _updateSetMoves(setIndex, (List<Move> moves) {
      final int insertionIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
      final Move moved = moves.removeAt(oldIndex);
      moves.insert(insertionIndex, moved);
      return moves;
    });
  }

  void _updateSet(int setIndex, WorkoutSet Function(WorkoutSet set) update) {
    setState(() {
      _sets[setIndex] = update(_sets[setIndex]);
    });
  }

  void _updateSetMoves(
    int setIndex,
    List<Move> Function(List<Move> moves) update,
  ) {
    _updateSet(setIndex, (WorkoutSet set) {
      return set.copyWith(moves: update(List<Move>.from(set.moves)));
    });
  }

  void _showAddMoveDialog(int setIndex, {Exercise? initialExercise}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AddMoveDialog(
        initialExercise: initialExercise,
        onAdd: (Move move, Exercise newExercise) {
          _upsertExerciseInPlan(newExercise);
          _updateSetMoves(setIndex, (List<Move> moves) => moves..add(move));
        },
      ),
    );
  }

  void _showEditMoveDialog(int setIndex, int moveIndex) {
    final Move move = _sets[setIndex].moves[moveIndex];
    final Exercise initialExercise = _getExercise(move.exerciseId) ??
        Exercise(exerciseId: move.exerciseId, name: 'Unknown Exercise');

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AddMoveDialog(
        initialMove: move,
        initialExercise: initialExercise,
        onAdd: (Move updatedMove, Exercise updatedExercise) {
          _upsertExerciseInPlan(updatedExercise);
          _updateSetMoves(
            setIndex,
            (List<Move> moves) {
              moves[moveIndex] = updatedMove;
              return moves;
            },
          );
        },
      ),
    );
  }

  Future<void> _showExistingMovesPicker(int setIndex) async {
    final List<WorkoutPlan> plans =
        ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];

    final Exercise? selectedExercise = await showDialog<Exercise>(
      context: context,
      builder: (BuildContext context) => ExistingMovePickerDialog(plans: plans),
    );

    if (selectedExercise != null && mounted) {
      _showAddMoveDialog(setIndex, initialExercise: selectedExercise);
    }
  }

  void _upsertExerciseInPlan(Exercise exercise) {
    _exercisesById[exercise.exerciseId] = exercise;

    final List<WorkoutPlan> plans =
        ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];
    final WorkoutPlan? plan =
        plans.where((WorkoutPlan p) => p.planId == widget.planId).firstOrNull;
    if (plan != null) {
      final List<Exercise> updatedExercises =
          List<Exercise>.from(plan.exercises);
      final int existingIndex = updatedExercises.indexWhere(
        (Exercise e) => e.exerciseId == exercise.exerciseId,
      );
      if (existingIndex >= 0) {
        updatedExercises[existingIndex] = exercise;
      } else {
        updatedExercises.add(exercise);
      }
      final WorkoutPlan updatedPlan =
          plan.copyWith(exercises: updatedExercises);
      // We load it silently into memory so the UI can instantly find it.
      ref
          .read(loadedWorkoutPlansNotifierProvider.notifier)
          .loadPlan(updatedPlan);
    }
  }

  Future<void> _handleWorkoutKeyboardMediaInserted(
    KeyboardInsertedContent content,
  ) async {
    final String? savedPath = await saveKeyboardInsertedMedia(content);
    if (!mounted) {
      return;
    }
    if (savedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add that image.')),
      );
      return;
    }

    _imageUrlController.text = savedPath;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image added.')),
    );
  }

  void _handleWorkoutNativeKeyboardMediaInserted(String? savedPath) {
    if (!mounted) {
      return;
    }
    if (savedPath == null || savedPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add that image.')),
      );
      return;
    }

    _imageUrlController.text = savedPath;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image added.')),
    );
  }

  void _cacheExercises(List<Exercise> exercises) {
    _exercisesById.addEntries(
      exercises.map((Exercise exercise) =>
          MapEntry<String, Exercise>(exercise.exerciseId, exercise)),
    );
  }

  void _updateSetName(int setIndex, String value) {
    final String trimmed = value.trim();
    _updateSet(
      setIndex,
      (WorkoutSet set) => set.copyWith(name: trimmed.isEmpty ? null : trimmed),
    );
  }

  void _updateSetLoopCount(int setIndex, String value) {
    final int? loopCount = int.tryParse(value);
    if (loopCount == null || loopCount < 1) {
      return;
    }

    _updateSet(
      setIndex,
      (WorkoutSet set) => set.copyWith(loopCount: loopCount),
    );
  }

  Exercise? _getExercise(String exerciseId) {
    final Exercise? cachedExercise = _exercisesById[exerciseId];
    if (cachedExercise != null) {
      return cachedExercise;
    }

    final List<WorkoutPlan> plans =
        ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];
    final WorkoutPlan? plan =
        plans.where((WorkoutPlan p) => p.planId == widget.planId).firstOrNull;
    if (plan != null) {
      _cacheExercises(plan.exercises);
      final Exercise? exercise = plan.exercises
          .where((Exercise e) => e.exerciseId == exerciseId)
          .firstOrNull;
      if (exercise != null) {
        return exercise;
      }
    }
    return null;
  }

  Future<void> _saveWorkout() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout title.')),
      );
      return;
    }

    final List<WorkoutPlan> plans =
        ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];
    final WorkoutPlan? plan =
        plans.where((WorkoutPlan p) => p.planId == widget.planId).firstOrNull;

    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Parent plan not found.')),
      );
      return;
    }

    final Workout newWorkout = Workout(
      workoutId: widget.workoutId ?? const Uuid().v4(),
      title: title,
      imageUrl: optionalText(_imageUrlController.text),
      sets: _sets,
    );

    // Update the plan's workout list
    final List<Workout> updatedWorkouts = List<Workout>.from(plan.workouts);
    final int existingIndex = updatedWorkouts
        .indexWhere((Workout w) => w.workoutId == newWorkout.workoutId);

    if (existingIndex >= 0) {
      updatedWorkouts[existingIndex] = newWorkout;
    } else {
      updatedWorkouts.add(newWorkout);
    }

    final WorkoutPlan updatedPlan = plan.copyWith(
      exercises: _mergedExercises(plan),
      workouts: updatedWorkouts,
    );

    await ref
        .read(loadedWorkoutPlansNotifierProvider.notifier)
        .loadPlan(updatedPlan);

    if (mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  List<Exercise> _mergedExercises(WorkoutPlan plan) {
    final Map<String, Exercise> exercisesById = <String, Exercise>{
      for (final Exercise exercise in plan.exercises)
        exercise.exerciseId: exercise,
      ..._exercisesById,
    };
    return exercisesById.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.workoutId == null ? 'Create Workout' : 'Edit Workout'),
        actions: <Widget>[
          TextButton(
            onPressed: _saveWorkout,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Workout Title',
                hintText: 'e.g., Upper Body Focus',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            ImageOrGifUrlField(
              controller: _imageUrlController,
              hintText: 'https://example.com/workout.gif',
              onContentInserted: (KeyboardInsertedContent content) {
                unawaited(_handleWorkoutKeyboardMediaInserted(content));
              },
              onNativeKeyboardMediaInserted:
                  _handleWorkoutNativeKeyboardMediaInserted,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Sets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_sets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Text('Add at least one set to this workout.'),
                ),
              )
            else
              ..._sets.asMap().entries.map((MapEntry<int, WorkoutSet> entry) {
                final int setIndex = entry.key;
                final WorkoutSet set = entry.value;
                return SizedBox(
                  width: double.infinity,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  key:
                                      ValueKey<String>('set-name-${set.setId}'),
                                  initialValue: set.name ?? '',
                                  decoration: InputDecoration(
                                    labelText: 'Set Name',
                                    hintText: 'Set ${setIndex + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (String value) =>
                                      _updateSetName(setIndex, value),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey<String>(
                                      'set-loops-${set.setId}'),
                                  initialValue: set.loopCount.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Loops',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (String value) =>
                                      _updateSetLoopCount(setIndex, value),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeSet(setIndex),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (set.moves.isEmpty)
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: AppSpacing.md),
                              child: Text('No moves in this set yet.'),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              buildDefaultDragHandles: false,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: set.moves.length,
                              onReorder: (int oldIndex, int newIndex) =>
                                  _reorderMove(setIndex, oldIndex, newIndex),
                              itemBuilder:
                                  (BuildContext context, int moveIndex) {
                                final Move move = set.moves[moveIndex];
                                final Exercise? exercise =
                                    _getExercise(move.exerciseId);
                                final String exerciseName =
                                    exercise?.name ?? 'Unknown Exercise';

                                return _MoveRow(
                                  key: ValueKey<String>(move.moveId),
                                  index: moveIndex,
                                  exerciseName: exerciseName,
                                  imageUrl: optionalText(exercise?.imageUrl),
                                  moveSummary: _moveSummary(move),
                                  onTap: () =>
                                      _showEditMoveDialog(setIndex, moveIndex),
                                  onRemove: () =>
                                      _removeMove(setIndex, moveIndex),
                                );
                              },
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showAddMoveDialog(setIndex),
                                  icon: const Icon(Icons.add),
                                  label: const Text('New Move'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showExistingMovesPicker(setIndex),
                                  icon: const Icon(Icons.search),
                                  label: const Text('Existing'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _moveSummary(Move move) {
    if (move.type == MoveType.reps) {
      return '${move.repCount ?? 0} reps';
    }
    if (move.type == MoveType.stopwatch) {
      return 'Max time';
    }
    final int? bpm = move.metronomeSpeed;
    if (bpm == null) {
      return '${move.durationSeconds ?? 0} seconds';
    }
    return '${move.durationSeconds ?? 0} seconds - $bpm BPM';
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    super.key,
    required this.index,
    required this.exerciseName,
    required this.imageUrl,
    required this.moveSummary,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final String exerciseName;
  final String? imageUrl;
  final String moveSummary;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            onTap: onTap,
            child: Semantics(
              button: true,
              label: 'Edit $exerciseName',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double summaryWidth =
                        constraints.maxWidth >= 520 ? 176 : 112;

                    return Row(
                      children: <Widget>[
                        _ExerciseThumbnail(imageUrl: imageUrl),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            exerciseName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: summaryWidth,
                          child: Text(
                            moveSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove move',
                          icon: const Icon(Icons.close),
                          onPressed: onRemove,
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: SizedBox.square(
                            dimension: 40,
                            child: Icon(
                              Icons.drag_indicator,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: SizedBox.square(
          dimension: 52,
          child: imageUrl == null
              ? Icon(
                  Icons.fitness_center,
                  color: colorScheme.onSurfaceVariant,
                )
              : ExerciseMediaImage(
                  source: imageUrl!,
                  fit: BoxFit.cover,
                  errorPlaceholder: Icon(
                    Icons.fitness_center,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}
