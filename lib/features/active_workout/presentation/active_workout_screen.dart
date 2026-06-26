import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_rep_counter.dart';
import 'package:workout_app_rewrite/features/active_workout/application/rep_history_service.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/active_workout/presentation/active_workout_controls.dart';
import 'package:workout_app_rewrite/features/active_workout/presentation/active_workout_helpers.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _metronomeTimer;
  int _timerSeconds = 0;
  DateTime? _countdownEndsAt;
  int _currentReps = 0;
  double _currentWeight = 0;
  bool _isProcessing = false;
  bool _isExiting = false;
  bool _playedTerminalCue = false;
  String? _lastMoveKey;
  String? _activeMetronomeKey;
  String? _lastGetReadyCountdownKey;
  String? _lastMoveHalfwayKey;
  int? _lastRepsForCurrentMove;
  double? _lastWeightForCurrentMove;
  int? _lastDurationForCurrentMove;
  final Stopwatch _moveStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WorkoutAudio.preloadBuiltInSounds(
      ref.read(appSettingsProvider).soundSelections.values,
    ));
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUiWithState(null, ref.read(activeWorkoutControllerProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopMetronome();
    _moveStopwatch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_tickTimer());
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkoutState state = ref.watch(activeWorkoutControllerProvider);
    final ActiveWorkoutController controller =
        ref.read(activeWorkoutControllerProvider.notifier);
    final Workout? workout = controller.workout;
    final WorkoutSet? currentSet = controller.currentSet;
    final WorkoutMove? currentWorkoutMove = controller.currentMove;

    ref.listen<WorkoutState>(activeWorkoutControllerProvider, _syncUiWithState);

    if (workout == null ||
        currentSet == null ||
        currentWorkoutMove == null ||
        isInactiveWorkoutState(state)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _exitPlayer();
        }
      });
      return const Scaffold();
    }

    final List<WorkoutPlan>? plans =
        ref.watch(loadedWorkoutPlansNotifierProvider).valueOrNull;
    final WorkoutPlan? plan = findWorkoutPlanById(plans, controller.planId);
    final WorkoutPhase displayPhase = displayWorkoutPhase(state);
    final Move? currentMove = resolveWorkoutMove(currentWorkoutMove, plan);
    final String moveLabel = moveDisplayLabel(
      currentMove?.name ?? currentWorkoutMove.moveId,
      currentWorkoutMove,
    );
    final String setLabel =
        optionalText(currentSet.name) ?? 'Block ${state.setIndex + 1}';
    final String? moveMediaUrl = optionalText(currentMove?.imageUrl);
    final WorkoutMove? nextWorkoutMoveDuringRest = nextMoveDuringRestPhase(
      phase: displayPhase,
      state: state,
      workout: workout,
    );
    final Move? nextMoveDuringRest = nextWorkoutMoveDuringRest == null
        ? null
        : resolveWorkoutMove(nextWorkoutMoveDuringRest, plan);
    final String? nextMoveLabelDuringRest = nextWorkoutMoveDuringRest == null
        ? null
        : moveDisplayLabel(
            nextMoveDuringRest?.name ?? nextWorkoutMoveDuringRest.moveId,
            nextWorkoutMoveDuringRest,
          );
    final String? nextMoveMediaUrlDuringRest =
        optionalText(nextMoveDuringRest?.imageUrl);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color statusColor = activeWorkoutPhaseColor(displayPhase, colors);
    final String statusLabel = activeWorkoutPhaseLabel(displayPhase);
    final bool isPaused = state.phase == WorkoutPhase.paused;
    final bool isPrep = displayPhase == WorkoutPhase.prep;
    final bool isRest = displayPhase == WorkoutPhase.restBetweenLaps ||
        displayPhase == WorkoutPhase.rest;
    final bool isMove = displayPhase == WorkoutPhase.move;
    final bool hasTrackedWeight = currentWorkoutMove.targetWeight != null &&
        currentWorkoutMove.targetWeightUnit != null;
    final int movePosition = workoutMovePosition(workout, state);
    final int moveTotal = workoutMoveTotal(workout);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          await _confirmAndExit();
        }
      },
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
                      tooltip: 'End workout',
                      icon: const Icon(Icons.close),
                      onPressed: _confirmAndExit,
                    ),
                    Expanded(
                        child: Column(
                      children: <Widget>[
                        Text(
                          workout.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$setLabel - Lap ${state.lapIndex + 1} of ${currentSet.lapCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Move $movePosition of $moveTotal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )),
                    IconButton(
                      tooltip: isPaused ? 'Resume workout' : 'Pause workout',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Semantics(
                  label: 'Workout progress, move $movePosition of $moveTotal',
                  child: LinearProgressIndicator(
                    value: moveTotal == 0 ? 0 : movePosition / moveTotal,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double minHeight = constraints.maxHeight.isFinite
                        ? (constraints.maxHeight - 24)
                            .clamp(0.0, constraints.maxHeight)
                            .toDouble()
                        : 0;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ActivePhaseChip(
                                  label: statusLabel, color: statusColor),
                              const SizedBox(height: 24),
                              if (isPrep || isRest) ...<Widget>[
                                if ((isPrep
                                        ? moveMediaUrl
                                        : nextMoveMediaUrlDuringRest) !=
                                    null) ...<Widget>[
                                  ActiveMoveMedia(
                                    url: isPrep
                                        ? moveMediaUrl!
                                        : nextMoveMediaUrlDuringRest!,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                ActiveTimerDisplay(
                                    seconds: _timerSeconds, color: statusColor),
                                const SizedBox(height: 16),
                                if (isPrep)
                                  Text(
                                    'Next: $moveLabel',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  )
                                else if (nextMoveLabelDuringRest != null)
                                  Text(
                                    'Next: $nextMoveLabelDuringRest',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                              ] else if (isMove) ...<Widget>[
                                if (moveMediaUrl != null) ...<Widget>[
                                  ActiveMoveMedia(url: moveMediaUrl),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  moveLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (currentWorkoutMove.type ==
                                    MoveType.duration) ...<Widget>[
                                  ActiveTimerDisplay(
                                      seconds: _timerSeconds,
                                      color: statusColor),
                                  if (currentWorkoutMove.metronomeSpeed !=
                                      null) ...<Widget>[
                                    const SizedBox(height: 8),
                                    ActiveMetronomeSummary(
                                      bpm: currentWorkoutMove.metronomeSpeed!,
                                      estimatedReps:
                                          metronomeRepsForElapsedTime(
                                                move: currentWorkoutMove,
                                                elapsedSeconds:
                                                    effectiveMoveDurationSeconds(
                                                  currentWorkoutMove,
                                                ),
                                              ) ??
                                              0,
                                    ),
                                  ],
                                  if (hasTrackedWeight) ...<Widget>[
                                    ..._weightControls(
                                      currentWorkoutMove,
                                      topPadding: 16,
                                    ),
                                  ],
                                ] else if (currentWorkoutMove.type ==
                                    MoveType.stopwatch)
                                  Column(
                                    children: <Widget>[
                                      ActiveStopwatchDisplay(
                                        move: currentWorkoutMove,
                                        seconds: _timerSeconds,
                                        color: statusColor,
                                        lastDuration:
                                            _lastDurationForCurrentMove,
                                      ),
                                      if (hasTrackedWeight) ...<Widget>[
                                        ..._weightControls(
                                          currentWorkoutMove,
                                          topPadding: 18,
                                        ),
                                      ],
                                    ],
                                  )
                                else
                                  Column(
                                    children: <Widget>[
                                      ActiveAdjustableRepDisplay(
                                        move: currentWorkoutMove,
                                        currentReps: _currentReps,
                                        onRepsChanged: (int value) => setState(
                                            () => _currentReps = value),
                                        lastReps: _lastRepsForCurrentMove,
                                      ),
                                      if (hasTrackedWeight) ...<Widget>[
                                        ..._weightControls(
                                          currentWorkoutMove,
                                          topPadding: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                if (nextMoveLabelDuringRest !=
                                    null) ...<Widget>[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Next: $nextMoveLabelDuringRest',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: <Widget>[
                    if (isMove) ...<Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _runGuarded(() => controller.skipMove()),
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('SKIP'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _primaryActionButton(
                          label: 'COMPLETE',
                          color: colors.primary,
                          onPressed: _completeCurrentMove,
                        ),
                      ),
                    ] else if (isRest)
                      Expanded(
                        child: _primaryActionButton(
                          label: displayPhase == WorkoutPhase.rest
                              ? 'SKIP COOLDOWN'
                              : 'SKIP REST',
                          color: colors.tertiary,
                          onPressed: () => _runGuarded(() {
                            if (displayPhase == WorkoutPhase.restBetweenLaps) {
                              controller.completeRestBetweenLaps();
                            } else {
                              controller.completeRest();
                            }
                          }),
                        ),
                      )
                    else
                      Expanded(
                        child: _primaryActionButton(
                          label: 'START NOW',
                          color: colors.secondary,
                          onPressed: () =>
                              _runGuarded(() => controller.startPrepNow()),
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

  void _setCurrentWeight(double value) {
    setState(() => _currentWeight = value.clamp(0, 9999).toDouble());
  }

  List<Widget> _weightControls(WorkoutMove move, {required double topPadding}) {
    return <Widget>[
      SizedBox(height: topPadding),
      ActiveAdjustableWeightDisplay(
        move: move,
        currentWeight: _currentWeight,
        onWeightChanged: _setCurrentWeight,
        lastWeight: _lastWeightForCurrentMove,
      ),
    ];
  }

  Widget _primaryActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Future<void> _confirmAndExit() async {
    final ActiveWorkoutController controller =
        ref.read(activeWorkoutControllerProvider.notifier);
    final WorkoutState state = ref.read(activeWorkoutControllerProvider);
    final bool pausedForDialog =
        !isInactiveWorkoutState(state) && state.phase != WorkoutPhase.paused;
    if (pausedForDialog) {
      controller.pause();
    }

    final _WorkoutExitAction? action = await _chooseExitAction();
    if (action == null || !mounted) {
      if (pausedForDialog) {
        controller.resume();
      }
      return;
    }
    if (action == _WorkoutExitAction.end) {
      await _saveEarlyExitMovePerformances(state);
      controller.endWorkout();
    } else {
      await controller.cancelWorkout();
    }
    if (mounted) _exitPlayer();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_tickTimer()),
    );
  }

  Future<void> _tickTimer() async {
    if (!mounted || _isProcessing) {
      return;
    }

    final WorkoutState state = ref.read(activeWorkoutControllerProvider);
    if (state.phase == WorkoutPhase.paused || isInactiveWorkoutState(state)) {
      return;
    }

    final WorkoutMove? currentMove =
        ref.read(activeWorkoutControllerProvider.notifier).currentMove;
    if (currentMove == null) {
      return;
    }

    if (displayWorkoutPhase(state) == WorkoutPhase.move &&
        currentMove.type == MoveType.stopwatch) {
      final int elapsedSeconds = _elapsedSecondsForMove(currentMove);
      if (elapsedSeconds != _timerSeconds) {
        setState(() {
          _timerSeconds = elapsedSeconds;
        });
      }
      return;
    }

    if (!_usesCountdownTimer(state, currentMove) || _countdownEndsAt == null) {
      return;
    }

    final int nextSeconds = _remainingCountdownSeconds();
    if (nextSeconds != _timerSeconds) {
      setState(() {
        _timerSeconds = nextSeconds;
      });
    }

    if (nextSeconds > 0) {
      _playGetReadyCountdownCueIfNeeded(state, nextSeconds);
      _playMoveHalfwayCueIfNeeded(state, currentMove, nextSeconds);
      return;
    }

    await _onTimerComplete();
  }

  Future<void> _onTimerComplete() async {
    _stopMetronome();

    final WorkoutState state = ref.read(activeWorkoutControllerProvider);
    final WorkoutPhase displayPhase = displayWorkoutPhase(state);
    final ActiveWorkoutController controller =
        ref.read(activeWorkoutControllerProvider.notifier);

    if (displayPhase == WorkoutPhase.prep) {
      await _playGetReadyDing();
      return _runGuarded(() => controller.startPrepNow());
    }

    if (displayPhase == WorkoutPhase.move &&
        controller.currentMove?.type == MoveType.duration) {
      return _completeCurrentMove();
    }

    if (displayPhase == WorkoutPhase.restBetweenLaps) {
      return _runGuarded(() => controller.completeRestBetweenLaps());
    }
    if (displayPhase == WorkoutPhase.rest) {
      return _runGuarded(() => controller.completeRest());
    }

    return Future<void>.value();
  }

  Future<void> _playConfiguredWorkoutAudio(
    Future<void> Function(AppSettings settings) play,
  ) async {
    final AppSettings settings = ref.read(appSettingsProvider);
    if (!settings.audioCuesEnabled) {
      return;
    }
    await play(settings);
  }

  Future<void> _playGetReadyDing() =>
      _playConfiguredWorkoutAudio((AppSettings settings) {
        if (!settings.getReadyDingEnabled) {
          return Future<void>.value();
        }
        return WorkoutAudio.playSharedSound(
          sound: settings.soundFor(WorkoutSoundCue.getReadyDing),
          customSound: settings.getReadyDingCustomSound,
          volume: settings.audioVolume,
        );
      });

  Future<void> _playGetReadyCountdownCue() =>
      _playConfiguredWorkoutAudio((AppSettings settings) {
        if (!settings.getReadyCountdownEnabled) {
          return Future<void>.value();
        }
        return WorkoutAudio.playSharedSound(
          sound: settings.soundFor(WorkoutSoundCue.getReadyCountdown),
          customSound: settings.getReadyCountdownCustomSound,
          volume: settings.audioVolume,
        );
      });

  Future<void> _playMoveFinishedDing() =>
      _playConfiguredWorkoutAudio((AppSettings settings) {
        if (!settings.moveFinishedDingEnabled) {
          return Future<void>.value();
        }
        return WorkoutAudio.playSharedSound(
          sound: settings.soundFor(WorkoutSoundCue.moveFinished),
          customSound: settings.moveFinishedDingCustomSound,
          volume: settings.audioVolume,
        );
      });

  Future<void> _playMoveHalfway() =>
      _playConfiguredWorkoutAudio((AppSettings settings) {
        if (!settings.moveHalfwayEnabled) return Future<void>.value();
        return WorkoutAudio.playSharedSound(
          sound: settings.soundFor(WorkoutSoundCue.moveHalfway),
          customSound: settings.moveHalfwayCustomSound,
          volume: settings.audioVolume,
        );
      });

  Future<void> _playMetronomeTick() =>
      _playConfiguredWorkoutAudio((AppSettings settings) {
        if (!settings.metronomeClickEnabled) {
          return Future<void>.value();
        }
        return WorkoutAudio.playSharedSound(
          sound: settings.soundFor(WorkoutSoundCue.metronome),
          customSound: settings.metronomeClickCustomSound,
          volume: settings.audioVolume,
        );
      });

  Future<void> _completeCurrentMove() {
    return _runGuarded(() async {
      final ActiveWorkoutController controller =
          ref.read(activeWorkoutControllerProvider.notifier);
      final WorkoutState state = ref.read(activeWorkoutControllerProvider);
      final WorkoutMove? currentMove = controller.currentMove;
      final WorkoutSet? currentSet = controller.currentSet;
      final Workout? workout = controller.workout;
      final String? sessionId = controller.sessionId;
      if (currentMove == null) {
        return;
      }
      if (!controller.isFinalMove) {
        await _playMoveFinishedDing();
      }
      if (currentSet != null && workout != null) {
        await _saveCurrentMoveProgress(
          state: state,
          workout: workout,
          set: currentSet,
          move: currentMove,
          sessionId: sessionId,
          completedAt: DateTime.now(),
        );
      }
      controller.completeMove();
    });
  }

  Future<void> _saveCurrentMoveProgress({
    required WorkoutState state,
    required Workout workout,
    required WorkoutSet set,
    required WorkoutMove move,
    required String? sessionId,
    required DateTime completedAt,
  }) async {
    final int elapsedSeconds = _elapsedSecondsForMove(move);
    final int? metronomeReps = metronomeRepsForElapsedTime(
      move: move,
      elapsedSeconds: elapsedSeconds,
    );
    final int? repsToSave =
        move.type == MoveType.reps ? _currentReps : metronomeReps;
    final bool tracksDuration = move.type == MoveType.stopwatch;
    final WeightUnit? weightUnit = move.targetWeightUnit;
    final bool hasTrackedWeight =
        move.targetWeight != null && weightUnit != null;

    if (repsToSave != null) {
      await ref.read(repHistoryServiceProvider).saveReps(
            workoutId: workout.workoutId,
            setId: set.setId,
            lapIndex: state.lapIndex,
            moveId: move.moveId,
            reps: repsToSave,
          );
      _lastRepsForCurrentMove = repsToSave;
    }
    if (tracksDuration) {
      await ref.read(repHistoryServiceProvider).saveDuration(
            workoutId: workout.workoutId,
            setId: set.setId,
            lapIndex: state.lapIndex,
            moveId: move.moveId,
            seconds: elapsedSeconds,
          );
      _lastDurationForCurrentMove = elapsedSeconds;
    }
    if (hasTrackedWeight) {
      await ref.read(repHistoryServiceProvider).saveWeight(
            workoutId: workout.workoutId,
            setId: set.setId,
            lapIndex: state.lapIndex,
            moveId: move.moveId,
            weightUnit: weightUnit.name,
            weight: _currentWeight,
          );
      _lastWeightForCurrentMove = _currentWeight;
    }
    if (sessionId == null) {
      return;
    }

    await ref.read(historyServiceProvider).saveMovePerformance(
          sessionId: sessionId,
          workoutId: workout.workoutId,
          setId: set.setId,
          lapIndex: state.lapIndex,
          workoutMoveId: move.workoutMoveId,
          moveId: move.moveId,
          repCount: repsToSave ?? 0,
          actualWeight: hasTrackedWeight ? _currentWeight : null,
          actualWeightUnit: hasTrackedWeight ? weightUnit.name : null,
          elapsedSeconds: elapsedSeconds,
          completedAt: completedAt,
        );
  }

  Future<void> _saveEarlyExitMovePerformances(WorkoutState exitState) async {
    final ActiveWorkoutController controller =
        ref.read(activeWorkoutControllerProvider.notifier);
    final Workout? workout = controller.workout;
    final String? sessionId = controller.sessionId;
    if (workout == null || sessionId == null) {
      return;
    }

    final WorkoutPhase phase = displayWorkoutPhase(exitState);
    final DateTime completedAt = DateTime.now();
    if (phase == WorkoutPhase.move) {
      final _MoveSlot? currentSlot = _normalizeMoveSlot(
        workout,
        setIndex: exitState.setIndex,
        lapIndex: exitState.lapIndex,
        moveIndex: exitState.moveIndex,
      );
      if (currentSlot != null) {
        await _saveCurrentMoveProgress(
          state: exitState,
          workout: workout,
          set: currentSlot.set,
          move: currentSlot.move,
          sessionId: sessionId,
          completedAt: completedAt,
        );
      }
    }

    final _MoveSlot? firstSkippedSlot = _firstSkippedMoveSlot(
      workout,
      state: exitState,
      phase: phase,
    );
    if (firstSkippedSlot == null) {
      return;
    }

    for (final _MoveSlot slot in _moveSlotsFrom(
      workout,
      startSetIndex: firstSkippedSlot.setIndex,
      startLapIndex: firstSkippedSlot.lapIndex,
      startMoveIndex: firstSkippedSlot.moveIndex,
    )) {
      await ref.read(historyServiceProvider).saveMovePerformance(
            sessionId: sessionId,
            workoutId: workout.workoutId,
            setId: slot.set.setId,
            lapIndex: slot.lapIndex,
            workoutMoveId: slot.move.workoutMoveId,
            moveId: slot.move.moveId,
            repCount: 0,
            elapsedSeconds: 0,
            completedAt: completedAt,
          );
    }
  }

  _MoveSlot? _firstSkippedMoveSlot(
    Workout workout, {
    required WorkoutState state,
    required WorkoutPhase phase,
  }) {
    int moveIndex = state.moveIndex;
    if (phase == WorkoutPhase.move || phase == WorkoutPhase.rest) {
      moveIndex += 1;
    }
    return _normalizeMoveSlot(
      workout,
      setIndex: state.setIndex,
      lapIndex: state.lapIndex,
      moveIndex: moveIndex,
    );
  }

  Iterable<_MoveSlot> _moveSlotsFrom(
    Workout workout, {
    required int startSetIndex,
    required int startLapIndex,
    required int startMoveIndex,
  }) sync* {
    for (int setIndex = startSetIndex;
        setIndex < workout.sets.length;
        setIndex += 1) {
      final WorkoutSet set = workout.sets[setIndex];
      final int firstLap = setIndex == startSetIndex ? startLapIndex : 0;
      for (int lapIndex = firstLap; lapIndex < set.lapCount; lapIndex += 1) {
        final int firstMove = setIndex == startSetIndex && lapIndex == firstLap
            ? startMoveIndex
            : 0;
        for (int moveIndex = firstMove;
            moveIndex < set.moves.length;
            moveIndex += 1) {
          yield _MoveSlot(
            setIndex: setIndex,
            lapIndex: lapIndex,
            moveIndex: moveIndex,
            set: set,
            move: set.moves[moveIndex],
          );
        }
      }
    }
  }

  _MoveSlot? _normalizeMoveSlot(
    Workout workout, {
    required int setIndex,
    required int lapIndex,
    required int moveIndex,
  }) {
    int normalizedSetIndex = setIndex;
    int normalizedLapIndex = lapIndex;
    int normalizedMoveIndex = moveIndex;

    while (normalizedSetIndex < workout.sets.length) {
      final WorkoutSet set = workout.sets[normalizedSetIndex];
      if (normalizedLapIndex >= set.lapCount) {
        normalizedSetIndex += 1;
        normalizedLapIndex = 0;
        normalizedMoveIndex = 0;
        continue;
      }
      if (normalizedMoveIndex >= set.moves.length) {
        normalizedLapIndex += 1;
        normalizedMoveIndex = 0;
        continue;
      }
      if (normalizedLapIndex < 0 || normalizedMoveIndex < 0) {
        return null;
      }
      return _MoveSlot(
        setIndex: normalizedSetIndex,
        lapIndex: normalizedLapIndex,
        moveIndex: normalizedMoveIndex,
        set: set,
        move: set.moves[normalizedMoveIndex],
      );
    }
    return null;
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
      _playTerminalCue(next.phase);
      _exitPlayer();
      return;
    }

    if (isInactiveWorkoutState(next)) {
      return;
    }

    final ActiveWorkoutController controller =
        ref.read(activeWorkoutControllerProvider.notifier);
    final WorkoutMove? move = controller.currentMove;
    final WorkoutSet? set = controller.currentSet;
    if (move == null || set == null) {
      return;
    }

    final String moveKey =
        '${next.setIndex}:${next.lapIndex}:${next.moveIndex}:${move.moveId}';
    final bool moveChanged = moveKey != _lastMoveKey;
    final bool resumedFromPause = previous?.phase == WorkoutPhase.paused &&
        next.phase != WorkoutPhase.paused;
    final bool phaseChanged = previous?.phase != next.phase;
    final bool positionChanged = previous == null ||
        previous.setIndex != next.setIndex ||
        previous.lapIndex != next.lapIndex ||
        previous.moveIndex != next.moveIndex;
    final bool shouldResetTimer = !resumedFromPause &&
        next.phase != WorkoutPhase.paused &&
        (previous == null || phaseChanged || positionChanged);

    int? nextTimer;
    if (shouldResetTimer) {
      nextTimer = _phaseStartSeconds(phase: next.phase, move: move, set: set);
    }

    _syncMetronomeWithState(next, move: move);
    _syncMoveStopwatch(next, moveChanged: moveChanged);
    final bool shouldStartCountdownClock =
        resumedFromPause && _usesCountdownTimer(next, move);
    if (next.phase == WorkoutPhase.paused) {
      _countdownEndsAt = null;
    }

    if (!moveChanged && nextTimer == null && !shouldStartCountdownClock) {
      return;
    }

    setState(() {
      if (moveChanged) {
        _lastMoveKey = moveKey;
        _lastGetReadyCountdownKey = null;
        _lastMoveHalfwayKey = null;
        _currentReps = move.repCount ?? 0;
        _currentWeight = move.targetWeight ?? 0;
        _lastRepsForCurrentMove = null;
        _lastWeightForCurrentMove = null;
        _lastDurationForCurrentMove = null;
      }
      if (nextTimer != null) {
        _timerSeconds = nextTimer;
      }
    });

    if (nextTimer != null || shouldStartCountdownClock) {
      _syncCountdownClock(next, move);
    }

    if (nextTimer != null) {
      _playGetReadyCountdownCueIfNeeded(next, nextTimer);
      if (next.phase == WorkoutPhase.prep && nextTimer == 0) {
        final int transitionCount = next.transitionCount;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final WorkoutState current =
              ref.read(activeWorkoutControllerProvider);
          if (current.phase == WorkoutPhase.prep &&
              current.transitionCount == transitionCount) {
            ref.read(activeWorkoutControllerProvider.notifier).startPrepNow();
          }
        });
      }
    }

    if (moveChanged && move.type == MoveType.reps) {
      _loadLastRepsForMove(
        moveKey: moveKey,
        state: next,
        move: move,
        set: set,
      );
    }
    if (moveChanged && move.type == MoveType.stopwatch) {
      _loadLastDurationForMove(
        moveKey: moveKey,
        state: next,
        move: move,
        set: set,
      );
    }
    if (moveChanged &&
        move.targetWeight != null &&
        move.targetWeightUnit != null) {
      _loadLastWeightForMove(
        moveKey: moveKey,
        state: next,
        move: move,
        set: set,
      );
    }
  }

  void _playTerminalCue(WorkoutPhase phase) {
    if (_playedTerminalCue ||
        (phase != WorkoutPhase.completed &&
            phase != WorkoutPhase.completedEarly)) {
      return;
    }
    _playedTerminalCue = true;

    unawaited(_playConfiguredWorkoutAudio((AppSettings settings) {
      final bool enabled = phase == WorkoutPhase.completed
          ? settings.workoutCompleteEnabled
          : settings.workoutEndedEarlyEnabled;
      if (!enabled) {
        return Future<void>.value();
      }
      return WorkoutAudio.playSharedSound(
        sound: settings.soundFor(phase == WorkoutPhase.completed
            ? WorkoutSoundCue.workoutComplete
            : WorkoutSoundCue.workoutEndedEarly),
        customSound: phase == WorkoutPhase.completed
            ? settings.workoutCompleteCustomSound
            : settings.workoutEndedEarlyCustomSound,
        volume: settings.audioVolume,
      );
    }));
  }

  Future<void> _loadLastRepsForMove({
    required String moveKey,
    required WorkoutState state,
    required WorkoutMove move,
    required WorkoutSet set,
  }) async {
    await _loadLastTrackedValueForMove<int>(
      moveKey: moveKey,
      loadValue: (Workout workout) {
        return ref.read(repHistoryServiceProvider).getLastReps(
              workoutId: workout.workoutId,
              setId: set.setId,
              lapIndex: state.lapIndex,
              moveId: move.moveId,
            );
      },
      applyValue: (int? lastReps) {
        _lastRepsForCurrentMove = lastReps;
        _currentReps = lastReps ?? (move.repCount ?? 0);
      },
    );
  }

  Future<void> _loadLastWeightForMove({
    required String moveKey,
    required WorkoutState state,
    required WorkoutMove move,
    required WorkoutSet set,
  }) async {
    final WeightUnit? unit = move.targetWeightUnit;
    if (unit == null) {
      return;
    }

    await _loadLastTrackedValueForMove<double>(
      moveKey: moveKey,
      loadValue: (Workout workout) {
        return ref.read(repHistoryServiceProvider).getLastWeight(
              workoutId: workout.workoutId,
              setId: set.setId,
              lapIndex: state.lapIndex,
              moveId: move.moveId,
              weightUnit: unit.name,
            );
      },
      applyValue: (double? lastWeight) {
        _lastWeightForCurrentMove = lastWeight;
        _currentWeight = lastWeight ?? (move.targetWeight ?? 0);
      },
    );
  }

  Future<void> _loadLastDurationForMove({
    required String moveKey,
    required WorkoutState state,
    required WorkoutMove move,
    required WorkoutSet set,
  }) async {
    await _loadLastTrackedValueForMove<int>(
      moveKey: moveKey,
      loadValue: (Workout workout) {
        return ref.read(repHistoryServiceProvider).getLastDuration(
              workoutId: workout.workoutId,
              setId: set.setId,
              lapIndex: state.lapIndex,
              moveId: move.moveId,
            );
      },
      applyValue: (int? lastDuration) {
        _lastDurationForCurrentMove = lastDuration;
      },
    );
  }

  Future<void> _loadLastTrackedValueForMove<T>({
    required String moveKey,
    required Future<T?> Function(Workout workout) loadValue,
    required void Function(T? value) applyValue,
  }) async {
    final Workout? workout =
        ref.read(activeWorkoutControllerProvider.notifier).workout;
    if (workout == null) {
      return;
    }

    final T? value = await loadValue(workout);

    if (!mounted || _lastMoveKey != moveKey) {
      return;
    }

    setState(() {
      applyValue(value);
    });
  }

  int _phaseStartSeconds({
    required WorkoutPhase phase,
    required WorkoutMove move,
    required WorkoutSet set,
  }) {
    if (phase == WorkoutPhase.prep) {
      return move.prepTimeSeconds;
    }
    if (phase == WorkoutPhase.move) {
      return effectiveMoveDurationSeconds(move);
    }
    if (phase == WorkoutPhase.restBetweenLaps) {
      return set.restBetweenLapsSeconds;
    }
    if (phase == WorkoutPhase.rest) {
      return move.finishTimeSeconds;
    }
    return _timerSeconds;
  }

  int _elapsedSecondsForMove(WorkoutMove move) {
    final int durationSeconds = effectiveMoveDurationSeconds(move);
    if (move.type != MoveType.duration || durationSeconds <= 0) {
      return _moveStopwatch.elapsed.inSeconds;
    }
    return (durationSeconds - _timerSeconds).clamp(0, durationSeconds);
  }

  bool _usesCountdownTimer(WorkoutState state, WorkoutMove move) {
    final WorkoutPhase phase = displayWorkoutPhase(state);
    return phase == WorkoutPhase.prep ||
        phase == WorkoutPhase.rest ||
        phase == WorkoutPhase.restBetweenLaps ||
        (phase == WorkoutPhase.move && move.type == MoveType.duration);
  }

  int _remainingCountdownSeconds() {
    final DateTime? endsAt = _countdownEndsAt;
    if (endsAt == null) {
      return _timerSeconds;
    }
    final int milliseconds = endsAt.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) {
      return 0;
    }
    return (milliseconds + 999) ~/ 1000;
  }

  void _syncCountdownClock(WorkoutState state, WorkoutMove move) {
    if (!_usesCountdownTimer(state, move)) {
      _countdownEndsAt = null;
      return;
    }
    _countdownEndsAt = DateTime.now().add(Duration(seconds: _timerSeconds));
  }

  void _syncMoveStopwatch(WorkoutState state, {required bool moveChanged}) {
    if (moveChanged) {
      _moveStopwatch
        ..stop()
        ..reset();
    }

    final bool shouldRun = state.phase == WorkoutPhase.move;
    if (shouldRun && !_moveStopwatch.isRunning) {
      _moveStopwatch.start();
      return;
    }
    if (!shouldRun && _moveStopwatch.isRunning) {
      _moveStopwatch.stop();
    }
  }

  void _syncMetronomeWithState(WorkoutState state,
      {required WorkoutMove move}) {
    final WorkoutPhase displayPhase = displayWorkoutPhase(state);
    final int? bpm = move.metronomeSpeed;
    final bool shouldPlay = state.phase != WorkoutPhase.paused &&
        displayPhase == WorkoutPhase.move &&
        move.type == MoveType.duration &&
        bpm != null &&
        bpm > 0;

    if (!shouldPlay) {
      _stopMetronome();
      return;
    }

    final String metronomeKey =
        '${state.setIndex}:${state.lapIndex}:${state.moveIndex}:${move.moveId}:$bpm';
    if (_activeMetronomeKey == metronomeKey && _metronomeTimer != null) {
      return;
    }

    _stopMetronome();
    _activeMetronomeKey = metronomeKey;
    unawaited(_playMetronomeTick());
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: (60000 / bpm).round()),
      (_) {
        if (!mounted) {
          _stopMetronome();
          return;
        }

        final WorkoutState currentState =
            ref.read(activeWorkoutControllerProvider);
        final WorkoutMove? currentMove =
            ref.read(activeWorkoutControllerProvider.notifier).currentMove;
        if (currentMove == null ||
            currentState.phase == WorkoutPhase.paused ||
            displayWorkoutPhase(currentState) != WorkoutPhase.move ||
            currentMove.moveId != move.moveId ||
            currentMove.metronomeSpeed != bpm) {
          _stopMetronome();
          return;
        }

        unawaited(_playMetronomeTick());
      },
    );
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _activeMetronomeKey = null;
  }

  void _playGetReadyCountdownCueIfNeeded(WorkoutState state, int seconds) {
    final WorkoutMove? currentMove =
        ref.read(activeWorkoutControllerProvider.notifier).currentMove;
    _playCountdownCueIfNeeded(
      state,
      currentMove: currentMove,
      seconds: seconds,
      phase: WorkoutPhase.prep,
      lastKey: _lastGetReadyCountdownKey,
      rememberKey: (String key) => _lastGetReadyCountdownKey = key,
      playCue: _playGetReadyCountdownCue,
    );
  }

  void _playMoveHalfwayCueIfNeeded(
    WorkoutState state,
    WorkoutMove? move,
    int seconds,
  ) {
    if (displayWorkoutPhase(state) != WorkoutPhase.move ||
        move?.type != MoveType.duration) {
      return;
    }
    final int duration = effectiveMoveDurationSeconds(move!);
    if (duration < 2 || seconds != duration ~/ 2) {
      return;
    }
    final String key =
        '${state.setIndex}:${state.lapIndex}:${state.moveIndex}:${move.moveId}';
    if (_lastMoveHalfwayKey == key) return;
    _lastMoveHalfwayKey = key;
    unawaited(_playMoveHalfway());
  }

  void _playCountdownCueIfNeeded(
    WorkoutState state, {
    required WorkoutMove? currentMove,
    required int seconds,
    required WorkoutPhase phase,
    required String? lastKey,
    required ValueChanged<String> rememberKey,
    required Future<void> Function() playCue,
    bool Function(WorkoutMove? move)? moveMatches,
  }) {
    if (displayWorkoutPhase(state) != phase ||
        seconds < 1 ||
        seconds > 3 ||
        (moveMatches != null && !moveMatches(currentMove))) {
      return;
    }

    final String countdownKey =
        '${state.setIndex}:${state.lapIndex}:${state.moveIndex}:${currentMove?.moveId}:$seconds';
    if (lastKey == countdownKey) {
      return;
    }

    rememberKey(countdownKey);
    unawaited(playCue());
  }

  Future<_WorkoutExitAction?> _chooseExitAction() {
    return showDialog<_WorkoutExitAction>(
      context: context,
      builder: (BuildContext context) => const _WorkoutExitDialog(),
    );
  }

  void _exitPlayer() {
    if (!mounted || _isExiting) {
      return;
    }
    _isExiting = true;
    _stopMetronome();

    final ActiveWorkoutController controller =
        ref.read(activeWorkoutControllerProvider.notifier);
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
    context.go('/dashboard');
  }
}

enum _WorkoutExitAction { end, cancelWorkout }

class _MoveSlot {
  const _MoveSlot({
    required this.setIndex,
    required this.lapIndex,
    required this.moveIndex,
    required this.set,
    required this.move,
  });

  final int setIndex;
  final int lapIndex;
  final int moveIndex;
  final WorkoutSet set;
  final WorkoutMove move;
}

class _WorkoutExitDialog extends StatelessWidget {
  const _WorkoutExitDialog();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('End or Cancel Workout?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'End workout saves this session to history. '
            'Cancel workout does not save workout history or move data.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_WorkoutExitAction.end),
            icon: const Icon(Icons.save_outlined),
            label: const Text('END WORKOUT AND SAVE'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_WorkoutExitAction.cancelWorkout),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('CANCEL WITHOUT SAVING'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('KEEP WORKING'),
        ),
      ],
    );
  }
}
