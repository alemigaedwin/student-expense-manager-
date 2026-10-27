import 'dart:typed_data';
import 'file_export_io.dart' if (dart.library.html) 'file_export_web.dart';

Future<void> exportFile(Uint8List bytes, String filename, String mimeType) => exportPlatformFile(bytes, filename, mimeType);
