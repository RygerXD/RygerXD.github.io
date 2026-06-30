import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RemoteGifCache {
  RemoteGifCache._();

  static final RemoteGifCache instance = RemoteGifCache._();
  static const int _maxCachedGifBytes = 50 * 1024 * 1024;

  final Map<String, Future<File?>> _inFlight = <String, Future<File?>>{};

  Future<File?> fileFor(String source) async {
    if (!isCacheableRemoteGifUrl(source)) {
      return null;
    }

    final File cacheFile = await _cacheFileForSource(source);
    if (await _hasUsableFile(cacheFile)) {
      return cacheFile;
    }

    return _inFlight.putIfAbsent(source, () async {
      try {
        return await _download(source, cacheFile);
      } finally {
        _inFlight.remove(source);
      }
    });
  }

  static bool isCacheableRemoteGifUrl(String source) {
    final Uri? uri = Uri.tryParse(source);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    return uri.path.toLowerCase().endsWith('.gif');
  }

  static String cacheFileNameForUrl(String source) {
    return 'remote_${_stableHexHash(source)}.gif';
  }

  Future<File> _cacheFileForSource(String source) async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final Directory cacheDirectory = Directory(
      p.join(documentsDirectory.path, 'remote_gif_cache'),
    );
    await cacheDirectory.create(recursive: true);
    return File(p.join(cacheDirectory.path, cacheFileNameForUrl(source)));
  }

  Future<bool> _hasUsableFile(File file) async {
    try {
      return await file.exists() && await file.length() > 0;
    } on FileSystemException {
      return false;
    }
  }

  Future<File?> _download(String source, File cacheFile) async {
    final HttpClient client = HttpClient();
    final File temporaryFile = File('${cacheFile.path}.tmp');
    try {
      final HttpClientRequest request = await client.getUrl(Uri.parse(source));
      request.headers.set(HttpHeaders.acceptHeader, 'image/gif,image/*');
      final HttpClientResponse response = await request.close();
      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        return null;
      }

      final String? mimeType = response.headers.contentType?.mimeType;
      if (mimeType != null && mimeType.toLowerCase() != 'image/gif') {
        return null;
      }

      final int? contentLength =
          response.contentLength < 0 ? null : response.contentLength;
      if (contentLength != null && contentLength > _maxCachedGifBytes) {
        return null;
      }

      await cacheFile.parent.create(recursive: true);
      final IOSink sink = temporaryFile.openWrite();
      int byteCount = 0;
      try {
        await for (final List<int> chunk in response) {
          byteCount += chunk.length;
          if (byteCount > _maxCachedGifBytes) {
            throw const _RemoteGifTooLargeException();
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }

      if (byteCount == 0) {
        await _deleteIfExists(temporaryFile);
        return null;
      }

      await temporaryFile.rename(cacheFile.path);
      return cacheFile;
    } on _RemoteGifTooLargeException {
      await _deleteIfExists(temporaryFile);
      return null;
    } on Object {
      await _deleteIfExists(temporaryFile);
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Best effort cleanup; a stale temp file should not block rendering.
    }
  }

  static String _stableHexHash(String value) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    const int mask64 = 0xffffffffffffffff;

    int hash = fnvOffset;
    for (final int codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}

class _RemoteGifTooLargeException implements Exception {
  const _RemoteGifTooLargeException();
}
