import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class AddMoveDialog extends StatefulWidget {
  const AddMoveDialog({
    super.key,
    required this.onAdd,
    this.initialMove,
    this.initialWorkoutMove,
    this.initialMoveType,
  });

  /// Called when a user adds or edits a move. Passes back the scheduled
  /// workout move and its reusable move data, which need to be saved to the plan.
  final void Function(WorkoutMove workoutMove, Move move) onAdd;
  final Move? initialMove;
  final WorkoutMove? initialWorkoutMove;
  final MoveType? initialMoveType;

  @override
  State<AddMoveDialog> createState() => _AddMoveDialogState();
}

class _AddMoveDialogState extends State<AddMoveDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mediaUrlController = TextEditingController();
  final TextEditingController _prepController =
      TextEditingController(text: '5');
  final TextEditingController _cooldownController =
      TextEditingController(text: '0');
  final TextEditingController _repsController =
      TextEditingController(text: '10');
  final TextEditingController _durationController =
      TextEditingController(text: '30');
  final TextEditingController _metronomeController =
      TextEditingController(text: '60');
  final TextEditingController _weightController = TextEditingController();
  MoveType _moveType = MoveType.reps;
  bool _useMetronome = false;
  bool _repeatEachSide = false;
  bool _hasWeight = false;
  WeightUnit _weightUnit = WeightUnit.lb;
  bool get _isEditing => widget.initialWorkoutMove != null;

  @override
  void initState() {
    super.initState();
    final Move? initialMove = widget.initialMove;
    final WorkoutMove? initialWorkoutMove = widget.initialWorkoutMove;
    if (initialMove != null) {
      _nameController.text = initialMove.name;
      _mediaUrlController.text = initialMove.imageUrl ?? '';
    }
    _moveType = initialWorkoutMove?.type ?? widget.initialMoveType ?? _moveType;
    if (initialWorkoutMove != null) {
      _useMetronome = initialWorkoutMove.metronomeSpeed != null;
      _repeatEachSide = initialWorkoutMove.repeatEachSide;
      _prepController.text = initialWorkoutMove.prepTimeSeconds.toString();
      _cooldownController.text =
          initialWorkoutMove.finishTimeSeconds.toString();
      _repsController.text = (initialWorkoutMove.repCount ?? 10).toString();
      _durationController.text =
          (initialWorkoutMove.durationSeconds ?? 30).toString();
      _metronomeController.text =
          (initialWorkoutMove.metronomeSpeed ?? 60).toString();
      _hasWeight = initialWorkoutMove.targetWeight != null;
      _weightController.text = initialWorkoutMove.targetWeight == null
          ? ''
          : formatWeight(initialWorkoutMove.targetWeight!);
      _weightUnit = initialWorkoutMove.targetWeightUnit ?? WeightUnit.lb;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mediaUrlController.dispose();
    _prepController.dispose();
    _cooldownController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _metronomeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;
    final int? metronomeSpeed = _parseMetronomeSpeed();
    final double? targetWeight = _parseTargetWeight();
    if (_moveType == MoveType.duration &&
        _useMetronome &&
        metronomeSpeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BPM must be between 20 and 300.')),
      );
      return;
    }
    if (_hasWeight && targetWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight must be greater than 0.')),
      );
      return;
    }

    final String moveId = widget.initialMove?.moveId ?? const Uuid().v4();
    final Move move = Move(
      moveId: moveId,
      name: name,
      imageUrl: optionalText(_mediaUrlController.text),
      description: widget.initialMove?.description,
    );

    final WorkoutMove workoutMove = WorkoutMove(
      workoutMoveId:
          widget.initialWorkoutMove?.workoutMoveId ?? const Uuid().v4(),
      moveId: moveId,
      type: _moveType,
      prepTimeSeconds: _parseNonNegativeSeconds(_prepController.text, 5),
      repCount: _moveType == MoveType.reps
          ? (int.tryParse(_repsController.text) ?? 10)
          : null,
      durationSeconds: _moveType == MoveType.duration
          ? (int.tryParse(_durationController.text) ?? 30)
          : null,
      finishTimeSeconds: _parseNonNegativeSeconds(_cooldownController.text, 0),
      setCount: widget.initialWorkoutMove?.setCount ?? 1,
      repeatEachSide: _repeatEachSide,
      targetWeight: _hasWeight ? targetWeight : null,
      targetWeightUnit: _hasWeight ? _weightUnit : null,
      metronomeSpeed: metronomeSpeed,
    );

    widget.onAdd(workoutMove, move);
    Navigator.of(context).pop();
  }

  int _parseNonNegativeSeconds(String value, int fallback) {
    final int? seconds = int.tryParse(value);
    if (seconds == null || seconds < 0) {
      return fallback;
    }
    return seconds;
  }

  int? _parseMetronomeSpeed() {
    if (_moveType != MoveType.duration || !_useMetronome) {
      return null;
    }
    final int? bpm = int.tryParse(_metronomeController.text);
    if (bpm == null || bpm < 20 || bpm > 300) {
      return null;
    }
    return bpm;
  }

  double? _parseTargetWeight() {
    if (!_hasWeight) {
      return null;
    }
    final double? weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      return null;
    }
    return weight;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double dialogWidth = screenSize.width * 0.9;
    final double contentWidth =
        (dialogWidth - (AppSpacing.xl * 2)).clamp(0.0, dialogWidth).toDouble();

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: AppSpacing.xl,
      ),
      title: Text(_isEditing ? 'Edit Move' : 'Add New Move'),
      content: SizedBox(
        width: contentWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Move Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              ImageOrGifUrlField(
                controller: _mediaUrlController,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<MoveType>(
                segments: const <ButtonSegment<MoveType>>[
                  ButtonSegment<MoveType>(
                    value: MoveType.reps,
                    label: Text('Reps'),
                    icon: Icon(Icons.repeat),
                  ),
                  ButtonSegment<MoveType>(
                    value: MoveType.duration,
                    label: Text('Time'),
                    icon: Icon(Icons.timer),
                  ),
                  ButtonSegment<MoveType>(
                    value: MoveType.stopwatch,
                    label: Text('Max Time'),
                    icon: Icon(Icons.timer_outlined),
                  ),
                ],
                selected: <MoveType>{_moveType},
                onSelectionChanged: (Set<MoveType> selected) {
                  setState(() {
                    _moveType = selected.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _prepController,
                decoration: const InputDecoration(
                  labelText: 'Prep Time (sec)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _cooldownController,
                decoration: const InputDecoration(
                  labelText: 'Cooldown Time (sec)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_moveType == MoveType.reps)
                TextField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: 'Rep Count',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                )
              else if (_moveType == MoveType.duration)
                Column(
                  children: <Widget>[
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: _repeatEachSide
                            ? 'Duration per side (sec)'
                            : 'Duration (sec)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Metronome'),
                      subtitle: const Text('Count one rep per two beats'),
                      value: _useMetronome,
                      onChanged: (bool value) {
                        setState(() {
                          _useMetronome = value;
                        });
                      },
                    ),
                    if (_useMetronome)
                      TextField(
                        controller: _metronomeController,
                        decoration: const InputDecoration(
                          labelText: 'BPM',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                  ],
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Left and right sides'),
                subtitle: const Text('Repeat this move for each side'),
                value: _repeatEachSide,
                onChanged: (bool value) {
                  setState(() {
                    _repeatEachSide = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Track weight'),
                subtitle: const Text('Adjust actual weight during workouts'),
                value: _hasWeight,
                onChanged: (bool value) {
                  setState(() {
                    _hasWeight = value;
                    if (value && _weightController.text.trim().isEmpty) {
                      _weightController.text = '0';
                    }
                  });
                },
              ),
              if (_hasWeight) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Target Weight',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SegmentedButton<WeightUnit>(
                      segments: const <ButtonSegment<WeightUnit>>[
                        ButtonSegment<WeightUnit>(
                          value: WeightUnit.lb,
                          label: Text('lb'),
                        ),
                        ButtonSegment<WeightUnit>(
                          value: WeightUnit.kg,
                          label: Text('kg'),
                        ),
                      ],
                      selected: <WeightUnit>{_weightUnit},
                      onSelectionChanged: (Set<WeightUnit> selected) {
                        setState(() {
                          _weightUnit = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
