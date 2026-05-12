import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
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
    setState(() {
      final WorkoutSet originalSet = _sets[setIndex];
      final List<Move> updatedMoves = List<Move>.from(originalSet.moves)
        ..removeAt(moveIndex);
      _sets[setIndex] = WorkoutSet(
        setId: originalSet.setId,
        name: originalSet.name,
        loopCount: originalSet.loopCount,
        restBetweenLoopsSeconds: originalSet.restBetweenLoopsSeconds,
        moves: updatedMoves,
      );
    });
  }

  void _showAddMoveDialog(int setIndex, {Exercise? initialExercise}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AddMoveDialog(
        initialExercise: initialExercise,
        onAdd: (Move move, Exercise newExercise) {
          _upsertExerciseInPlan(newExercise);
          setState(() {
            final WorkoutSet originalSet = _sets[setIndex];
            final List<Move> updatedMoves = List<Move>.from(originalSet.moves)
              ..add(move);
            _sets[setIndex] = WorkoutSet(
              setId: originalSet.setId,
              name: originalSet.name,
              loopCount: originalSet.loopCount,
              restBetweenLoopsSeconds: originalSet.restBetweenLoopsSeconds,
              moves: updatedMoves,
            );
          });
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
          setState(() {
            final WorkoutSet originalSet = _sets[setIndex];
            final List<Move> updatedMoves = List<Move>.from(originalSet.moves);
            updatedMoves[moveIndex] = updatedMove;
            _sets[setIndex] = WorkoutSet(
              setId: originalSet.setId,
              name: originalSet.name,
              loopCount: originalSet.loopCount,
              restBetweenLoopsSeconds: originalSet.restBetweenLoopsSeconds,
              moves: updatedMoves,
            );
          });
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
      final WorkoutPlan updatedPlan = WorkoutPlan(
        schemaVersion: plan.schemaVersion,
        planId: plan.planId,
        name: plan.name,
        description: plan.description,
        author: plan.author,
        imageUrl: plan.imageUrl,
        tags: plan.tags,
        exercises: updatedExercises,
        workouts: plan.workouts,
      );
      // We load it silently into memory so the UI can instantly find it.
      ref
          .read(loadedWorkoutPlansNotifierProvider.notifier)
          .loadPlan(updatedPlan);
    }
  }

  void _cacheExercises(List<Exercise> exercises) {
    _exercisesById.addEntries(
      exercises.map((Exercise exercise) =>
          MapEntry<String, Exercise>(exercise.exerciseId, exercise)),
    );
  }

  void _updateSetName(int setIndex, String value) {
    final WorkoutSet originalSet = _sets[setIndex];
    final String trimmed = value.trim();
    setState(() {
      _sets[setIndex] = WorkoutSet(
        setId: originalSet.setId,
        name: trimmed.isEmpty ? null : trimmed,
        loopCount: originalSet.loopCount,
        restBetweenLoopsSeconds: originalSet.restBetweenLoopsSeconds,
        moves: originalSet.moves,
      );
    });
  }

  void _updateSetLoopCount(int setIndex, String value) {
    final int? loopCount = int.tryParse(value);
    if (loopCount == null || loopCount < 1) {
      return;
    }

    final WorkoutSet originalSet = _sets[setIndex];
    setState(() {
      _sets[setIndex] = WorkoutSet(
        setId: originalSet.setId,
        name: originalSet.name,
        loopCount: loopCount,
        restBetweenLoopsSeconds: originalSet.restBetweenLoopsSeconds,
        moves: originalSet.moves,
      );
    });
  }

  String _getExerciseName(String exerciseId) {
    return _getExercise(exerciseId)?.name ?? 'Unknown Exercise';
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

    final WorkoutPlan updatedPlan = WorkoutPlan(
      schemaVersion: plan.schemaVersion,
      planId: plan.planId,
      name: plan.name,
      description: plan.description,
      author: plan.author,
      imageUrl: plan.imageUrl,
      tags: plan.tags,
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
                return Card(
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
                                key: ValueKey<String>('set-name-${set.setId}'),
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
                                key: ValueKey<String>('set-loops-${set.setId}'),
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
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: set.moves.length,
                            itemBuilder: (BuildContext context, int moveIndex) {
                              final Move move = set.moves[moveIndex];
                              final String exerciseName =
                                  _getExerciseName(move.exerciseId);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(exerciseName),
                                subtitle: Text(
                                  move.type == MoveType.reps
                                      ? '${move.repCount ?? 0} reps'
                                      : _durationMoveSummary(move),
                                ),
                                onTap: () =>
                                    _showEditMoveDialog(setIndex, moveIndex),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      tooltip: 'Edit move',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showEditMoveDialog(
                                          setIndex, moveIndex),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove move',
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          _removeMove(setIndex, moveIndex),
                                    ),
                                  ],
                                ),
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
                );
              }),
          ],
        ),
      ),
    );
  }

  String _durationMoveSummary(Move move) {
    final int? bpm = move.metronomeSpeed;
    if (bpm == null) {
      return '${move.durationSeconds ?? 0} seconds';
    }
    return '${move.durationSeconds ?? 0} seconds - $bpm BPM';
  }
}
