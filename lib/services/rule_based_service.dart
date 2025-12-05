import 'dart:developer';
import 'package:flutter/foundation.dart';

import '../models/assistant_response.dart';
import '../models/service_info.dart';
import '../core/knowledge_base.dart';

class RuleBasedService {
  final KnowledgeBase knowledgeBase;

  RuleBasedService(this.knowledgeBase);

  Future<AssistantResponse?> process(String query, String language) async {
    log('[RuleBasedService] Processing query: "$query"');
    final startTime = DateTime.now();

    
    final normalizedQuery = query.toLowerCase().trim();
    log('[RuleBasedService] Normalized query: "$normalizedQuery"');

    
    final matchedService = _matchService(normalizedQuery, language);

    if (matchedService != null) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      log('[RuleBasedService] Matched service "${matchedService.id}" in ${processingTime}ms.');

      final answer = _buildServiceAnswer(matchedService, language);

      return AssistantResponse(
        answer: answer,
        source: ResponseSource.ruleBased,
        status: ResponseStatus.success,
        processingTimeMs: processingTime,
        relatedServiceId: matchedService.id,
        suggestedActions: _getSuggestedActions(matchedService, language),
        confidence: 0.95,
      );
    }

    log('[RuleBasedService] No rule-based match found.');
    return null;
  }

  ServiceInfo? _matchService(String query, String language) {
    final services = knowledgeBase.getAllServices();
    final queryWords = query.split(RegExp(r'\s+'));
    log('[RuleBasedService] Matching against ${services.length} services...');

    
    final requiredMatches = kIsWeb ? 1 : 2;

    for (var service in services) {
      final keywords = language == 'fr' ? service.keywordsFr : service.keywordsAr;
      int matchCount = 0;

      for (var keyword in keywords) {
        final keywordLower = keyword.toLowerCase();
        if (queryWords.any((word) => word == keywordLower || word.startsWith(keywordLower))) {
          matchCount++;
        }
      }

      if (matchCount >= requiredMatches) {
        log('[RuleBasedService] Found match for "${service.id}" with $matchCount keyword matches (required: $requiredMatches).');
        return service;
      }

      final serviceName = language == 'fr'
          ? service.nameFr.toLowerCase()
          : service.nameAr.toLowerCase();

      if (query == serviceName || query.contains(serviceName)) {
        if (queryWords.length <= 4 || query.startsWith(serviceName)) {
          log('[RuleBasedService] Found exact match for service name "${service.id}".');
          return service;
        }
      }
    }

    return null;
  }

  String _buildServiceAnswer(ServiceInfo service, String language) {
    if (language == 'fr') {
      final buffer = StringBuffer();
      buffer.writeln('# ${service.nameFr}\n');
      buffer.writeln(service.descriptionFr);
      buffer.writeln('\n## Informations:');

      if (service.requirements.isNotEmpty) {
        buffer.writeln('\n**Documents requis:**');
        for (var req in service.requirements) {
          buffer.writeln('- $req');
        }
      }

      if (service.processingTime.isNotEmpty) {
        buffer.writeln('\n**Délai de traitement:** ${service.processingTime}');
      }

      if (service.price != null && service.price! > 0) {
        buffer.writeln('**Coût:** ${service.price!.toStringAsFixed(2)}€');
      } else if (service.price == 0) {
        buffer.writeln('**Coût:** Gratuit');
      }

      return buffer.toString();
    } else {
      final buffer = StringBuffer();
      buffer.writeln('# ${service.nameAr}\n');
      buffer.writeln(service.descriptionAr);
      buffer.writeln('\n## معلومات:');

      if (service.requirements.isNotEmpty) {
        buffer.writeln('\n**المستندات المطلوبة:**');
        for (var req in service.requirements) {
          buffer.writeln('- $req');
        }
      }

      if (service.processingTime.isNotEmpty) {
        buffer.writeln('\n**مدة المعالجة:** ${service.processingTime}');
      }

      if (service.price != null && service.price! > 0) {
        buffer.writeln('**التكلفة:** ${service.price!.toStringAsFixed(2)}€');
      } else if (service.price == 0) {
        buffer.writeln('**التكلفة:** مجاني');
      }

      return buffer.toString();
    }
  }

  List<SuggestedAction> _getSuggestedActions(ServiceInfo service, String language) {
    if (language == 'fr') {
      return [
        SuggestedAction(id: 'view_details', label: 'Voir plus de détails'),
        SuggestedAction(id: 'make_appointment', label: 'Prendre rendez-vous'),
        SuggestedAction(id: 'download_forms', label: 'Télécharger les formulaires'),
        SuggestedAction(id: 'frequent_questions', label: 'Questions fréquentes'),
      ];
    } else {
      return [
        SuggestedAction(id: 'view_details', label: 'عرض المزيد من التفاصيل'),
        SuggestedAction(id: 'make_appointment', label: 'حجز موعد'),
        SuggestedAction(id: 'download_forms', label: 'تحميل النماذج'),
        SuggestedAction(id: 'frequent_questions', label: 'الأسئلة الشائعة'),
      ];
    }
  }
}
