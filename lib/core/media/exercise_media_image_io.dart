import 'dart:io';

import 'package:flutter/material.dart';

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
    final Uri? uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        source,
        fit: fit,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          return loadingProgress == null
              ? child
              : loadingPlaceholder ?? _defaultPlaceholder();
        },
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return errorPlaceholder ?? _defaultPlaceholder();
        },
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
        return errorPlaceholder ?? _defaultPlaceholder();
      },
    );
  }

  Widget _defaultPlaceholder() {
    return const SizedBox(
      width: 160,
      height: 120,
      child: Icon(Icons.broken_image_outlined, size: 40),
    );
  }
}
