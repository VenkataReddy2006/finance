import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class Group extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int orderIndex;

  Group({
    required this.id,
    required this.name,
    required this.orderIndex,
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  Group copyWith({
    String? name,
    int? orderIndex,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
