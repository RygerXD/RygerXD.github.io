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
  final TextEditingController _prepController = TextEditingController(text: '5');
  final TextEditingController _repsController = TextEditingController(text: '10');
  final TextEditingController _durationController = TextEditingController(text: '30');
  bool _isRepBased = true;

  @override
  void dispose() {
    _nameController.dispose();
    _prepController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    final String exerciseId = const Uuid().v4();
    final Exercise exercise = Exercise(
      exerciseId: exerciseId,
      name: name,
    );

    final Move move = Move(
      moveId: const Uuid().v4(),
      exerciseId: exerciseId,
      type: _isRepBased ? MoveType.reps : MoveType.duration,
      prepTimeSeconds: int.tryParse(_prepController.text) ?? 5,
      repCount: _isRepBased ? (int.tryParse(_repsController.text) ?? 10) : null,
      durationSeconds: _isRepBased ? null : (int.tryParse(_durationController.text) ?? 30),
      finishTimeSeconds: 0,
    );

    widget.onAdd(move, exercise);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Move'),
      content: SingleChildScrollView(
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
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (sec)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
          ],
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
