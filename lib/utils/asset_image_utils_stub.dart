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

  if (value.startsWith('/uploads/') &&
      mediaBaseUrl != null &&
      mediaBaseUrl.trim().isNotEmpty) {
    return NetworkImage('${mediaBaseUrl.trim()}$value');
  }

  return null;
}