import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'payment.dart';

part 'person.g.dart';

@HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class Person extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int sNo;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String village;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final double principal;

  @HiveField(6)
  final double interest;

  @HiveField(7)
  final int? legacyDayOfWeek; // Keep old data at index 7

  @HiveField(8)
  final List<Payment> payments;

  @HiveField(9)
  final String groupId; // New field at index 9

  Person({
    required this.id,
    required this.sNo,
    required this.name,
    required this.village,
    required this.date,
    required this.principal,
    required this.interest,
    this.legacyDayOfWeek,
    required this.groupId,
    List<Payment>? payments,
  }) : payments = payments ?? [];

  double get totalAmount => principal + interest;

  double get totalGiven => payments.fold(0.0, (sum, p) => sum + p.amount);

  double get balance => totalAmount - totalGiven;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  Person copyWith({
    int? sNo,
    String? name,
    String? village,
    DateTime? date,
    double? principal,
    double? interest,
    String? groupId,
    List<Payment>? payments,
  }) {
    return Person(
      id: id,
      sNo: sNo ?? this.sNo,
      name: name ?? this.name,
      village: village ?? this.village,
      date: date ?? this.date,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      groupId: groupId ?? this.groupId,
      legacyDayOfWeek: legacyDayOfWeek,
      payments: payments ?? this.payments,
    );
  }
}
