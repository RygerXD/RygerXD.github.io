import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/core/media/remote_gif_cache_io.dart';

void main() {
  test('identifies remote gif URLs as cacheable', () {
    expect(
      RemoteGifCache.isCacheableRemoteGifUrl(
        'https://example.com/workout.gif?size=large',
      ),
      isTrue,
    );
    expect(
      RemoteGifCache.isCacheableRemoteGifUrl('http://example.com/move.GIF'),
      isTrue,
    );
    expect(
      RemoteGifCache.isCacheableRemoteGifUrl('https://example.com/move.png'),
      isFalse,
    );
    expect(RemoteGifCache.isCacheableRemoteGifUrl('move.gif'), isFalse);
    expect(
      RemoteGifCache.isCacheableRemoteGifUrl('file:///tmp/move.gif'),
      isFalse,
    );
  });

  test('uses stable deterministic cache file names', () {
    const String source = 'https://example.com/workout.gif?size=large';

    expect(
      RemoteGifCache.cacheFileNameForUrl(source),
      RemoteGifCache.cacheFileNameForUrl(source),
    );
    expect(
      RemoteGifCache.cacheFileNameForUrl(source),
      isNot(
          RemoteGifCache.cacheFileNameForUrl('https://example.com/other.gif')),
    );
    expect(RemoteGifCache.cacheFileNameForUrl(source), endsWith('.gif'));
  });
}
