

part of 'service_info.dart';





class ServiceInfoAdapter extends TypeAdapter<ServiceInfo> {
  @override
  final int typeId = 0;

  @override
  ServiceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceInfo(
      id: fields[0] as String,
      nameFr: fields[1] as String,
      nameAr: fields[2] as String,
      descriptionFr: fields[3] as String,
      descriptionAr: fields[4] as String,
      keywordsFr: (fields[5] as List).cast<String>(),
      keywordsAr: (fields[6] as List).cast<String>(),
      category: fields[7] as String,
      documentationUrl: fields[8] as String,
      requirements: (fields[9] as List).cast<String>(),
      processingTime: fields[10] as String,
      price: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameFr)
      ..writeByte(2)
      ..write(obj.nameAr)
      ..writeByte(3)
      ..write(obj.descriptionFr)
      ..writeByte(4)
      ..write(obj.descriptionAr)
      ..writeByte(5)
      ..write(obj.keywordsFr)
      ..writeByte(6)
      ..write(obj.keywordsAr)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.documentationUrl)
      ..writeByte(9)
      ..write(obj.requirements)
      ..writeByte(10)
      ..write(obj.processingTime)
      ..writeByte(11)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FAQItemAdapter extends TypeAdapter<FAQItem> {
  @override
  final int typeId = 1;

  @override
  FAQItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FAQItem(
      id: fields[0] as String,
      questionFr: fields[1] as String,
      questionAr: fields[2] as String,
      answerFr: fields[3] as String,
      answerAr: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
      relatedServiceId: fields[6] as String?,
      popularity: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FAQItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.questionFr)
      ..writeByte(2)
      ..write(obj.questionAr)
      ..writeByte(3)
      ..write(obj.answerFr)
      ..writeByte(4)
      ..write(obj.answerAr)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.relatedServiceId)
      ..writeByte(7)
      ..write(obj.popularity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FAQItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
