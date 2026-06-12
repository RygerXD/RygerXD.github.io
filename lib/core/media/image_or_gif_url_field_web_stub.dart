import 'package:flutter/material.dart';

class WebImageOrGifUrlField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    throw UnsupportedError('WebImageOrGifUrlField is only available on web.');
  }
}
