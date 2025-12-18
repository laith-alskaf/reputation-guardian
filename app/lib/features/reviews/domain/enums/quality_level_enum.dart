/// Quality level classification based on quality score
enum QualityLevel {
  /// High quality (score >= 0.7)
  high,

  /// Medium quality (0.4 <= score < 0.7)
  medium,

  /// Low quality (score < 0.4)
  low;

  /// Get Arabic label
  String get arabicLabel {
    switch (this) {
      case QualityLevel.high:
        return 'جودة عالية';
      case QualityLevel.medium:
        return 'جودة متوسطة';
      case QualityLevel.low:
        return 'جودة منخفضة';
    }
  }

  /// Get quality level from score
  static QualityLevel fromScore(double score) {
    if (score >= 0.7) return QualityLevel.high;
    if (score >= 0.4) return QualityLevel.medium;
    return QualityLevel.low;
  }
}
