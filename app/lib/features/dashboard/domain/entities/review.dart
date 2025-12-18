import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String shopId;
  final String email;
  final String? phone;
  final int rating;
  final String text;
  final String sentiment;
  final String category;
  final double? qualityScore;
  final bool isProfane;
  final bool isSuspicious;
  final List<String> qualityFlags;
  final List<String> keyThemes;
  final bool contextMatch;
  final String? summary;
  final List<String>? actionableInsights;
  final String? suggestedReply;
  final DateTime createdAt;
  final String status;
  final String? rejectionReason;

  const Review({
    required this.id,
    required this.shopId,
    required this.email,
    this.phone,
    required this.rating,
    required this.text,
    required this.sentiment,
    required this.category,
    this.qualityScore,
    required this.isProfane,
    required this.isSuspicious,
    required this.qualityFlags,
    required this.keyThemes,
    required this.contextMatch,
    this.summary,
    this.actionableInsights,
    this.suggestedReply,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
    id,
    shopId,
    email,
    phone,
    rating,
    text,
    sentiment,
    category,
    qualityScore,
    isProfane,
    isSuspicious,
    qualityFlags,
    keyThemes,
    contextMatch,
    summary,
    actionableInsights,
    suggestedReply,
    createdAt,
    status,
    rejectionReason,
  ];
}
