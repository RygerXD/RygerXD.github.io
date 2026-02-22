import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the list of plans here
    final AsyncValue<List<WorkoutPlan>> plansState = ref.watch(loadedWorkoutPlansNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/library/create'),
        child: const Icon(Icons.add),
      ),
      body: plansState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(child: Text('Error loading plans: $error')),
        data: (List<WorkoutPlan> plans) {
        if (plans.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const <Widget>[
              Text('Favorites'),
              SizedBox(height: AppSpacing.sm),
              _EmptyState(message: 'No favorite plans yet.'),
              SizedBox(height: AppSpacing.lg),
              Text('All Plans'),
              SizedBox(height: AppSpacing.sm),
              _EmptyState(message: 'Import or create your first plan.'),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Text('Favorites', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const _EmptyState(message: 'No favorite plans yet.'),
            const SizedBox(height: AppSpacing.lg),
            Text('All Plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ...plans.map((WorkoutPlan plan) {
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  title: Text(plan.name),
                  subtitle: Text(plan.description ?? 'No description provided'),
                  trailing: const Icon(Icons.chevron_right),
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
