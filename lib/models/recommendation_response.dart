import 'package:json_annotation/json_annotation.dart';

part 'recommendation_response.g.dart';

@JsonSerializable(explicitToJson: true)
class RecommendationResponse {
  final String analysis;
  final List<String> searchQueries;

  RecommendationResponse({
    required this.analysis,
    required this.searchQueries,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationResponseToJson(this);
}