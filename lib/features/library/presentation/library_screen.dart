import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the list of plans here
    final AsyncValue<List<WorkoutPlan>> plansState =
        ref.watch(loadedWorkoutPlansNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/library/create'),
        child: const Icon(Icons.add),
      ),
      body: plansState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text('Error loading plans: $error')),
        data: (List<WorkoutPlan> plans) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => _importWorkoutJson(context, ref),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Import Plan JSON'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Favorites',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _EmptyState(message: 'No favorite plans yet.'),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'All Plans',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (plans.isEmpty)
                const _EmptyState(message: 'Import or create your first plan.')
              else
                ...plans.map((WorkoutPlan plan) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      leading: MediaThumbnail(
                        imageUrl: optionalText(plan.imageUrl),
                        fallbackIcon: Icons.library_books_outlined,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        iconColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        dimension: 48,
                      ),
                      title: Text(plan.name),
                      subtitle:
                          Text(plan.description ?? 'No description provided'),
                      trailing: SizedBox(
                        width: 96,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Export plan',
                              icon: const Icon(Icons.upload_file_outlined),
                              onPressed: () =>
                                  _exportWorkoutPlan(context, ref, plan),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                      onTap: () {
                        context.go('/library/detail/${plan.planId}');
                      },
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importWorkoutJson(BuildContext context, WidgetRef ref) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      return;
    }

    try {
      final String jsonString = utf8.decode(result.files.single.bytes!);
      final WorkoutPlan plan = await ref
          .read(workoutPlanImportServiceProvider)
          .importFromJsonString(jsonString);

      ref.invalidate(loadedWorkoutPlansNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${plan.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing workout: $e')),
        );
      }
    }
  }

  Future<void> _exportWorkoutPlan(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
  ) async {
    try {
      final result =
          await ref.read(workoutPlanExportServiceProvider).exportPlan(plan);
      if (!context.mounted) {
        return;
      }
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export canceled.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${plan.name}')),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting workout: $error')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(message),
      ),
    );
  }
}
