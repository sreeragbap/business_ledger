import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum AttachmentSource { photo, file }

/// Asks where to attach from, then picks. Resolves `null` when the user
/// backs out. Size and type are checked by the form cubit.
///
/// Photos come from the system photo picker without full metadata, which
/// needs no photo-library permission on iOS. A camera option needs an
/// `NSCameraUsageDescription` in `ios/Runner/Info.plist` first.
Future<PickedAttachment?> pickAttachment(BuildContext context) async {
  final source = await showAppBottomSheet<AttachmentSource>(
    context: context,
    title: 'Attach',
    child: Builder(
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Photo'),
            subtitle: const Text('A bill or receipt from your photos'),
            onTap: () => Navigator.of(sheet).pop(AttachmentSource.photo),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('File'),
            subtitle: const Text('PDF or image, up to 10 MB'),
            onTap: () => Navigator.of(sheet).pop(AttachmentSource.file),
          ),
        ],
      ),
    ),
  );
  switch (source) {
    case null:
      return null;
    case AttachmentSource.photo:
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2400,
        requestFullMetadata: false,
      );
      if (image == null) return null;
      return PickedAttachment(
        name: image.name,
        bytes: await image.readAsBytes(),
        contentType:
            image.mimeType ?? PickedAttachment.contentTypeFor(image.name),
      );
    case AttachmentSource.file:
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
      );
      if (file == null) return null;
      return PickedAttachment(
        name: file.name,
        bytes: await file.xFile.readAsBytes(),
        contentType: PickedAttachment.contentTypeFor(file.name),
      );
  }
}
