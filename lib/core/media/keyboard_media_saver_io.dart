import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const MethodChannel _mediaChannel = MethodChannel('workout_app_rewrite/media');

Future<String?> saveKeyboardInsertedMedia(
    KeyboardInsertedContent content) async {
  if (Platform.isAndroid) {
    final String? copiedPath = await _copyAndroidContentUri(content);
    if (copiedPath != null) {
      return copiedPath;
    }
  }

  final Uint8List? bytes = content.data;
  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  final Directory documentsDirectory = await getApplicationDocumentsDirectory();
  final Directory mediaDirectory = Directory(
    p.join(documentsDirectory.path, 'move_media'),
  );
  await mediaDirectory.create(recursive: true);

  final File mediaFile = File(
    p.join(
      mediaDirectory.path,
      'keyboard_${DateTime.now().microsecondsSinceEpoch}'
      '${_extensionForMimeType(content.mimeType)}',
    ),
  );
  await mediaFile.writeAsBytes(bytes, flush: true);
  return mediaFile.path;
}

Future<String?> _copyAndroidContentUri(KeyboardInsertedContent content) async {
  try {
    final String? copiedPath = await _mediaChannel.invokeMethod<String>(
      'copyKeyboardContent',
      <String, String>{
        'uri': content.uri,
        'mimeType': content.mimeType,
      },
    );
    return copiedPath == null || copiedPath.isEmpty ? null : copiedPath;
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

String _extensionForMimeType(String mimeType) {
  return switch (mimeType.toLowerCase()) {
    'image/gif' => '.gif',
    'image/png' => '.png',
    'image/webp' => '.webp',
    'image/jpeg' || 'image/jpg' => '.jpg',
    _ => '.img',
  };
}
