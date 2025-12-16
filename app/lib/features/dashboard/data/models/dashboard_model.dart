import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/dashboard_data.dart';

part 'dashboard_model.g.dart';

@JsonSerializable()
class DashboardModel {
  @JsonKey(name: 'metrics')
  final MetricsModel metricsData;

  @JsonKey(name: 'shop_info')
  final ShopInfoModel shopInfoData;

  @JsonKey(name: 'qr_code')
  final String? qrCodeData;

  @JsonKey(name: 'processed_reviews')
  final List<dynamic> processedReviewsData;

  @JsonKey(name: 'rejected_quality_reviews')
  final List<dynamic> rejectedQualityReviewsData;

  @JsonKey(name: 'rejected_irrelevant_reviews')
  final List<dynamic> rejectedIrrelevantReviewsData;

  DashboardModel({
    required this.metricsData,
    required this.shopInfoData,
    this.qrCodeData,
    required this.processedReviewsData,
    required this.rejectedQualityReviewsData,
    required this.rejectedIrrelevantReviewsData,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardModelToJson(this);

  DashboardData toEntity() {
    return DashboardData(
      metrics: metricsData.toEntity(),
      shopInfo: shopInfoData.toEntity(),
      qrCode: qrCodeData,
      processedReviews: processedReviewsData,
      rejectedQualityReviews: rejectedQualityReviewsData,
      rejectedIrrelevantReviews: rejectedIrrelevantReviewsData,
      lastUpdated: DateTime.now(),
    );
  }
}

@JsonSerializable()
class MetricsModel {
  @JsonKey(name: 'average_stars')
  final double averageStars;

  @JsonKey(name: 'total_reviews')
  final int totalReviews;

  @JsonKey(name: 'positive_reviews')
  final int positiveReviews;

  @JsonKey(name: 'negative_reviews')
  final int negativeReviews;

  @JsonKey(name: 'neutral_reviews')
  final int neutralReviews;

  MetricsModel({
    required this.averageStars,
    required this.totalReviews,
    required this.positiveReviews,
    required this.negativeReviews,
    required this.neutralReviews,
  });

  factory MetricsModel.fromJson(Map<String, dynamic> json) =>
      _$MetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$MetricsModelToJson(this);

  Metrics toEntity() {
    return Metrics(
      averageStars: averageStars,
      totalReviews: totalReviews,
      positiveReviews: positiveReviews,
      negativeReviews: negativeReviews,
      neutralReviews: neutralReviews,
    );
  }
}

@JsonSerializable()
class ShopInfoModel {
  @JsonKey(name: 'shop_id')
  final String shopId;

  @JsonKey(name: 'shop_name')
  final String shopName;

  @JsonKey(name: 'shop_type')
  final String shopType;

  @JsonKey(name: 'created_at')
  final String createdAt;

  ShopInfoModel({
    required this.shopId,
    required this.shopName,
    required this.shopType,
    required this.createdAt,
  });

  factory ShopInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ShopInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopInfoModelToJson(this);

  ShopInfo toEntity() {
    return ShopInfo(
      shopId: shopId,
      shopName: shopName,
      shopType: shopType,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
