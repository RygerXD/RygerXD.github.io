import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/moves/application/move_catalog.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class MovesScreen extends ConsumerStatefulWidget {
  const MovesScreen({super.key});

  @override
  ConsumerState<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends ConsumerState<MovesScreen> {
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
        title: const Text('Moves'),
      ),
      body: plansState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text('Error loading moves: $error')),
        data: (List<WorkoutPlan> plans) {
          final List<ReferencedMoveEntry> moves = collectReferencedMoves(plans);
          final List<ReferencedMoveEntry> filteredMoves = _filteredMoves(moves);
          if (moves.isEmpty) {
            return const _EmptyState(
              message: 'No moves yet. Import or create a plan to add some.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search moves',
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
              if (filteredMoves.isEmpty)
                const _EmptyState(message: 'No matching moves.')
              else
                for (final ReferencedMoveEntry entry in filteredMoves)
                  _MoveCard(
                    entry: entry,
                    onTap: () => _editMove(context, ref, plans, entry),
                  ),
            ],
          );
        },
      ),
    );
  }

  List<ReferencedMoveEntry> _filteredMoves(
    List<ReferencedMoveEntry> moves,
  ) {
    return filterByFuzzyMoveName<ReferencedMoveEntry>(
      entries: moves,
      query: _query,
      moveFor: (ReferencedMoveEntry entry) => entry.move,
    );
  }

  Future<void> _editMove(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutPlan> plans,
    ReferencedMoveEntry entry,
  ) async {
    final Move? updatedMove = await showDialog<Move>(
      context: context,
      builder: (BuildContext context) => _EditMoveDialog(
        move: entry.move,
        sourcePlanNames: entry.planNames,
      ),
    );

    if (updatedMove == null) {
      return;
    }

    try {
      for (final WorkoutPlan plan in plans) {
        final int moveIndex = plan.moves.indexWhere(
          (Move move) => move.moveId == updatedMove.moveId,
        );
        if (moveIndex < 0) {
          continue;
        }

        final List<Move> updatedMoves = List<Move>.from(plan.moves);
        updatedMoves[moveIndex] = updatedMove;
        await ref
            .read(loadedWorkoutPlansNotifierProvider.notifier)
            .loadPlan(plan.copyWith(moves: updatedMoves));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated ${updatedMove.name}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating move: $error')),
        );
      }
    }
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.entry,
    required this.onTap,
  });

  final ReferencedMoveEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Move move = entry.move;
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
                imageUrl: optionalText(move.imageUrl),
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
                      move.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (move.description != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        move.description!,
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

class _EditMoveDialog extends StatefulWidget {
  const _EditMoveDialog({
    required this.move,
    required this.sourcePlanNames,
  });

  final Move move;
  final List<String> sourcePlanNames;

  @override
  State<_EditMoveDialog> createState() => _EditMoveDialogState();
}

class _EditMoveDialogState extends State<_EditMoveDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.move.name);
  late final TextEditingController _imageUrlController =
      TextEditingController(text: widget.move.imageUrl ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.move.description ?? '');

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
      title: const Text('Edit Move'),
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
                    labelText: 'Move Name *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a move name';
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
              widget.move.copyWith(
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
