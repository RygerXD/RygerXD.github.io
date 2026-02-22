import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/active_workout/application/rep_history_service.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _ticker;
  int _timerSeconds = 0;
  int _currentReps = 0;
  bool _isProcessing = false;
  bool _isExiting = false;
  String? _lastMoveKey;
  int? _lastRepsForCurrentMove;

  @override
  void initState() {
    super.initState();
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUiWithState(null, ref.read(activeWorkoutControllerProvider));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkoutState state = ref.watch(activeWorkoutControllerProvider);
    final ActiveWorkoutController controller = ref.read(activeWorkoutControllerProvider.notifier);
    final Workout? workout = controller.workout;
    final WorkoutSet? currentSet = controller.currentSet;
    final Move? currentMove = controller.currentMove;

    ref.listen<WorkoutState>(activeWorkoutControllerProvider, _syncUiWithState);

    if (workout == null || currentSet == null || currentMove == null || _isInactiveState(state)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _exitPlayer();
        }
      });
      return const Scaffold();
    }

    final List<WorkoutPlan>? plans = ref.watch(loadedWorkoutPlansNotifierProvider).valueOrNull;
    final WorkoutPlan? plan = _findPlanById(plans, controller.planId);
    final WorkoutPhase displayPhase = _displayPhase(state);
    final String moveLabel = _resolveMoveLabel(currentMove, plan);
    final Color statusColor = _statusColor(displayPhase);
    final String statusLabel = _statusLabel(displayPhase);
    final bool isPaused = state.phase == WorkoutPhase.paused;
    final bool isPrep = displayPhase == WorkoutPhase.prep;
    final bool isRest = displayPhase == WorkoutPhase.restBetweenLoops || displayPhase == WorkoutPhase.rest;
    final bool isMove = displayPhase == WorkoutPhase.move;

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        if (await _confirmExit() && mounted) {
                          _exitPlayer();
                        }
                      },
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          workout.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${state.moveIndex + 1} / ${currentSet.moves.length} - Loop ${state.loopIndex + 1}/${currentSet.loopCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      onPressed: _isProcessing
                          ? null
                          : () {
                              if (isPaused) {
                                controller.resume();
                              } else {
                                controller.pause();
                              }
                            },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _PhaseChip(label: statusLabel, color: statusColor),
                      const SizedBox(height: 24),
                      if (isPrep || isRest) ...<Widget>[
                        _TimerDisplay(seconds: _timerSeconds, color: statusColor),
                        const SizedBox(height: 16),
                        if (isPrep)
                          Text(
                            'Next: $moveLabel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                      ] else if (isMove) ...<Widget>[
                        Text(
                          moveLabel,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (currentMove.type == MoveType.duration)
                          _TimerDisplay(seconds: _timerSeconds, color: statusColor)
                        else
                          _AdjustableRepDisplay(
                            move: currentMove,
                            currentReps: _currentReps,
                            onRepsChanged: (int value) => setState(() => _currentReps = value),
                            lastReps: _lastRepsForCurrentMove,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: <Widget>[
                    if (isMove) ...<Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () => _runGuarded(() => controller.skipMove()),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('SKIP'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _completeCurrentMove,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('COMPLETE'),
                        ),
                      ),
                    ] else if (isRest)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _runGuarded(() {
                                  if (displayPhase == WorkoutPhase.restBetweenLoops) {
                                    controller.completeRestBetweenLoops();
                                  } else {
                                    controller.completeRest();
                                  }
                                }),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('SKIP REST'),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _runGuarded(() => controller.startPrepNow()),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('START NOW'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _isProcessing || _timerSeconds <= 0) {
        return;
      }

      final WorkoutState state = ref.read(activeWorkoutControllerProvider);
      if (state.phase == WorkoutPhase.paused || _isInactiveState(state)) {
        return;
      }

      setState(() {
        _timerSeconds -= 1;
      });

      if (_timerSeconds == 0) {
        await _onTimerComplete();
      }
    });
  }

  Future<void> _onTimerComplete() {
    final WorkoutState state = ref.read(activeWorkoutControllerProvider);
    final WorkoutPhase displayPhase = _displayPhase(state);
    final ActiveWorkoutController controller = ref.read(activeWorkoutControllerProvider.notifier);

    if (displayPhase == WorkoutPhase.prep) {
      return _runGuarded(() => controller.startPrepNow());
    }
    if (displayPhase == WorkoutPhase.restBetweenLoops) {
      return _runGuarded(() => controller.completeRestBetweenLoops());
    }
    if (displayPhase == WorkoutPhase.rest) {
      return _runGuarded(() => controller.completeRest());
    }
    if (displayPhase == WorkoutPhase.move && controller.currentMove?.type == MoveType.duration) {
      return _completeCurrentMove();
    }

    return Future<void>.value();
  }

  Future<void> _completeCurrentMove() {
    return _runGuarded(() async {
      final ActiveWorkoutController controller = ref.read(activeWorkoutControllerProvider.notifier);
      final WorkoutState state = ref.read(activeWorkoutControllerProvider);
      final Move? currentMove = controller.currentMove;
      final WorkoutSet? currentSet = controller.currentSet;
      final Workout? workout = controller.workout;
      if (currentMove == null) {
        return;
      }
      if (currentMove.type == MoveType.reps && currentSet != null && workout != null) {
        await ref.read(repHistoryServiceProvider).saveReps(
              workoutId: workout.workoutId,
              setId: currentSet.setId,
              loopIndex: state.loopIndex,
              exerciseId: currentMove.exerciseId,
              reps: _currentReps,
            );
        _lastRepsForCurrentMove = _currentReps;
      }
      controller.completeMove();
    });
  }

  Future<void> _runGuarded(FutureOr<void> Function() action) async {
    if (_isProcessing || !mounted) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _syncUiWithState(WorkoutState? previous, WorkoutState next) {
    if (!mounted) {
      return;
    }

    if (next.isTerminal) {
      _exitPlayer();
      return;
    }

    if (_isInactiveState(next)) {
      return;
    }

    final ActiveWorkoutController controller = ref.read(activeWorkoutControllerProvider.notifier);
    final Move? move = controller.currentMove;
    final WorkoutSet? set = controller.currentSet;
    if (move == null || set == null) {
      return;
    }

    final String moveKey = '${next.setIndex}:${next.loopIndex}:${next.moveIndex}:${move.moveId}';
    final bool moveChanged = moveKey != _lastMoveKey;
    final bool resumedFromPause = previous?.phase == WorkoutPhase.paused && next.phase != WorkoutPhase.paused;
    final bool phaseChanged = previous?.phase != next.phase;
    final bool positionChanged =
        previous == null ||
        previous.setIndex != next.setIndex ||
        previous.loopIndex != next.loopIndex ||
        previous.moveIndex != next.moveIndex;
    final bool shouldResetTimer =
        !resumedFromPause && next.phase != WorkoutPhase.paused && (previous == null || phaseChanged || positionChanged);

    int? nextTimer;
    if (shouldResetTimer) {
      nextTimer = _phaseStartSeconds(phase: next.phase, move: move, set: set);
    }

    if (!moveChanged && nextTimer == null) {
      return;
    }

    setState(() {
      if (moveChanged) {
        _lastMoveKey = moveKey;
        _currentReps = move.repCount ?? 0;
        _lastRepsForCurrentMove = null;
      }
      if (nextTimer != null) {
        _timerSeconds = nextTimer!;
      }
    });

    if (moveChanged && move.type == MoveType.reps) {
      _loadLastRepsForMove(
        moveKey: moveKey,
        state: next,
        move: move,
        set: set,
      );
    }
  }

  Future<void> _loadLastRepsForMove({
    required String moveKey,
    required WorkoutState state,
    required Move move,
    required WorkoutSet set,
  }) async {
    final Workout? workout = ref.read(activeWorkoutControllerProvider.notifier).workout;
    if (workout == null) {
      return;
    }

    final int? lastReps = await ref.read(repHistoryServiceProvider).getLastReps(
          workoutId: workout.workoutId,
          setId: set.setId,
          loopIndex: state.loopIndex,
          exerciseId: move.exerciseId,
        );

    if (!mounted || _lastMoveKey != moveKey) {
      return;
    }

    setState(() {
      _lastRepsForCurrentMove = lastReps;
      _currentReps = lastReps ?? (move.repCount ?? 0);
    });
  }

  int _phaseStartSeconds({
    required WorkoutPhase phase,
    required Move move,
    required WorkoutSet set,
  }) {
    if (phase == WorkoutPhase.prep) {
      return move.prepTimeSeconds;
    }
    if (phase == WorkoutPhase.move) {
      return move.type == MoveType.duration ? (move.durationSeconds ?? 0) : 0;
    }
    if (phase == WorkoutPhase.restBetweenLoops) {
      return set.restBetweenLoopsSeconds;
    }
    if (phase == WorkoutPhase.rest) {
      return set.restBetweenLoopsSeconds;
    }
    return _timerSeconds;
  }

  WorkoutPhase _displayPhase(WorkoutState state) {
    if (state.phase == WorkoutPhase.paused) {
      return state.pausedFrom ?? WorkoutPhase.move;
    }
    return state.phase;
  }

  bool _isInactiveState(WorkoutState state) {
    return state.phase == WorkoutPhase.idle;
  }

  WorkoutPlan? _findPlanById(List<WorkoutPlan>? plans, String? planId) {
    if (plans == null || planId == null) {
      return null;
    }
    for (final WorkoutPlan plan in plans) {
      if (plan.planId == planId) {
        return plan;
      }
    }
    return null;
  }

  String _resolveMoveLabel(Move move, WorkoutPlan? plan) {
    if (plan == null) {
      return move.exerciseId;
    }
    for (final Exercise exercise in plan.exercises) {
      if (exercise.exerciseId == move.exerciseId) {
        return exercise.name;
      }
    }
    return move.exerciseId;
  }

  Color _statusColor(WorkoutPhase phase) {
    if (phase == WorkoutPhase.prep) {
      return Colors.orange;
    }
    if (phase == WorkoutPhase.restBetweenLoops || phase == WorkoutPhase.rest) {
      return Colors.green;
    }
    return Colors.blue;
  }

  String _statusLabel(WorkoutPhase phase) {
    if (phase == WorkoutPhase.prep) {
      return 'Get Ready';
    }
    if (phase == WorkoutPhase.restBetweenLoops || phase == WorkoutPhase.rest) {
      return 'Rest';
    }
    return 'Go!';
  }

  Future<bool> _confirmExit() async {
    final bool? shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Abandon Workout?'),
        content: const Text('Progress for this workout session will be lost.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ABANDON'),
          ),
        ],
      ),
    );

    if (shouldAbandon == true) {
      ref.read(activeWorkoutControllerProvider.notifier).abandon();
      return true;
    }
    return false;
  }

  void _exitPlayer() {
    if (!mounted || _isExiting) {
      return;
    }
    _isExiting = true;

    final ActiveWorkoutController controller = ref.read(activeWorkoutControllerProvider.notifier);
    final String? planId = controller.planId;
    controller.clearActiveWorkout();

    if (context.canPop()) {
      context.pop();
      return;
    }

    if (planId != null) {
      context.go('/library/detail/$planId');
      return;
    }
    context.go('/library');
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({
    required this.seconds,
    required this.color,
  });

  final int seconds;
  final Color color;

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) {
      return '00:00';
    }
    final int minutes = totalSeconds ~/ 60;
    final int remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(seconds),
      style: TextStyle(
        fontSize: 120,
        fontWeight: FontWeight.bold,
        color: color,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

class _AdjustableRepDisplay extends StatelessWidget {
  const _AdjustableRepDisplay({
    required this.move,
    required this.currentReps,
    required this.onRepsChanged,
    this.lastReps,
  });

  final Move move;
  final int currentReps;
  final ValueChanged<int> onRepsChanged;
  final int? lastReps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          'ACTUAL REPS',
          style: TextStyle(color: Colors.grey, letterSpacing: 1.2, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _RepButton(
              label: '-10',
              icon: Icons.keyboard_double_arrow_left,
              onPressed: currentReps >= 10 ? () => onRepsChanged(currentReps - 10) : null,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _RepButton(
              label: '-1',
              icon: Icons.remove,
              onPressed: currentReps > 0 ? () => onRepsChanged(currentReps - 1) : null,
              color: Colors.blue,
            ),
            const SizedBox(width: 32),
            Column(
              children: <Widget>[
                Text(
                  currentReps.toString(),
                  style: const TextStyle(fontSize: 84, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  'Recommended: ${move.repCount ?? 0}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                if (lastReps != null)
                  Text(
                    'Last: $lastReps',
                    style: const TextStyle(color: Colors.orange, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(width: 32),
            _RepButton(
              label: '+1',
              icon: Icons.add,
              onPressed: () => onRepsChanged(currentReps + 1),
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _RepButton(
              label: '+10',
              icon: Icons.keyboard_double_arrow_right,
              onPressed: () => onRepsChanged(currentReps + 10),
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}

class _RepButton extends StatelessWidget {
  const _RepButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon, size: 32),
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.2),
            foregroundColor: color,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
