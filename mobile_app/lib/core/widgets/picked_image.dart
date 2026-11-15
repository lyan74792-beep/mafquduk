// Platform-agnostic picked image holder (bytes + filename) convertible to [UploadFile].
import 'dart:typed_data';

import '../network/api_client.dart';

class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  UploadFile toUpload(String field) =>
      UploadFile(field: field, bytes: bytes, filename: filename);
}
