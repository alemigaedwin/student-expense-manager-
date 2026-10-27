import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/anchored_menu.dart';
import '../../utils/app_colors.dart';

/// A receipt chosen by the user, read fully into memory so it can be uploaded
/// to the database. Works the same on Android, iOS and the web (no file paths).
class PickedReceipt {
  final Uint8List bytes;
  final String fileName;
  const PickedReceipt(this.bytes, this.fileName);
}

/// Shows the Camera / Gallery / PDF menu anchored to the "Add Bills" button and
/// returns the chosen file's bytes, or null if the user cancelled.
/// Throws if the camera/gallery cannot be opened (e.g. permission denied) so the
/// caller can tell the user instead of failing silently.
Future<PickedReceipt?> showBillAttachmentPicker(BuildContext anchorContext) async {
  final choice = await showAnchoredMenu<String>(
    anchorContext: anchorContext,
    items: [
      PopupMenuItem(
        value: 'camera',
        child: Row(children: [
          Icon(Icons.camera_alt, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Text('Camera', style: TextStyle(color: AppColors.textPrimary)),
        ]),
      ),
      PopupMenuItem(
        value: 'gallery',
        child: Row(children: [
          Icon(Icons.photo_library, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Text('Gallery', style: TextStyle(color: AppColors.textPrimary)),
        ]),
      ),
      PopupMenuItem(
        value: 'pdf',
        child: Row(children: [
          Icon(Icons.picture_as_pdf, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Text('PDF', style: TextStyle(color: AppColors.textPrimary)),
        ]),
      ),
    ],
  );

  if (choice == null) return null;
  switch (choice) {
    case 'camera':
    case 'gallery':
      // Downscaling keeps phone photos small (usually well under 1 MB) so the
      // upload is quick on mobile data and fits the server limit.
      final file = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (file == null) return null;
      return PickedReceipt(await file.readAsBytes(),
          file.name.isEmpty ? 'receipt.jpg' : file.name);
    case 'pdf':
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      final picked = result?.files.single;
      if (picked == null) return null;
      final bytes = picked.bytes;
      if (bytes == null) {
        throw Exception('The PDF could not be read.');
      }
      return PickedReceipt(bytes, picked.name);
  }
  return null;
}
