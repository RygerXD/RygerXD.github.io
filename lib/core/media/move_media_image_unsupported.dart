import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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
  static const int _maxLocalStorageGifBytes = 3 * 1024 * 1024;
  Future<Uint8List?>? _cachedGifFuture;
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
    if (!_isCacheableRemoteGifUrl(widget.source)) {
      _cachedGifFuture = null;
      _cachedGifSource = null;
      return;
    }
    _cachedGifSource = widget.source;
    _cachedGifFuture = _cachedGifBytesFor(widget.source);
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedGifFuture case final Future<Uint8List?> cachedGifFuture) {
      return FutureBuilder<Uint8List?>(
        future: cachedGifFuture,
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          final Uint8List? bytes = snapshot.data;
          if (bytes != null && _cachedGifSource == widget.source) {
            return Image.memory(
              bytes,
              fit: widget.fit,
              gaplessPlayback: true,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return widget.errorPlaceholder ?? _defaultPlaceholder();
              },
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return widget.loadingPlaceholder ?? _defaultPlaceholder();
          }
          return _networkImage();
        },
      );
    }

    return _networkImage();
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

  Widget _defaultPlaceholder() {
    return const SizedBox(
      width: 160,
      height: 120,
      child: Icon(Icons.broken_image_outlined, size: 40),
    );
  }

  Future<Uint8List?> _cachedGifBytesFor(String source) async {
    final String storageKey = _storageKeyForUrl(source);
    final String? cachedBase64 = web.window.localStorage.getItem(storageKey);
    if (cachedBase64 != null && cachedBase64.isNotEmpty) {
      try {
        return base64Decode(cachedBase64);
      } on FormatException {
        web.window.localStorage.removeItem(storageKey);
      }
    }

    try {
      final web.Response response = await web.window.fetch(source.toJS).toDart;
      if (!response.ok) {
        return null;
      }
      final String? contentType =
          response.headers.get('content-type')?.split(';').first.trim();
      if (contentType != null && contentType.toLowerCase() != 'image/gif') {
        return null;
      }

      final JSArrayBuffer buffer = await response.arrayBuffer().toDart;
      final Uint8List bytes = buffer.toDart.asUint8List();
      if (bytes.isEmpty) {
        return null;
      }
      if (bytes.length <= _maxLocalStorageGifBytes) {
        try {
          web.window.localStorage.setItem(storageKey, base64Encode(bytes));
        } on Object {
          // Quota and privacy settings should not block rendering.
        }
      }
      return bytes;
    } on Object {
      return null;
    }
  }

  bool _isCacheableRemoteGifUrl(String source) {
    final Uri? uri = Uri.tryParse(source);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    return uri.path.toLowerCase().endsWith('.gif');
  }

  String _storageKeyForUrl(String source) {
    return 'workout_app_rewrite.remote_gif_cache.v1.${_stableHexHash(source)}';
  }

  String _stableHexHash(String value) {
    const int fnvOffset = 0x811c9dc5;
    const int fnvPrime = 0x01000193;
    const int mask32 = 0xffffffff;

    int hash = fnvOffset;
    for (final int codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & mask32;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
