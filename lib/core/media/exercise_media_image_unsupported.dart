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

    return buildNetworkMediaImage(
      source: source,
      fit: fit,
      loadingPlaceholder: loadingPlaceholder,
      errorPlaceholder: errorPlaceholder,
    );
  }
}
