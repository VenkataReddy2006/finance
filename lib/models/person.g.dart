// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 1;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[0] as String,
      sNo: fields[1] as int,
      name: fields[2] as String,
      village: fields[3] as String,
      date: fields[4] as DateTime,
      principal: fields[5] as double,
      interest: fields[6] as double,
      legacyDayOfWeek: fields[7] as int?,
      groupId: fields[9] as String,
      payments: (fields[8] as List?)?.cast<Payment>(),
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sNo)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.village)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.principal)
      ..writeByte(6)
      ..write(obj.interest)
      ..writeByte(7)
      ..write(obj.legacyDayOfWeek)
      ..writeByte(8)
      ..write(obj.payments)
      ..writeByte(9)
      ..write(obj.groupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
      id: json['id'] as String,
      sNo: (json['sNo'] as num).toInt(),
      name: json['name'] as String,
      village: json['village'] as String,
      date: DateTime.parse(json['date'] as String),
      principal: (json['principal'] as num).toDouble(),
      interest: (json['interest'] as num).toDouble(),
      legacyDayOfWeek: (json['legacyDayOfWeek'] as num?)?.toInt(),
      groupId: json['groupId'] as String,
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'id': instance.id,
      'sNo': instance.sNo,
      'name': instance.name,
      'village': instance.village,
      'date': instance.date.toIso8601String(),
      'principal': instance.principal,
      'interest': instance.interest,
      'legacyDayOfWeek': instance.legacyDayOfWeek,
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'groupId': instance.groupId,
    };
