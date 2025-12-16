// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
  id: json['_id'] as String,
  shopId: json['shop_id'] as String,
  email: json['email'] as String,
  source: json['source'] == null
      ? null
      : SourceData.fromJson(json['source'] as Map<String, dynamic>),
  processing: json['processing'] == null
      ? null
      : ProcessingData.fromJson(json['processing'] as Map<String, dynamic>),
  analysis: json['analysis'] == null
      ? null
      : AnalysisData.fromJson(json['analysis'] as Map<String, dynamic>),
  generatedContent: json['generated_content'] == null
      ? null
      : GeneratedContentData.fromJson(
          json['generated_content'] as Map<String, dynamic>,
        ),
  createdAt: json['created_at'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'shop_id': instance.shopId,
      'email': instance.email,
      'source': instance.source,
      'processing': instance.processing,
      'analysis': instance.analysis,
      'generated_content': instance.generatedContent,
      'created_at': instance.createdAt,
      'status': instance.status,
    };

SourceData _$SourceDataFromJson(Map<String, dynamic> json) =>
    SourceData(rating: (json['rating'] as num).toInt());

Map<String, dynamic> _$SourceDataToJson(SourceData instance) =>
    <String, dynamic>{'rating': instance.rating};

ProcessingData _$ProcessingDataFromJson(Map<String, dynamic> json) =>
    ProcessingData(concatenatedText: json['concatenated_text'] as String);

Map<String, dynamic> _$ProcessingDataToJson(ProcessingData instance) =>
    <String, dynamic>{'concatenated_text': instance.concatenatedText};

AnalysisData _$AnalysisDataFromJson(Map<String, dynamic> json) => AnalysisData(
  sentiment: json['sentiment'] as String,
  category: json['category'] as String,
  quality: json['quality'] == null
      ? null
      : QualityData.fromJson(json['quality'] as Map<String, dynamic>),
  context: json['context'] == null
      ? null
      : ContextData.fromJson(json['context'] as Map<String, dynamic>),
  keyThemes: (json['key_themes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AnalysisDataToJson(AnalysisData instance) =>
    <String, dynamic>{
      'sentiment': instance.sentiment,
      'category': instance.category,
      'quality': instance.quality,
      'context': instance.context,
      'key_themes': instance.keyThemes,
    };

QualityData _$QualityDataFromJson(Map<String, dynamic> json) => QualityData(
  qualityScore: (json['quality_score'] as num).toDouble(),
  isProfane: json['is_profane'] as bool,
);

Map<String, dynamic> _$QualityDataToJson(QualityData instance) =>
    <String, dynamic>{
      'quality_score': instance.qualityScore,
      'is_profane': instance.isProfane,
    };

ContextData _$ContextDataFromJson(Map<String, dynamic> json) =>
    ContextData(hasMismatch: json['has_mismatch'] as bool);

Map<String, dynamic> _$ContextDataToJson(ContextData instance) =>
    <String, dynamic>{'has_mismatch': instance.hasMismatch};

GeneratedContentData _$GeneratedContentDataFromJson(
  Map<String, dynamic> json,
) => GeneratedContentData(
  summary: json['summary'] as String?,
  actionableInsights: (json['actionable_insights'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  suggestedReply: json['suggested_reply'] as String?,
);

Map<String, dynamic> _$GeneratedContentDataToJson(
  GeneratedContentData instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'actionable_insights': instance.actionableInsights,
  'suggested_reply': instance.suggestedReply,
};
