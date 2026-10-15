import 'dart:typed_data';

import 'package:business_ledger/features/documents/domain/models/issued_document.dart';

/// Turns an issued document into PDF bytes. Rendering is local: it needs
/// only the document's snapshot, so it works offline.
///
/// An interface rather than a function so DI can bind it and tests can stub
/// it like any repository.
// ignore: one_member_abstracts
abstract class DocumentRenderer {
  const DocumentRenderer();

  Future<Uint8List> render(IssuedDocument document);
}
