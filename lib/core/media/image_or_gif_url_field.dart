import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageOrGifUrlField extends StatefulWidget {
  const ImageOrGifUrlField({
    super.key,
    required this.controller,
    required this.onContentInserted,
    required this.onNativeKeyboardMediaInserted,
    this.hintText = 'https://example.com/move.gif',
  });

  final TextEditingController controller;
  final ValueChanged<KeyboardInsertedContent> onContentInserted;
  final ValueChanged<String?> onNativeKeyboardMediaInserted;
  final String hintText;

  @override
  State<ImageOrGifUrlField> createState() => _ImageOrGifUrlFieldState();
}

class _ImageOrGifUrlFieldState extends State<ImageOrGifUrlField> {
  static const String _viewType =
      'workout_app_rewrite/keyboard_media_edit_text';
  static const MethodChannel _channel =
      MethodChannel('workout_app_rewrite/keyboard_media_text');

  int? _nativeViewId;

  bool get _usesNativeAndroidField {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final String bindingType = WidgetsBinding.instance.runtimeType.toString();
    return !bindingType.contains('TestWidgets');
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    final Object? rawArguments = call.arguments;
    if (rawArguments is! Map<Object?, Object?>) {
      return;
    }

    final int? viewId = rawArguments['viewId'] as int?;
    if (viewId == null || viewId != _nativeViewId) {
      return;
    }

    switch (call.method) {
      case 'onTextChanged':
        final String text = rawArguments['text'] as String? ?? '';
        if (widget.controller.text != text) {
          widget.controller.text = text;
        }
      case 'onKeyboardMediaInserted':
        widget.onNativeKeyboardMediaInserted(rawArguments['path'] as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usesNativeAndroidField) {
      return InputDecorator(
        isEmpty: widget.controller.text.isEmpty,
        decoration: const InputDecoration(
          labelText: 'Image or GIF URL',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.image_outlined),
        ),
        child: SizedBox(
          height: 72,
          child: AndroidView(
            viewType: _viewType,
            creationParams: <String, String>{
              'initialText': widget.controller.text,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: (int id) {
              _nativeViewId = id;
            },
          ),
        ),
      );
    }

    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: 'Image or GIF URL',
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.image_outlined),
      ),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 1,
      maxLines: 3,
      contentInsertionConfiguration: ContentInsertionConfiguration(
        allowedMimeTypes: const <String>[
          'image/*',
          'image/gif',
          'image/png',
          'image/jpeg',
          'image/webp',
        ],
        onContentInserted: widget.onContentInserted,
      ),
    );
  }
}
