part of 'document_cubit.dart';

class DocumentState extends Equatable {
  const DocumentState({
    this.businessId,
    this.documents = const [],
    this.document,
    this.pdf,
    this.watchStatus = const Status.initial(),
    this.issueStatus = const Status.initial(),
    this.renderStatus = const Status.initial(),
    this.shareStatus = const Status.initial(),
    this.printStatus = const Status.initial(),
    this.uploadStatus = const Status.initial(),
  });

  final String? businessId;

  /// Documents issued for the watched transaction, newest first.
  final List<IssuedDocument> documents;

  /// The document being previewed.
  final IssuedDocument? document;

  /// [document] rendered. `null` until the render completes.
  final Uint8List? pdf;

  final Status watchStatus;
  final Status issueStatus;
  final Status renderStatus;
  final Status shareStatus;
  final Status printStatus;
  final Status uploadStatus;

  bool get hasPdf => pdf != null;

  /// Any operation that should keep the preview's actions disabled.
  bool get isBusy =>
      issueStatus.isLoading ||
      renderStatus.isLoading ||
      shareStatus.isLoading ||
      printStatus.isLoading ||
      uploadStatus.isLoading;

  DocumentState copyWith({
    String? businessId,
    List<IssuedDocument>? documents,
    IssuedDocument? document,
    Uint8List? pdf,
    bool clearPdf = false,
    Status? watchStatus,
    Status? issueStatus,
    Status? renderStatus,
    Status? shareStatus,
    Status? printStatus,
    Status? uploadStatus,
  }) => DocumentState(
    businessId: businessId ?? this.businessId,
    documents: documents ?? this.documents,
    document: document ?? this.document,
    pdf: clearPdf ? null : pdf ?? this.pdf,
    watchStatus: watchStatus ?? this.watchStatus,
    issueStatus: issueStatus ?? this.issueStatus,
    renderStatus: renderStatus ?? this.renderStatus,
    shareStatus: shareStatus ?? this.shareStatus,
    printStatus: printStatus ?? this.printStatus,
    uploadStatus: uploadStatus ?? this.uploadStatus,
  );

  @override
  List<Object?> get props => [
    businessId,
    documents,
    document,
    // Compared by size, not byte by byte: a deep compare of a PDF on every
    // emit is wasteful, and a new render always arrives with a status change.
    pdf?.length,
    watchStatus,
    issueStatus,
    renderStatus,
    shareStatus,
    printStatus,
    uploadStatus,
  ];
}
