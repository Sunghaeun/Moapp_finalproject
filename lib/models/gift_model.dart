// models/gift_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'gift_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class Gift {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final int price;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final String category;
  @HiveField(6)
  final List<String> tags;
  @HiveField(7)
  final String purchaseLink;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.tags,
    required this.purchaseLink,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => _$GiftFromJson(json);
  Map<String, dynamic> toJson() => _$GiftToJson(this);
}