import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final Metrics metrics;
  final ShopInfo shopInfo;
  final String? qrCode;
  final List<dynamic> processedReviews;
  final List<dynamic> rejectedQualityReviews;
  final List<dynamic> rejectedIrrelevantReviews;
  final DateTime lastUpdated;

  const DashboardData({
    required this.metrics,
    required this.shopInfo,
    this.qrCode,
    required this.processedReviews,
    required this.rejectedQualityReviews,
    required this.rejectedIrrelevantReviews,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        metrics,
        shopInfo,
        qrCode,
        processedReviews,
        rejectedQualityReviews,
        rejectedIrrelevantReviews,
        lastUpdated,
      ];
}

class Metrics extends Equatable {
  final double averageStars;
  final int totalReviews;
  final int positiveReviews;
  final int negativeReviews;
  final int neutralReviews;

  const Metrics({
    required this.averageStars,
    required this.totalReviews,
    required this.positiveReviews,
    required this.negativeReviews,
    required this.neutralReviews,
  });

  @override
  List<Object?> get props => [
        averageStars,
        totalReviews,
        positiveReviews,
        negativeReviews,
        neutralReviews,
      ];
}

class ShopInfo extends Equatable {
  final String shopId;
  final String shopName;
  final String shopType;
  final DateTime createdAt;

  const ShopInfo({
    required this.shopId,
    required this.shopName,
    required this.shopType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [shopId, shopName, shopType, createdAt];
}
