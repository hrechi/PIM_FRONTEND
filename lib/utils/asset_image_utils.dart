import 'package:flutter/material.dart';

import 'asset_image_utils_stub.dart'
    if (dart.library.io) 'asset_image_utils_io.dart';

ImageProvider? resolveAssetImageProvider(
  String? imageUrl, {
  String? mediaBaseUrl,
}) {
  return resolveAssetImageProviderImpl(
    imageUrl,
    mediaBaseUrl: mediaBaseUrl,
  );
}