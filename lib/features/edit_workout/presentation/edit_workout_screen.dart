import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/add_move_dialog.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/existing_move_picker_dialog.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
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
  final Map<String, Move> _movesById = <String, Move>{};

  bool _isInit = true;

  WorkoutPlan? get _currentPlan {
    final List<WorkoutPlan> plans =
        ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];
    return plans
        .where((WorkoutPlan plan) => plan.planId == widget.planId)
        .firstOrNull;
  }

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

    final WorkoutPlan? plan = _currentPlan;

    if (plan != null) {
      _cacheMoves(plan.moves);
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
          lapCount: 1,
          restBetweenLapsSeconds: 0,
          moves: <WorkoutMove>[],
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
    _updateSetMoves(
        setIndex, (List<WorkoutMove> moves) => moves..removeAt(moveIndex));
  }

  void _updateMoveSetCount(int setIndex, int moveIndex, int setCount) {
    final int clampedSetCount = setCount.clamp(1, 99).toInt();
    _updateSetMoves(setIndex, (List<WorkoutMove> moves) {
      moves[moveIndex] = moves[moveIndex].copyWith(
        setCount: clampedSetCount,
      );
      return moves;
    });
  }

  void _reorderMove(int setIndex, int oldIndex, int newIndex) {
    _updateSetMoves(setIndex, (List<WorkoutMove> moves) {
      final int insertionIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
      final WorkoutMove moved = moves.removeAt(oldIndex);
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
    List<WorkoutMove> Function(List<WorkoutMove> moves) update,
  ) {
    _updateSet(setIndex, (WorkoutSet set) {
      return set.copyWith(moves: update(List<WorkoutMove>.from(set.moves)));
    });
  }

  void _showAddMoveDialog(int setIndex, {Move? initialMove}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AddMoveDialog(
        initialMove: initialMove,
        onAdd: (WorkoutMove workoutMove, Move newMove) {
          _upsertMoveInPlan(newMove);
          _updateSetMoves(
              setIndex, (List<WorkoutMove> moves) => moves..add(workoutMove));
        },
      ),
    );
  }

  void _showEditMoveDialog(int setIndex, int moveIndex) {
    final WorkoutMove workoutMove = _sets[setIndex].moves[moveIndex];
    final Move initialMove = _getMove(workoutMove.moveId) ??
        Move(moveId: workoutMove.moveId, name: 'Unknown Move');

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AddMoveDialog(
        initialWorkoutMove: workoutMove,
        initialMove: initialMove,
        onAdd: (WorkoutMove updatedWorkoutMove, Move updatedMove) {
          _upsertMoveInPlan(updatedMove);
          _updateSetMoves(
            setIndex,
            (List<WorkoutMove> moves) {
              moves[moveIndex] = updatedWorkoutMove;
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
    final List<WorkoutPlan> pickerPlans = _plansWithDraftWorkout(plans);

    final Move? selectedMove = await showDialog<Move>(
      context: context,
      builder: (BuildContext context) =>
          ExistingMovePickerDialog(plans: pickerPlans),
    );

    if (selectedMove != null && mounted) {
      _showAddMoveDialog(setIndex, initialMove: selectedMove);
    }
  }

  List<WorkoutPlan> _plansWithDraftWorkout(List<WorkoutPlan> plans) {
    final List<WorkoutPlan> pickerPlans = List<WorkoutPlan>.from(plans);
    final int planIndex = pickerPlans.indexWhere(
      (WorkoutPlan plan) => plan.planId == widget.planId,
    );
    if (planIndex == -1) {
      return pickerPlans;
    }

    final WorkoutPlan plan = pickerPlans[planIndex];
    final Workout draftWorkout = Workout(
      workoutId: widget.workoutId ?? '__draft-workout__',
      title: _titleController.text.trim().isEmpty
          ? 'Draft Workout'
          : _titleController.text.trim(),
      imageUrl: optionalText(_imageUrlController.text),
      sets: List<WorkoutSet>.from(_sets),
    );
    final List<Workout> workouts = List<Workout>.from(plan.workouts);
    final int workoutIndex = workouts.indexWhere(
      (Workout workout) => workout.workoutId == draftWorkout.workoutId,
    );
    if (workoutIndex >= 0) {
      workouts[workoutIndex] = draftWorkout;
    } else {
      workouts.add(draftWorkout);
    }
    pickerPlans[planIndex] = plan.copyWith(
      moves: _mergedMoves(plan),
      workouts: workouts,
    );
    return pickerPlans;
  }

  void _upsertMoveInPlan(Move move) {
    _movesById[move.moveId] = move;

    final WorkoutPlan? plan = _currentPlan;
    if (plan != null) {
      final List<Move> updatedMoves = List<Move>.from(plan.moves);
      final int existingIndex = updatedMoves.indexWhere(
        (Move e) => e.moveId == move.moveId,
      );
      if (existingIndex >= 0) {
        updatedMoves[existingIndex] = move;
      } else {
        updatedMoves.add(move);
      }
      final WorkoutPlan updatedPlan = plan.copyWith(moves: updatedMoves);
      // We load it silently into memory so the UI can instantly find it.
      ref
          .read(loadedWorkoutPlansNotifierProvider.notifier)
          .loadPlan(updatedPlan);
    }
  }

  void _cacheMoves(List<Move> moves) {
    _movesById.addEntries(
      moves.map((Move move) => MapEntry<String, Move>(move.moveId, move)),
    );
  }

  void _updateSetName(int setIndex, String value) {
    final String trimmed = value.trim();
    _updateSet(
      setIndex,
      (WorkoutSet set) => set.copyWith(name: trimmed.isEmpty ? null : trimmed),
    );
  }

  void _updateSetLapCount(int setIndex, int lapCount) {
    final int clampedLapCount = lapCount.clamp(1, 99).toInt();
    _updateSet(
      setIndex,
      (WorkoutSet set) => set.copyWith(lapCount: clampedLapCount),
    );
  }

  void _updateSetRestBetweenLapsSeconds(int setIndex, String value) {
    final int? seconds = int.tryParse(value);
    if (seconds == null) {
      return;
    }
    _updateSet(
      setIndex,
      (WorkoutSet set) => set.copyWith(
        restBetweenLapsSeconds: seconds.clamp(0, 3600).toInt(),
      ),
    );
  }

  Move? _getMove(String moveId) {
    final Move? cachedMove = _movesById[moveId];
    if (cachedMove != null) {
      return cachedMove;
    }

    final WorkoutPlan? plan = _currentPlan;
    if (plan != null) {
      _cacheMoves(plan.moves);
      final Move? move =
          plan.moves.where((Move e) => e.moveId == moveId).firstOrNull;
      if (move != null) {
        return move;
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

    final WorkoutPlan? plan = _currentPlan;

    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Parent plan not found.')),
      );
      return;
    }

    // Update the plan's workout list
    final List<Workout> updatedWorkouts = List<Workout>.from(plan.workouts);
    final int existingIndex = widget.workoutId == null
        ? -1
        : updatedWorkouts.indexWhere(
            (Workout workout) => workout.workoutId == widget.workoutId,
          );
    final Workout? existingWorkout =
        existingIndex < 0 ? null : updatedWorkouts[existingIndex];
    final Workout newWorkout = (existingWorkout ??
            Workout(
              workoutId: widget.workoutId ?? const Uuid().v4(),
              title: title,
              sets: const <WorkoutSet>[],
            ))
        .copyWith(
      title: title,
      imageUrl: optionalText(_imageUrlController.text),
      sets: _sets,
    );

    if (existingIndex >= 0) {
      updatedWorkouts[existingIndex] = newWorkout;
    } else {
      updatedWorkouts.add(newWorkout);
    }

    final WorkoutPlan updatedPlan = plan.copyWith(
      moves: _mergedMoves(plan),
      workouts: updatedWorkouts,
    );

    await ref
        .read(loadedWorkoutPlansNotifierProvider.notifier)
        .loadPlan(updatedPlan);

    if (mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  List<Move> _mergedMoves(WorkoutPlan plan) {
    final Map<String, Move> movesById = <String, Move>{
      for (final Move move in plan.moves) move.moveId: move,
      ..._movesById,
    };
    return movesById.values.toList(growable: false);
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
                              SizedBox(
                                width: 112,
                                child: _CountStepper(
                                  value: set.lapCount,
                                  singularLabel: 'lap',
                                  pluralLabel: 'laps',
                                  decreaseTooltip: 'Decrease laps',
                                  increaseTooltip: 'Increase laps',
                                  onChanged: (int lapCount) =>
                                      _updateSetLapCount(setIndex, lapCount),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeSet(setIndex),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 180,
                              child: TextFormField(
                                key: ValueKey<String>(
                                  'set-rest-between-laps-${set.setId}',
                                ),
                                initialValue:
                                    set.restBetweenLapsSeconds.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Rest Between Laps',
                                  suffixText: 'sec',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (String value) =>
                                    _updateSetRestBetweenLapsSeconds(
                                  setIndex,
                                  value,
                                ),
                              ),
                            ),
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
                                final WorkoutMove workoutMove =
                                    set.moves[moveIndex];
                                final Move? move = _getMove(workoutMove.moveId);
                                final String moveName =
                                    move?.name ?? 'Unknown Move';

                                return _MoveRow(
                                  key: ValueKey<String>(
                                      workoutMove.workoutMoveId),
                                  index: moveIndex,
                                  moveName: moveName,
                                  imageUrl: optionalText(move?.imageUrl),
                                  moveSummary: _moveSummary(workoutMove),
                                  setCount: workoutMove.setCount,
                                  onSetCountChanged: (int setCount) =>
                                      _updateMoveSetCount(
                                    setIndex,
                                    moveIndex,
                                    setCount,
                                  ),
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

  String _moveSummary(WorkoutMove move) {
    if (move.type == MoveType.reps) {
      return _withTargetWeight(
        _withEachSide('${move.repCount ?? 0} reps', move),
        move,
      );
    }
    if (move.type == MoveType.stopwatch) {
      return _withTargetWeight(_withEachSide('Max time', move), move);
    }
    final int? bpm = move.metronomeSpeed;
    final String durationSummary =
        _withEachSide('${move.durationSeconds ?? 0} seconds', move);
    final String? targetWeight = formatMoveTargetWeight(move);
    final String weightedSummary = targetWeight == null
        ? durationSummary
        : '$durationSummary, $targetWeight';
    if (bpm == null) {
      return weightedSummary;
    }
    return '$weightedSummary - $bpm BPM';
  }

  String _withTargetWeight(String summary, WorkoutMove move) {
    final String? targetWeight = formatMoveTargetWeight(move);
    if (targetWeight == null) {
      return summary;
    }
    return '$summary, $targetWeight';
  }

  String _withEachSide(String summary, WorkoutMove move) {
    return move.repeatEachSide ? '$summary / side' : summary;
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    super.key,
    required this.index,
    required this.moveName,
    required this.imageUrl,
    required this.moveSummary,
    required this.setCount,
    required this.onSetCountChanged,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final String moveName;
  final String? imageUrl;
  final String moveSummary;
  final int setCount;
  final ValueChanged<int> onSetCountChanged;
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
              label: 'Edit $moveName',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    MediaThumbnail(
                      imageUrl: imageUrl,
                      fallbackIcon: Icons.fitness_center,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      iconColor: colorScheme.onSurfaceVariant,
                      dimension: 52,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            moveName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            moveSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MoveSetCountControl(
                      setCount: setCount,
                      onChanged: onSetCountChanged,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveSetCountControl extends StatelessWidget {
  const _MoveSetCountControl({
    required this.setCount,
    required this.onChanged,
  });

  final int setCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CountStepper(
      value: setCount,
      singularLabel: 'set',
      pluralLabel: 'sets',
      decreaseTooltip: 'Decrease sets',
      increaseTooltip: 'Increase sets',
      onChanged: onChanged,
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.singularLabel,
    required this.pluralLabel,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onChanged,
  });

  final int value;
  final String singularLabel;
  final String pluralLabel;
  final String decreaseTooltip;
  final String increaseTooltip;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextStyle? labelStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.w800);

    return SizedBox(
      width: 112,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          SizedBox.square(
            dimension: 36,
            child: IconButton(
              tooltip: decreaseTooltip,
              icon: const Icon(Icons.remove),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
          ),
          SizedBox(
            width: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  value.toString(),
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  value == 1 ? singularLabel : pluralLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 36,
            child: IconButton(
              tooltip: increaseTooltip,
              icon: const Icon(Icons.add),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
              onPressed: value < 99 ? () => onChanged(value + 1) : null,
            ),
          ),
        ],
      ),
    );
  }
}
