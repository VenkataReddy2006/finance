import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Payment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double amount;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}
