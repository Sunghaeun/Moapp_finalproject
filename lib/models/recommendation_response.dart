import 'package:json_annotation/json_annotation.dart';

part 'recommendation_response.g.dart';

@JsonSerializable(explicitToJson: true)
class RecommendationResponse {
  final String analysis;
  final String searchQuery;

  RecommendationResponse({
    required this.analysis,
    required this.searchQuery,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationResponseToJson(this);
}