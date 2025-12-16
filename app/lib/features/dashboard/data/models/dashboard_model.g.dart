// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardModel _$DashboardModelFromJson(
  Map<String, dynamic> json,
) => DashboardModel(
  metricsData: MetricsModel.fromJson(json['metrics'] as Map<String, dynamic>),
  shopInfoData: ShopInfoModel.fromJson(
    json['shop_info'] as Map<String, dynamic>,
  ),
  qrCodeData: json['qr_code'] as String?,
  processedReviewsData: json['processed_reviews'] as List<dynamic>,
  rejectedQualityReviewsData: json['rejected_quality_reviews'] as List<dynamic>,
  rejectedIrrelevantReviewsData:
      json['rejected_irrelevant_reviews'] as List<dynamic>,
);

Map<String, dynamic> _$DashboardModelToJson(DashboardModel instance) =>
    <String, dynamic>{
      'metrics': instance.metricsData,
      'shop_info': instance.shopInfoData,
      'qr_code': instance.qrCodeData,
      'processed_reviews': instance.processedReviewsData,
      'rejected_quality_reviews': instance.rejectedQualityReviewsData,
      'rejected_irrelevant_reviews': instance.rejectedIrrelevantReviewsData,
    };

MetricsModel _$MetricsModelFromJson(Map<String, dynamic> json) => MetricsModel(
  averageStars: (json['average_stars'] as num).toDouble(),
  totalReviews: (json['total_reviews'] as num).toInt(),
  positiveReviews: (json['positive_reviews'] as num).toInt(),
  negativeReviews: (json['negative_reviews'] as num).toInt(),
  neutralReviews: (json['neutral_reviews'] as num).toInt(),
);

Map<String, dynamic> _$MetricsModelToJson(MetricsModel instance) =>
    <String, dynamic>{
      'average_stars': instance.averageStars,
      'total_reviews': instance.totalReviews,
      'positive_reviews': instance.positiveReviews,
      'negative_reviews': instance.negativeReviews,
      'neutral_reviews': instance.neutralReviews,
    };

ShopInfoModel _$ShopInfoModelFromJson(Map<String, dynamic> json) =>
    ShopInfoModel(
      shopId: json['shop_id'] as String,
      shopName: json['shop_name'] as String,
      shopType: json['shop_type'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ShopInfoModelToJson(ShopInfoModel instance) =>
    <String, dynamic>{
      'shop_id': instance.shopId,
      'shop_name': instance.shopName,
      'shop_type': instance.shopType,
      'created_at': instance.createdAt,
    };
