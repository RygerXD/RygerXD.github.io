import 'package:flutter/material.dart';

Widget defaultMediaImagePlaceholder() {
  return const SizedBox(
    width: 160,
    height: 120,
    child: Icon(Icons.broken_image_outlined, size: 40),
  );
}

Widget? buildDataUrlImage({
  required String source,
  BoxFit? fit,
  Widget? errorPlaceholder,
}) {
  final Uri? uri = Uri.tryParse(source);
  final UriData? data = uri?.data;
  if (uri?.scheme != 'data' ||
      data == null ||
      !data.mimeType.toLowerCase().startsWith('image/')) {
    return null;
  }

  try {
    return Image.memory(
      data.contentAsBytes(),
      fit: fit,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return errorPlaceholder ?? defaultMediaImagePlaceholder();
      },
    );
  } on FormatException {
    return null;
  }
}

Widget buildNetworkMediaImage({
  required String source,
  BoxFit? fit,
  Widget? loadingPlaceholder,
  Widget? errorPlaceholder,
}) {
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
          : loadingPlaceholder ?? defaultMediaImagePlaceholder();
    },
    errorBuilder: (
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) {
      return errorPlaceholder ?? defaultMediaImagePlaceholder();
    },
  );
}
