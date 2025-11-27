// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationResponse _$RecommendationResponseFromJson(
        Map<String, dynamic> json) =>
    RecommendationResponse(
      analysis: json['analysis'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => GiftRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      followupQuestions: (json['followupQuestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RecommendationResponseToJson(
        RecommendationResponse instance) =>
    <String, dynamic>{
      'analysis': instance.analysis,
      'recommendations':
          instance.recommendations.map((e) => e.toJson()).toList(),
      'followupQuestions': instance.followupQuestions,
    };

GiftRecommendation _$GiftRecommendationFromJson(Map<String, dynamic> json) =>
    GiftRecommendation(
      name: json['name'] as String,
      reason: json['reason'] as String,
      price: (json['price'] as num).toInt(),
      link: json['link'] as String?,
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$GiftRecommendationToJson(GiftRecommendation instance) =>
    <String, dynamic>{
      'name': instance.name,
      'reason': instance.reason,
      'price': instance.price,
      'link': instance.link,
      'alternatives': instance.alternatives,
    };
