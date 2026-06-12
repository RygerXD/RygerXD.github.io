import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/core/media/exercise_media_image.dart';

void main() {
  testWidgets('renders data URL images', (WidgetTester tester) async {
    const String transparentGif =
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';

    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseMediaImage(source: transparentGif),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });
}
