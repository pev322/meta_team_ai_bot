import 'package:hive/hive.dart';
part 'service_info.g.dart';

@HiveType(typeId: 0)
class ServiceInfo extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nameFr;

  @HiveField(2)
  String nameAr;

  @HiveField(3)
  String descriptionFr;

  @HiveField(4)
  String descriptionAr;

  @HiveField(5)
  List<String> keywordsFr;

  @HiveField(6)
  List<String> keywordsAr;

  @HiveField(7)
  String category;

  @HiveField(8)
  String documentationUrl;

  @HiveField(9)
  List<String> requirements;

  @HiveField(10)
  String processingTime;

  @HiveField(11)
  double? price;

  ServiceInfo({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.keywordsFr,
    required this.keywordsAr,
    required this.category,
    this.documentationUrl = '',
    this.requirements = const [],
    this.processingTime = '',
    this.price,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameFr': nameFr,
        'nameAr': nameAr,
        'descriptionFr': descriptionFr,
        'descriptionAr': descriptionAr,
        'keywordsFr': keywordsFr,
        'keywordsAr': keywordsAr,
        'category': category,
        'documentationUrl': documentationUrl,
        'requirements': requirements,
        'processingTime': processingTime,
        'price': price,
      };

  factory ServiceInfo.fromJson(Map<String, dynamic> json) => ServiceInfo(
        id: json['id'] ?? '',
        nameFr: json['nameFr'] ?? '',
        nameAr: json['nameAr'] ?? '',
        descriptionFr: json['descriptionFr'] ?? '',
        descriptionAr: json['descriptionAr'] ?? '',
        keywordsFr: List<String>.from(json['keywordsFr'] ?? []),
        keywordsAr: List<String>.from(json['keywordsAr'] ?? []),
        category: json['category'] ?? '',
        documentationUrl: json['documentationUrl'] ?? '',
        requirements: List<String>.from(json['requirements'] ?? []),
        processingTime: json['processingTime'] ?? '',
        price: json['price']?.toDouble(),
      );
}

@HiveType(typeId: 1)
class FAQItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String questionFr;

  @HiveField(2)
  String questionAr;

  @HiveField(3)
  String answerFr;

  @HiveField(4)
  String answerAr;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  String? relatedServiceId;

  @HiveField(7)
  int popularity;

  FAQItem({
    required this.id,
    required this.questionFr,
    required this.questionAr,
    required this.answerFr,
    required this.answerAr,
    this.tags = const [],
    this.relatedServiceId,
    this.popularity = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionFr': questionFr,
        'questionAr': questionAr,
        'answerFr': answerFr,
        'answerAr': answerAr,
        'tags': tags,
        'relatedServiceId': relatedServiceId,
        'popularity': popularity,
      };

  factory FAQItem.fromJson(Map<String, dynamic> json) => FAQItem(
        id: json['id'] ?? '',
        questionFr: json['questionFr'] ?? '',
        questionAr: json['questionAr'] ?? '',
        answerFr: json['answerFr'] ?? '',
        answerAr: json['answerAr'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        relatedServiceId: json['relatedServiceId'],
        popularity: json['popularity'] ?? 0,
      );
}
