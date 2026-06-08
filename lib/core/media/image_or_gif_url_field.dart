import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workout_app_rewrite/core/media/keyboard_media_saver.dart';

class ImageOrGifUrlField extends StatefulWidget {
  const ImageOrGifUrlField({
    super.key,
    required this.controller,
    this.hintText = 'https://example.com/move.gif',
  });

  final TextEditingController controller;
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
        _setMediaPath(rawArguments['path'] as String?);
    }
  }

  Future<void> _handleKeyboardMediaInserted(
    KeyboardInsertedContent content,
  ) async {
    _setMediaPath(await saveKeyboardInsertedMedia(content));
  }

  void _setMediaPath(String? savedPath) {
    if (!mounted) {
      return;
    }

    final bool didSave = savedPath != null && savedPath.isNotEmpty;
    if (didSave) {
      widget.controller.text = savedPath;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(didSave ? 'Image added.' : 'Could not add that image.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesNativeAndroidField) {
      return InputDecorator(
        isEmpty: widget.controller.text.isEmpty,
        decoration: const InputDecoration(
          labelText: 'Image or GIF URL',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.image_outlined),
        ),
        child: SizedBox(
          height: 72,
          child: AndroidView(
            viewType: _viewType,
            creationParams: <String, String>{
              'initialText': widget.controller.text,
              'hintText': widget.hintText,
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
        onContentInserted: (KeyboardInsertedContent content) {
          unawaited(_handleKeyboardMediaInserted(content));
        },
      ),
    );
  }
}
