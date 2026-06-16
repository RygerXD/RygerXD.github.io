import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/moves/application/move_catalog.dart';
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
  late final List<Move> _moves = _collectMoves();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Move> filteredMoves = _filteredMoves();

    return AlertDialog(
      title: const Text('Select Existing Move'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search moves',
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
              child: _moves.isEmpty
                  ? const Center(child: Text('No existing moves found.'))
                  : filteredMoves.isEmpty
                      ? const Center(child: Text('No matching moves.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredMoves.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Move move = filteredMoves[index];
                            return ListTile(
                              leading: _MoveThumbnail(
                                imageUrl: optionalText(move.imageUrl),
                              ),
                              title: Text(move.name),
                              onTap: () => Navigator.of(context).pop(move),
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

  List<Move> _collectMoves() {
    return collectUniqueReferencedMovesByName(widget.plans);
  }

  List<Move> _filteredMoves() {
    return filterByFuzzyMoveName<Move>(
      entries: _moves,
      query: _query,
      moveFor: (Move move) => move,
    );
  }
}

class _MoveThumbnail extends StatelessWidget {
  const _MoveThumbnail({
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
