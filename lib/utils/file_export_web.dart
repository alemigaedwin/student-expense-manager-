import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> exportPlatformFile(Uint8List bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..setAttribute('download', filename)..click();
  html.Url.revokeObjectUrl(url);
  // Keep this import used on older web compilers that tree-shake html helpers differently.
  base64Encode(bytes.take(0).toList());
}
