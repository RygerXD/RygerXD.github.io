import 'package:flutter/material.dart';

class MoveMediaImage extends StatelessWidget {
  const MoveMediaImage({
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

  Widget _defaultPlaceholder() {
    return const SizedBox(
      width: 160,
      height: 120,
      child: Icon(Icons.broken_image_outlined, size: 40),
    );
  }
}
