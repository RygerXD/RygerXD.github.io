import 'dart:io';

import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/media/data_url_image.dart';

class ExerciseMediaImage extends StatelessWidget {
  const ExerciseMediaImage({
    super.key,
    required this.source,
    this.fit,
    this.loadingPlaceholder,
    this.errorPlaceholder,
  });

  final String source;
  final BoxFit? fit;
  final Widget? loadingPlaceholder;
  final Widget? errorPlaceholder;

  @override
  Widget build(BuildContext context) {
    final Widget? dataUrlImage = buildDataUrlImage(
      source: source,
      fit: fit,
      errorPlaceholder: errorPlaceholder,
    );
    if (dataUrlImage != null) {
      return dataUrlImage;
    }

    final Uri? uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return buildNetworkMediaImage(
        source: source,
        fit: fit,
        loadingPlaceholder: loadingPlaceholder,
        errorPlaceholder: errorPlaceholder,
      );
    }

    final File file =
        uri != null && uri.scheme == 'file' ? File.fromUri(uri) : File(source);
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return errorPlaceholder ?? defaultMediaImagePlaceholder();
      },
    );
  }
}
