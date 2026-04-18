import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider? resolveAssetImageProviderImpl(
  String? imageUrl, {
  String? mediaBaseUrl,
}) {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;

  final value = imageUrl.trim();

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  if (value.startsWith('file://')) {
    final file = File(Uri.parse(value).toFilePath());
    if (file.existsSync()) return FileImage(file);
    return null;
  }

  if (value.startsWith('/uploads/')) {
    final base = mediaBaseUrl?.trim();
    if (base != null && base.isNotEmpty) {
      return NetworkImage('$base$value');
    }
  }

  final file = File(value);
  if (file.existsSync()) {
    return FileImage(file);
  }

  final base = mediaBaseUrl?.trim();
  if (base != null && base.isNotEmpty) {
    final normalized = value.startsWith('/') ? value : '/$value';
    return NetworkImage('$base$normalized');
  }

  return null;
}