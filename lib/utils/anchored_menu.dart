import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shows a [PopupMenuButton]-style menu anchored just below/around the
/// widget owning [anchorContext], instead of a full modal bottom sheet.
/// Pass the context of a [Builder] wrapped tightly around the trigger
/// widget so the anchor position is accurate.
Future<T?> showAnchoredMenu<T>({
  required BuildContext anchorContext,
  required List<PopupMenuEntry<T>> items,
}) async {
  final renderObject = anchorContext.findRenderObject();
  final overlay =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox;

  RelativeRect position;
  if (renderObject is RenderBox) {
    position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderObject.localToGlobal(
            renderObject.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        renderObject.localToGlobal(
            renderObject.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
  } else {
    // Fallback: anchor near the top of the screen.
    position = RelativeRect.fromLTRB(
        overlay.size.width * 0.1, 90, overlay.size.width * 0.1, 0);
  }

  return showMenu<T>(
    context: anchorContext,
    position: position,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border)),
    items: items,
  );
}
