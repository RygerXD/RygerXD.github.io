import 'package:flutter/services.dart';

class BuiltInWorkoutSound {
  const BuiltInWorkoutSound({
    required this.id,
    required this.assetPath,
    required this.mimeType,
    required this.label,
  });

  final String id;
  final String assetPath;
  final String mimeType;
  final String label;

  String get name => id.substring(0, id.lastIndexOf('.'));

  bool matches(String selection) => id == selection || name == selection;
}

abstract final class BuiltInSoundCatalog {
  static Future<List<BuiltInWorkoutSound>>? _sounds;

  static Future<List<BuiltInWorkoutSound>> load() =>
      _sounds ??= _loadFromAssets();

  static Future<BuiltInWorkoutSound> resolve(String selection) async {
    final List<BuiltInWorkoutSound> sounds = await load();
    if (sounds.isEmpty) {
      throw StateError('No built-in sound assets are available.');
    }
    return sounds.firstWhere(
      (BuiltInWorkoutSound sound) => sound.matches(selection),
      orElse: () => sounds.firstWhere(
        (BuiltInWorkoutSound sound) => sound.matches('classic'),
        orElse: () => sounds.first,
      ),
    );
  }

  static List<BuiltInWorkoutSound> fromAssetPaths(Iterable<String> paths) {
    final List<BuiltInWorkoutSound> sounds = paths
        .where((String path) => path.startsWith('assets/audio/'))
        .map(_fromAssetPath)
        .whereType<BuiltInWorkoutSound>()
        .toList(growable: false)
      ..sort((BuiltInWorkoutSound left, BuiltInWorkoutSound right) =>
          left.label.toLowerCase().compareTo(right.label.toLowerCase()));
    return sounds;
  }

  static Future<List<BuiltInWorkoutSound>> _loadFromAssets() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    return fromAssetPaths(manifest.listAssets());
  }

  static BuiltInWorkoutSound? _fromAssetPath(String assetPath) {
    final String fileName = assetPath.split('/').last;
    final int extensionIndex = fileName.lastIndexOf('.');
    if (extensionIndex <= 0) return null;
    final String extension =
        fileName.substring(extensionIndex + 1).toLowerCase();
    final String? mimeType = switch (extension) {
      'mp3' => 'audio/mpeg',
      'ogg' || 'opus' => 'audio/ogg',
      'wav' => 'audio/wav',
      _ => null,
    };
    if (mimeType == null) return null;

    final String name = fileName.substring(0, extensionIndex);
    final String words = name.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final String label = words.isEmpty
        ? fileName
        : '${words[0].toUpperCase()}${words.substring(1)}';
    return BuiltInWorkoutSound(
      id: fileName,
      assetPath: assetPath,
      mimeType: mimeType,
      label: label,
    );
  }
}
