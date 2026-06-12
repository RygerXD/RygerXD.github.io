import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class WebImageOrGifUrlField extends StatefulWidget {
  const WebImageOrGifUrlField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onMediaAdded,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String?> onMediaAdded;

  @override
  State<WebImageOrGifUrlField> createState() => _WebImageOrGifUrlFieldState();
}

class _WebImageOrGifUrlFieldState extends State<WebImageOrGifUrlField> {
  static const String _viewType =
      'workout_app_rewrite/web_keyboard_media_editable';
  static const String _acceptedImageMimeTypes =
      'image/gif,image/png,image/jpeg,image/webp,image/*';
  static final Map<String, _WebImageOrGifUrlFieldState> _states =
      <String, _WebImageOrGifUrlFieldState>{};

  static bool _registered = false;
  static int _nextFieldId = 0;
  static bool _styleInstalled = false;

  late final String _fieldId = 'media-field-${_nextFieldId++}';
  web.HTMLDivElement? _element;
  web.HTMLInputElement? _fileInput;

  @override
  void initState() {
    super.initState();
    _states[_fieldId] = this;
    _registerViewFactory();
    widget.controller.addListener(_syncElementFromController);
  }

  @override
  void didUpdateWidget(WebImageOrGifUrlField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncElementFromController);
      widget.controller.addListener(_syncElementFromController);
      _syncElementFromController();
    }
    _element?.setAttribute('data-placeholder', widget.hintText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncElementFromController);
    _fileInput?.remove();
    _states.remove(_fieldId);
    super.dispose();
  }

  static void _registerViewFactory() {
    if (_registered) {
      return;
    }
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId, {Object? params}) {
        final Map<Object?, Object?> creationParams =
            params as Map<Object?, Object?>? ?? <Object?, Object?>{};
        final String fieldId = creationParams['fieldId'] as String? ?? '';
        final String hintText = creationParams['hintText'] as String? ?? '';
        final _WebImageOrGifUrlFieldState? state = _states[fieldId];
        final web.HTMLDivElement element = _createElement(
          fieldId: fieldId,
          hintText: hintText,
          initialText: creationParams['initialText'] as String? ?? '',
        );
        state?._attachElement(element);
        return element;
      },
    );
  }

  static web.HTMLDivElement _createElement({
    required String fieldId,
    required String hintText,
    required String initialText,
  }) {
    _installPlaceholderStyle();

    final web.HTMLDivElement element =
        web.document.createElement('div') as web.HTMLDivElement;
    element.contentEditable = 'true';
    element.textContent = initialText;
    element.setAttribute('role', 'textbox');
    element.setAttribute('aria-label', 'Image or GIF URL');
    element.setAttribute('aria-multiline', 'true');
    element.setAttribute('accept', _acceptedImageMimeTypes);
    element.setAttribute('autocapitalize', 'none');
    element.setAttribute('autocomplete', 'off');
    element.setAttribute('autocorrect', 'off');
    element.setAttribute('enterkeyhint', 'done');
    element.setAttribute('spellcheck', 'false');
    element.setAttribute('data-workout-media-field', fieldId);
    element.setAttribute('data-accepted-mime-types', _acceptedImageMimeTypes);
    element.setAttribute('data-placeholder', hintText);
    element.style.cssText = '''
box-sizing: border-box;
width: 100%;
height: 100%;
min-height: 72px;
padding: 14px 0 6px 0;
border: 0;
outline: none;
background: transparent;
color: #111827;
font: 400 16px Roboto, Arial, sans-serif;
line-height: 22px;
white-space: pre-wrap;
word-break: break-word;
overflow-y: auto;
''';

    element.addEventListener(
        'input',
        ((web.Event event) {
          _states[fieldId]?._handleInput(event as web.InputEvent);
        }).toJS);
    element.addEventListener(
        'beforeinput',
        ((web.Event event) {
          _states[fieldId]?._handleBeforeInput(event as web.InputEvent);
        }).toJS);
    element.addEventListener(
        'paste',
        ((web.Event event) {
          _states[fieldId]?._handlePaste(event as web.ClipboardEvent);
        }).toJS);
    element.addEventListener(
        'drop',
        ((web.Event event) {
          _states[fieldId]?._handleDrop(event as web.DragEvent);
        }).toJS);

    return element;
  }

  static void _installPlaceholderStyle() {
    if (_styleInstalled) {
      return;
    }
    _styleInstalled = true;
    final web.HTMLStyleElement style =
        web.document.createElement('style') as web.HTMLStyleElement;
    style.textContent = '''
[data-workout-media-field]:empty::before {
  content: attr(data-placeholder);
  color: #6b7280;
  pointer-events: none;
}
[data-workout-media-field] img {
  display: none;
}
''';
    web.document.head?.append(style);
  }

  void _attachElement(web.HTMLDivElement element) {
    _element = element;
    _syncElementFromController();
  }

  void _syncElementFromController() {
    final web.HTMLDivElement? element = _element;
    if (element == null) {
      return;
    }
    if ((element.textContent ?? '') != widget.controller.text) {
      element.textContent = widget.controller.text;
    }
  }

  void _handleInput(web.InputEvent event) {
    final web.HTMLDivElement? element = _element;
    if (element == null) {
      return;
    }

    final String? insertedImageSource = _extractInsertedImageSource(element);
    if (insertedImageSource != null) {
      event.preventDefault();
      _setMediaUrl(insertedImageSource);
      return;
    }

    final String text = element.innerText.trim();
    if (widget.controller.text != text) {
      widget.controller.text = text;
    }
  }

  void _handleBeforeInput(web.InputEvent event) {
    final web.File? file = _firstImageFile(event.dataTransfer);
    if (file == null) {
      return;
    }
    event.preventDefault();
    _readImageFile(file);
  }

  void _handlePaste(web.ClipboardEvent event) {
    final web.File? file = _firstImageFile(event.clipboardData);
    if (file == null) {
      return;
    }
    event.preventDefault();
    _readImageFile(file);
  }

  void _handleDrop(web.DragEvent event) {
    final web.File? file = _firstImageFile(event.dataTransfer);
    if (file == null) {
      return;
    }
    event.preventDefault();
    _readImageFile(file);
  }

  web.File? _firstImageFile(web.DataTransfer? dataTransfer) {
    if (dataTransfer == null) {
      return null;
    }

    final web.DataTransferItemList items = dataTransfer.items;
    for (int index = 0; index < items.length; index += 1) {
      final web.DataTransferItem item = items[index];
      if (item.kind == 'file' && item.type.toLowerCase().startsWith('image/')) {
        return item.getAsFile();
      }
    }

    final web.FileList files = dataTransfer.files;
    for (int index = 0; index < files.length; index += 1) {
      final web.File? file = files.item(index);
      if (file != null && file.type.toLowerCase().startsWith('image/')) {
        return file;
      }
    }
    return null;
  }

  void _readImageFile(web.File file) {
    final web.FileReader reader = web.FileReader();
    reader.onload = ((web.Event event) {
      final JSAny? result = reader.result;
      if (result == null) {
        widget.onMediaAdded(null);
        return;
      }

      final String dataUrl = (result as JSString).toDart;
      _setMediaUrl(dataUrl);
    }).toJS;
    reader.onerror = ((web.Event event) {
      widget.onMediaAdded(null);
    }).toJS;
    reader.readAsDataURL(file);
  }

  void _openImagePicker() {
    _fileInput?.remove();
    final web.HTMLInputElement input = web.HTMLInputElement();
    _fileInput = input;
    input.type = 'file';
    input.accept = _acceptedImageMimeTypes;
    input.style.display = 'none';
    input.onchange = ((web.Event event) {
      final web.File? file = input.files?.item(0);
      input.remove();
      if (_fileInput == input) {
        _fileInput = null;
      }
      if (file == null || !file.type.toLowerCase().startsWith('image/')) {
        widget.onMediaAdded(null);
        return;
      }
      _readImageFile(file);
    }).toJS;
    web.document.body?.append(input);
    input.click();
  }

  String? _extractInsertedImageSource(web.HTMLDivElement element) {
    final web.HTMLImageElement? image =
        element.querySelector('img') as web.HTMLImageElement?;
    final String? source = image?.src;
    if (source == null || source.isEmpty) {
      return null;
    }
    if (source.startsWith('data:image/') ||
        source.startsWith('http://') ||
        source.startsWith('https://')) {
      return source;
    }
    return null;
  }

  void _setMediaUrl(String dataUrl) {
    widget.controller.text = dataUrl;
    _element?.textContent = dataUrl;
    widget.onMediaAdded(dataUrl);
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      isEmpty: widget.controller.text.isEmpty,
      decoration: InputDecoration(
        labelText: 'Image or GIF URL',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.image_outlined),
        suffixIcon: IconButton(
          tooltip: 'Add image or GIF',
          icon: const Icon(Icons.add_photo_alternate_outlined),
          onPressed: _openImagePicker,
        ),
      ),
      child: SizedBox(
        height: 72,
        child: HtmlElementView(
          viewType: _viewType,
          creationParams: <String, String>{
            'fieldId': _fieldId,
            'initialText': widget.controller.text,
            'hintText': widget.hintText,
          },
        ),
      ),
    );
  }
}
