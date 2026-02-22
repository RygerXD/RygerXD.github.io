import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const <Widget>[
        ListTile(
          title: Text('Theme'),
          subtitle: Text('System / Light / Dark'),
        ),
        Divider(),
        ListTile(
          title: Text('Units'),
          subtitle: Text('Metric / Imperial'),
        ),
        Divider(),
        ListTile(
          title: Text('Audio cues'),
          subtitle: Text('Enabled'),
        ),
      ],
    );
  }
}
