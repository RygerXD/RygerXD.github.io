import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class AddMoveDialog extends StatefulWidget {
  const AddMoveDialog({
    super.key,
    required this.onAdd,
  });

  /// Called when a user adds a move. Passes back the new Move, and
  /// optionally a new Exercise if one was created (which needs to be saved to the Plan).
  final void Function(Move move, Exercise newExercise) onAdd;

  @override
  State<AddMoveDialog> createState() => _AddMoveDialogState();
}

class _AddMoveDialogState extends State<AddMoveDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mediaUrlController = TextEditingController();
  final TextEditingController _prepController =
      TextEditingController(text: '5');
  final TextEditingController _repsController =
      TextEditingController(text: '10');
  final TextEditingController _durationController =
      TextEditingController(text: '30');
  final TextEditingController _metronomeController =
      TextEditingController(text: '60');
  bool _isRepBased = true;
  bool _useMetronome = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mediaUrlController.dispose();
    _prepController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _metronomeController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;
    final int? metronomeSpeed = _parseMetronomeSpeed();
    if (!_isRepBased && _useMetronome && metronomeSpeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BPM must be between 20 and 300.')),
      );
      return;
    }

    final String exerciseId = const Uuid().v4();
    final Exercise exercise = Exercise(
      exerciseId: exerciseId,
      name: name,
      imageUrl: _optionalText(_mediaUrlController.text),
    );

    final Move move = Move(
      moveId: const Uuid().v4(),
      exerciseId: exerciseId,
      type: _isRepBased ? MoveType.reps : MoveType.duration,
      prepTimeSeconds: int.tryParse(_prepController.text) ?? 5,
      repCount: _isRepBased ? (int.tryParse(_repsController.text) ?? 10) : null,
      durationSeconds:
          _isRepBased ? null : (int.tryParse(_durationController.text) ?? 30),
      finishTimeSeconds: 0,
      metronomeSpeed: metronomeSpeed,
    );

    widget.onAdd(move, exercise);
    Navigator.of(context).pop();
  }

  String? _optionalText(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _parseMetronomeSpeed() {
    if (_isRepBased || !_useMetronome) {
      return null;
    }
    final int? bpm = int.tryParse(_metronomeController.text);
    if (bpm == null || bpm < 20 || bpm > 300) {
      return null;
    }
    return bpm;
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
      title: const Text('Add New Move'),
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
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _mediaUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image or GIF URL',
                  hintText: 'https://example.com/move.gif',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Reps'),
                    icon: Icon(Icons.repeat),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Duration'),
                    icon: Icon(Icons.timer),
                  ),
                ],
                selected: <bool>{_isRepBased},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() {
                    _isRepBased = selected.first;
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
              if (_isRepBased)
                TextField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: 'Rep Count',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                )
              else
                Column(
                  children: <Widget>[
                    TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Metronome'),
                      subtitle: const Text('Count one rep per beat'),
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
                ),
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
