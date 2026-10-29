import 'package:equatable/equatable.dart';

/// One line of text the platform recogniser found, with its box.
///
/// Boxes are in pixels of the upright image on both platforms: the parser
/// measures row slopes, which need the same unit on both axes.
class OcrLine extends Equatable {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// The shape the platform channel sends.
  factory OcrLine.fromMap(Map<Object?, Object?> map) => OcrLine(
    text: (map['text'] as String?) ?? '',
    left: (map['left'] as num?)?.toDouble() ?? 0,
    top: (map['top'] as num?)?.toDouble() ?? 0,
    right: (map['right'] as num?)?.toDouble() ?? 0,
    bottom: (map['bottom'] as num?)?.toDouble() ?? 0,
  );

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  @override
  List<Object?> get props => [text, left, top, right, bottom];
}
