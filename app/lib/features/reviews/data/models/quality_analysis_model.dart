import 'package:reputation_guardian/features/reviews/domain/enums/quality_flag_enum.dart';

/// Model representing quality analysis data from backend
class QualityAnalysisModel {
  /// Quality score from 0.0 to 1.0
  final double qualityScore;

  /// List of quality flags indicating issues
  final List<QualityFlag> flags;

  /// Whether the review is marked as suspicious
  final bool isSuspicious;

  /// Toxicity status: toxic, uncertain, non-toxic
  final String toxicityStatus;

  const QualityAnalysisModel({
    required this.qualityScore,
    required this.flags,
    required this.isSuspicious,
    required this.toxicityStatus,
  });

  /// Create from JSON
  factory QualityAnalysisModel.fromJson(Map<String, dynamic> json) {
    return QualityAnalysisModel(
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
      flags: QualityFlag.parseList(json['flags'] as List?),
      isSuspicious: json['is_suspicious'] as bool? ?? false,
      toxicityStatus: json['toxicity_status'] as String? ?? 'non-toxic',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'quality_score': qualityScore,
      'flags': flags.map((f) => f.toBackendString()).toList(),
      'is_suspicious': isSuspicious,
      'toxicity_status': toxicityStatus,
    };
  }

  /// Check if toxic
  bool get isToxic => toxicityStatus == 'toxic';

  /// Check if has any flags
  bool get hasFlags => flags.isNotEmpty;

  /// Check if has severe issues
  bool get hasSevereIssues => flags.any((f) => f.isSevere);

  /// Get most critical flag
  QualityFlag? get mostCriticalFlag {
    return QualityFlag.getMostImportant(flags);
  }

  /// Copy with new values
  QualityAnalysisModel copyWith({
    double? qualityScore,
    List<QualityFlag>? flags,
    bool? isSuspicious,
    String? toxicityStatus,
  }) {
    return QualityAnalysisModel(
      qualityScore: qualityScore ?? this.qualityScore,
      flags: flags ?? this.flags,
      isSuspicious: isSuspicious ?? this.isSuspicious,
      toxicityStatus: toxicityStatus ?? this.toxicityStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QualityAnalysisModel &&
        other.qualityScore == qualityScore &&
        _listEquals(other.flags, flags) &&
        other.isSuspicious == isSuspicious &&
        other.toxicityStatus == toxicityStatus;
  }

  @override
  int get hashCode {
    return qualityScore.hashCode ^
        flags.hashCode ^
        isSuspicious.hashCode ^
        toxicityStatus.hashCode;
  }

  bool _listEquals(List<QualityFlag> a, List<QualityFlag> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
