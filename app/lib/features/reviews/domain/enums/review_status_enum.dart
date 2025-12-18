/// Review status enumeration
/// Represents all possible states a review can be in
enum ReviewStatus {
  /// Review is being processed
  processing,

  /// Review is accepted and processed successfully
  processed,

  /// Review rejected due to low quality
  rejectedLowQuality,

  /// Review rejected due to being irrelevant to the shop
  rejectedIrrelevant;

  /// Get Arabic label for the status
  String get arabicLabel {
    switch (this) {
      case ReviewStatus.processing:
        return 'قيد المعالجة';
      case ReviewStatus.processed:
        return 'مقبول';
      case ReviewStatus.rejectedLowQuality:
        return 'مرفوض - جودة منخفضة';
      case ReviewStatus.rejectedIrrelevant:
        return 'مرفوض - غير ذي صلة';
    }
  }

  /// Get short Arabic label
  String get shortLabel {
    switch (this) {
      case ReviewStatus.processing:
        return 'معالجة';
      case ReviewStatus.processed:
        return 'مقبول';
      case ReviewStatus.rejectedLowQuality:
        return 'جودة منخفضة';
      case ReviewStatus.rejectedIrrelevant:
        return 'غير ذي صلة';
    }
  }

  /// Check if status is rejected
  bool get isRejected =>
      this == ReviewStatus.rejectedLowQuality ||
      this == ReviewStatus.rejectedIrrelevant;

  /// Check if status is accepted
  bool get isAccepted => this == ReviewStatus.processed;

  /// Check if status is processing
  bool get isProcessing => this == ReviewStatus.processing;

  /// Convert from backend string value
  static ReviewStatus fromString(String value) {
    switch (value) {
      case 'processing':
        return ReviewStatus.processing;
      case 'processed':
        return ReviewStatus.processed;
      case 'rejected_low_quality':
        return ReviewStatus.rejectedLowQuality;
      case 'rejected_irrelevant':
        return ReviewStatus.rejectedIrrelevant;
      default:
        return ReviewStatus.processing;
    }
  }

  /// Convert to backend string value
  String toBackendString() {
    switch (this) {
      case ReviewStatus.processing:
        return 'processing';
      case ReviewStatus.processed:
        return 'processed';
      case ReviewStatus.rejectedLowQuality:
        return 'rejected_low_quality';
      case ReviewStatus.rejectedIrrelevant:
        return 'rejected_irrelevant';
    }
  }
}
