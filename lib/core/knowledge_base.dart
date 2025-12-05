import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/service_info.dart';

class KnowledgeBase {
  static const String _servicesBoxName = 'services';
  static const String _faqBoxName = 'faq';

  Box<ServiceInfo>? _servicesBox;
  Box<FAQItem>? _faqBox;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ServiceInfoAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FAQItemAdapter());
      }

      
      _servicesBox = await Hive.openBox<ServiceInfo>(_servicesBoxName);
      _faqBox = await Hive.openBox<FAQItem>(_faqBoxName);

      _isInitialized = true;

      
      if (_servicesBox!.isEmpty) {
        await _loadDefaultServices();
      }
      if (_faqBox!.isEmpty) {
        await _loadDefaultFAQ();
      }
    } catch (e) {
      throw Exception('Failed to initialize Knowledge Base: $e');
    }
  }

  
  Future<void> addService(ServiceInfo service) async {
    await _servicesBox?.put(service.id, service);
  }

  Future<void> addServices(List<ServiceInfo> services) async {
    for (var service in services) {
      await addService(service);
    }
  }

  ServiceInfo? getService(String id) {
    return _servicesBox?.get(id);
  }

  List<ServiceInfo> getAllServices() {
    return _servicesBox?.values.toList() ?? [];
  }

  List<ServiceInfo> searchServices(String query, String language) {
    if (_servicesBox == null) return [];

    final lowercaseQuery = query.toLowerCase();
    return _servicesBox!.values.where((service) {
      if (language == 'fr') {
        return service.nameFr.toLowerCase().contains(lowercaseQuery) ||
            service.descriptionFr.toLowerCase().contains(lowercaseQuery) ||
            service.keywordsFr
                .any((k) => k.toLowerCase().contains(lowercaseQuery));
      } else {
        return service.nameAr.contains(query) ||
            service.descriptionAr.contains(query) ||
            service.keywordsAr.any((k) => k.contains(query));
      }
    }).toList();
  }

  List<ServiceInfo> getServicesByCategory(String category) {
    return _servicesBox?.values
            .where((service) => service.category == category)
            .toList() ??
        [];
  }

  
  Future<void> addFAQ(FAQItem faq) async {
    await _faqBox?.put(faq.id, faq);
  }

  Future<void> addFAQs(List<FAQItem> faqs) async {
    for (var faq in faqs) {
      await addFAQ(faq);
    }
  }

  FAQItem? getFAQ(String id) {
    return _faqBox?.get(id);
  }

  List<FAQItem> getAllFAQs() {
    return _faqBox?.values.toList() ?? [];
  }

  List<FAQItem> searchFAQs(String query, String language) {
    if (_faqBox == null) return [];

    final lowercaseQuery = query.toLowerCase();
    return _faqBox!.values.where((faq) {
      if (language == 'fr') {
        return faq.questionFr.toLowerCase().contains(lowercaseQuery) ||
            faq.answerFr.toLowerCase().contains(lowercaseQuery) ||
            faq.tags.any((t) => t.toLowerCase().contains(lowercaseQuery));
      } else {
        return faq.questionAr.contains(query) ||
            faq.answerAr.contains(query) ||
            faq.tags.any((t) => t.contains(query));
      }
    }).toList();
  }

  Future<void> incrementFAQPopularity(String faqId) async {
    final faq = _faqBox?.get(faqId);
    if (faq != null) {
      faq.popularity++;
      await faq.save();
    }
  }

  List<FAQItem> getPopularFAQs({int limit = 10}) {
    final faqs = getAllFAQs();
    faqs.sort((a, b) => b.popularity.compareTo(a.popularity));
    return faqs.take(limit).toList();
  }

  
  Future<void> clearAll() async {
    await _servicesBox?.clear();
    await _faqBox?.clear();
  }

  Future<void> close() async {
    await _servicesBox?.close();
    await _faqBox?.close();
    _isInitialized = false;
  }

  
  Future<void> _loadDefaultServices() async {
    final categories = ['identity', 'civil_status', 'transport'];
    final allServices = <ServiceInfo>[];

    for (final category in categories) {
      try {
        final jsonString = await rootBundle
            .loadString('assets/data/services/$category.json');
        final List<dynamic> jsonData = json.decode(jsonString);

        for (final item in jsonData) {
          allServices.add(ServiceInfo(
            id: item['id'],
            nameFr: item['nameFr'],
            nameAr: item['nameAr'],
            descriptionFr: item['descriptionFr'],
            descriptionAr: item['descriptionAr'],
            keywordsFr: List<String>.from(item['keywordsFr']),
            keywordsAr: List<String>.from(item['keywordsAr']),
            category: item['category'],
            documentationUrl: item['documentationUrl'],
            requirements: List<String>.from(item['requirements']),
            processingTime: item['processingTime'],
            price: item['price'].toDouble(),
          ));
        }
      } catch (e) {
        throw Exception('Failed to load services from $category.json: $e');
      }
    }

    await addServices(allServices);
  }

  Future<void> _loadDefaultFAQ() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/faq/general.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      final faqs = jsonData.map((item) {
        return FAQItem(
          id: item['id'],
          questionFr: item['questionFr'],
          questionAr: item['questionAr'],
          answerFr: item['answerFr'],
          answerAr: item['answerAr'],
          tags: List<String>.from(item['tags']),
          relatedServiceId: item['relatedServiceId'],
          popularity: item['popularity'],
        );
      }).toList();

      await addFAQs(faqs);
    } catch (e) {
      throw Exception('Failed to load FAQ from general.json: $e');
    }
  }
}
