import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({
    super.key,
    this.planId,
  });

  final String? planId;

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  final List<String> _tags = <String>[];
  WorkoutPlan? _existingPlan;
  bool _isInitializing = false;
  bool _isLoading = false;

  bool get _isEditing => widget.planId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _isInitializing = true;
      unawaited(_loadExistingPlan());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPlan() async {
    final List<WorkoutPlan> plans =
        await ref.read(loadedWorkoutPlansNotifierProvider.future);
    final WorkoutPlan? plan = plans
        .where((WorkoutPlan plan) => plan.planId == widget.planId)
        .firstOrNull;

    if (!mounted) {
      return;
    }

    setState(() {
      _existingPlan = plan;
      if (plan != null) {
        _nameController.text = plan.name;
        _imageUrlController.text = plan.imageUrl ?? '';
        _descriptionController.text = plan.description ?? '';
        _authorController.text = plan.author ?? '';
        _tags
          ..clear()
          ..addAll(plan.tags);
      }
      _isInitializing = false;
    });
  }

  void _addTag() {
    final String tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing && _existingPlan == null) {
        throw StateError('Plan not found.');
      }

      final String name = _nameController.text.trim();
      final String? imageUrl = optionalText(_imageUrlController.text);
      final String? description = optionalText(_descriptionController.text);
      final String? author = optionalText(_authorController.text);
      final List<String> tags = List<String>.from(_tags);
      final WorkoutPlan savedPlan = _existingPlan?.copyWith(
            name: name,
            imageUrl: imageUrl,
            description: description,
            author: author,
            tags: tags,
          ) ??
          WorkoutPlan(
            schemaVersion: 3,
            planId: const Uuid().v4(),
            name: name,
            imageUrl: imageUrl,
            description: description,
            author: author,
            tags: tags,
            workouts: <Workout>[],
            exercises: <Exercise>[],
          );

      await ref
          .read(loadedWorkoutPlansNotifierProvider.notifier)
          .loadPlan(savedPlan);

      if (mounted) {
        context.go('/library/detail/${savedPlan.planId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Workout Plan' : 'Create Workout Plan'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _isLoading || _isInitializing ? null : _savePlan,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name *',
                      hintText: 'e.g., My Custom Workout',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a plan name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ImageOrGifUrlField(
                    controller: _imageUrlController,
                    hintText: 'https://example.com/plan.gif',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your workout plan...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      hintText: 'Your name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Add a tag...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.tag),
                          ),
                          onFieldSubmitted: (_) => _addTag(),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _tags
                          .map((String tag) => Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeTag(tag),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Text(
                                'After creating your plan, you can add workouts and exercises to it.'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
