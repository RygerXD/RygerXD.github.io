import 'dart:io';

import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/media/remote_gif_cache_io.dart';

class MoveMediaImage extends StatefulWidget {
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
  State<MoveMediaImage> createState() => _MoveMediaImageState();
}

class _MoveMediaImageState extends State<MoveMediaImage> {
  Future<File?>? _cachedGifFuture;
  String? _cachedGifSource;

  @override
  void initState() {
    super.initState();
    _syncCachedGifFuture();
  }

  @override
  void didUpdateWidget(MoveMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _syncCachedGifFuture();
    }
  }

  void _syncCachedGifFuture() {
    if (!RemoteGifCache.isCacheableRemoteGifUrl(widget.source)) {
      _cachedGifFuture = null;
      _cachedGifSource = null;
      return;
    }
    _cachedGifSource = widget.source;
    _cachedGifFuture = RemoteGifCache.instance.fileFor(widget.source);
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedGifFuture case final Future<File?> cachedGifFuture) {
      return FutureBuilder<File?>(
        future: cachedGifFuture,
        builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
          final File? file = snapshot.data;
          if (file != null && _cachedGifSource == widget.source) {
            return _fileImage(file);
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return widget.loadingPlaceholder ?? _defaultPlaceholder();
          }
          return _networkImage();
        },
      );
    }

    final Uri? uri = Uri.tryParse(widget.source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return _networkImage();
    }

    final File file = uri != null && uri.scheme == 'file'
        ? File.fromUri(uri)
        : File(widget.source);
    return _fileImage(file);
  }

  Widget _networkImage() {
    return Image.network(
      widget.source,
      fit: widget.fit,
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? loadingProgress,
      ) {
        return loadingProgress == null
            ? child
            : widget.loadingPlaceholder ?? _defaultPlaceholder();
      },
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return widget.errorPlaceholder ?? _defaultPlaceholder();
      },
    );
  }

  Widget _fileImage(File file) {
    return Image.file(
      file,
      fit: widget.fit,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return widget.errorPlaceholder ?? _defaultPlaceholder();
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
