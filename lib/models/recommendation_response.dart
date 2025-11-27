import 'package:json_annotation/json_annotation.dart';

part 'recommendation_response.g.dart';

@JsonSerializable(explicitToJson: true)
class RecommendationResponse {
  final String analysis;
  final List<GiftRecommendation> recommendations;
  final List<String> followupQuestions;

  RecommendationResponse({
    required this.analysis,
    required this.recommendations,
    required this.followupQuestions,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationResponseToJson(this);
}

@JsonSerializable()
class GiftRecommendation {
  final String name;
  final String reason;
  final int price;
  final String? link;
  final List<String> alternatives;

  GiftRecommendation({
    required this.name,
    required this.reason,
    required this.price,
    this.link,
    required this.alternatives,
  });

  factory GiftRecommendation.fromJson(Map<String, dynamic> json) =>
      _$GiftRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$GiftRecommendationToJson(this);
}