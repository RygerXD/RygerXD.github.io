import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/media/move_media_image.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.backgroundColor,
    required this.dimension,
    this.iconColor,
    this.isCircular = false,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final Color backgroundColor;
  final double dimension;
  final Color? iconColor;
  final bool isCircular;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Icon(
      fallbackIcon,
      color: iconColor,
    );
    final Widget thumbnail = ColoredBox(
      color: backgroundColor,
      child: SizedBox.square(
        dimension: dimension,
        child: imageUrl == null
            ? placeholder
            : MoveMediaImage(
                source: imageUrl!,
                fit: BoxFit.cover,
                errorPlaceholder: placeholder,
              ),
      ),
    );

    if (isCircular) {
      return ClipOval(child: thumbnail);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: thumbnail,
    );
  }
}
