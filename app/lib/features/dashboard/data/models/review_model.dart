import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/review.dart';

part 'review_model.g.dart';

@JsonSerializable()
class ReviewModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'shop_id')
  final String shopId;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'source')
  final SourceData? source;

  @JsonKey(name: 'processing')
  final ProcessingData? processing;

  @JsonKey(name: 'analysis')
  final AnalysisData? analysis;

  @JsonKey(name: 'generated_content')
  final GeneratedContentData? generatedContent;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;

  ReviewModel({
    required this.id,
    required this.shopId,
    required this.email,
    this.source,
    this.processing,
    this.analysis,
    this.generatedContent,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);

  Review toEntity() {
    return Review(
      id: id,
      shopId: shopId,
      email: email,
      phone: source?.fields?['phone']?.toString(),
      rating: source?.rating ?? 0,
      text: processing?.concatenatedText ?? '',
      sentiment: analysis?.sentiment ?? 'محايد',
      category: analysis?.category ?? 'عام',
      qualityScore: analysis?.quality?.qualityScore,
      isProfane: processing?.isProfane ?? false,
      isSuspicious: analysis?.quality?.isSuspicious ?? false,
      qualityFlags: analysis?.quality?.flags ?? [],
      keyThemes: analysis?.keyThemes ?? [],
      contextMatch: !(analysis?.context?.hasMismatch ?? false),
      summary: generatedContent?.summary,
      actionableInsights: generatedContent?.actionableInsights,
      suggestedReply: generatedContent?.suggestedReply,
      createdAt: DateTime.parse(createdAt),
      status: status,
      rejectionReason: rejectionReason,
    );
  }
}

@JsonSerializable()
class SourceData {
  final int rating;
  final Map<String, dynamic>? fields;

  SourceData({required this.rating, this.fields});

  factory SourceData.fromJson(Map<String, dynamic> json) =>
      _$SourceDataFromJson(json);

  Map<String, dynamic> toJson() => _$SourceDataToJson(this);
}

@JsonSerializable()
class ProcessingData {
  @JsonKey(name: 'concatenated_text')
  final String concatenatedText;

  @JsonKey(name: 'is_profane')
  final bool? isProfane;

  ProcessingData({required this.concatenatedText, this.isProfane});

  factory ProcessingData.fromJson(Map<String, dynamic> json) =>
      _$ProcessingDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingDataToJson(this);
}

@JsonSerializable()
class AnalysisData {
  final String sentiment;
  final String category;
  final QualityData? quality;
  final ContextData? context;

  @JsonKey(name: 'key_themes')
  final List<String>? keyThemes;

  AnalysisData({
    required this.sentiment,
    required this.category,
    this.quality,
    this.context,
    this.keyThemes,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) =>
      _$AnalysisDataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisDataToJson(this);
}

@JsonSerializable()
class QualityData {
  @JsonKey(name: 'quality_score')
  final double qualityScore;

  @JsonKey(name: 'is_profane')
  final bool? isProfane;

  @JsonKey(name: 'is_suspicious')
  final bool? isSuspicious;

  @JsonKey(name: 'flags')
  final List<String>? flags;

  QualityData({
    required this.qualityScore,
    this.isProfane,
    this.isSuspicious,
    this.flags,
  });

  factory QualityData.fromJson(Map<String, dynamic> json) =>
      _$QualityDataFromJson(json);

  Map<String, dynamic> toJson() => _$QualityDataToJson(this);
}

@JsonSerializable()
class ContextData {
  @JsonKey(name: 'has_mismatch')
  final bool hasMismatch;

  ContextData({required this.hasMismatch});

  factory ContextData.fromJson(Map<String, dynamic> json) =>
      _$ContextDataFromJson(json);

  Map<String, dynamic> toJson() => _$ContextDataToJson(this);
}

@JsonSerializable()
class GeneratedContentData {
  final String? summary;

  @JsonKey(name: 'actionable_insights')
  final List<String>? actionableInsights;

  @JsonKey(name: 'suggested_reply')
  final String? suggestedReply;

  GeneratedContentData({
    this.summary,
    this.actionableInsights,
    this.suggestedReply,
  });

  factory GeneratedContentData.fromJson(Map<String, dynamic> json) =>
      _$GeneratedContentDataFromJson(json);

  Map<String, dynamic> toJson() => _$GeneratedContentDataToJson(this);
}
