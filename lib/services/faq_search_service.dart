import 'dart:developer';
import 'package:flutter/foundation.dart';

import '../models/assistant_response.dart';
import '../models/service_info.dart';
import '../core/knowledge_base.dart';

class FAQSearchService {
  final KnowledgeBase knowledgeBase;
  
  
  static const double minRelevanceScore = kIsWeb ? 0.5 : 0.75;

  FAQSearchService(this.knowledgeBase);

  Future<AssistantResponse?> process(String query, String language) async {
    log('[FAQSearchService] Processing query: "$query"');
    final startTime = DateTime.now();

    final faqs = knowledgeBase.searchFAQs(query, language);
    log('[FAQSearchService] Found ${faqs.length} candidate FAQs.');

    if (faqs.isEmpty) {
      return null;
    }

    final scoredFAQs = faqs.map((faq) {
      final score = _calculateRelevanceScore(query, faq, language);
      log('[FAQSearchService] FAQ "${faq.id}" scored: ${score.toStringAsFixed(2)}');
      return MapEntry(faq, score);
    }).toList();

    scoredFAQs.sort((a, b) => b.value.compareTo(a.value));

    final bestMatch = scoredFAQs.first;
    log('[FAQSearchService] Best match is "${bestMatch.key.id}" with score ${bestMatch.value.toStringAsFixed(2)}');

    if (bestMatch.value < minRelevanceScore) {
      log('[FAQSearchService] Best match score is below threshold of $minRelevanceScore.');
      return null;
    }

    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    log('[FAQSearchService] Found relevant FAQ in ${processingTime}ms.');

    await knowledgeBase.incrementFAQPopularity(bestMatch.key.id);

    final answer = language == 'fr'
        ? bestMatch.key.answerFr
        : bestMatch.key.answerAr;

    return AssistantResponse(
      answer: answer,
      source: ResponseSource.faqSearch,
      status: ResponseStatus.success,
      processingTimeMs: processingTime,
      relatedServiceId: bestMatch.key.relatedServiceId,
      suggestedActions: _getSuggestedActions(bestMatch.key, language),
      confidence: bestMatch.value,
      metadata: {
        'faq_id': bestMatch.key.id,
        'score': bestMatch.value,
        'alternative_faqs': scoredFAQs
            .skip(1)
            .take(3)
            .map((e) => {
                  'id': e.key.id,
                  'question': language == 'fr'
                      ? e.key.questionFr
                      : e.key.questionAr,
                  'score': e.value,
                })
            .toList(),
      },
    );
  }

  double _calculateRelevanceScore(String query, FAQItem faq, String language) {
    final normalizedQuery = query.toLowerCase().trim();
    final question = language == 'fr'
        ? faq.questionFr.toLowerCase()
        : faq.questionAr;
    final answer = language == 'fr'
        ? faq.answerFr.toLowerCase()
        : faq.answerAr;

    final queryWords = normalizedQuery.split(RegExp(r'\s+'));
    log('[FAQSearchService] Calculating score for FAQ "${faq.id}" with ${queryWords.length} query words.');

    int questionMatches = 0;
    for (var word in queryWords) {
      if (word.length < 3) continue;
      if (question.contains(word)) {
        questionMatches++;
      }
    }
    double questionScore = (questionMatches / queryWords.length) * 0.7;
    log('[FAQSearchService] Question match score: ${questionScore.toStringAsFixed(2)} ($questionMatches matches)');

    int answerMatches = 0;
    for (var word in queryWords) {
      if (word.length < 3) continue;
      if (answer.contains(word)) {
        answerMatches++;
      }
    }
    double answerScore = (answerMatches / queryWords.length) * 0.2;
    log('[FAQSearchService] Answer match score: ${answerScore.toStringAsFixed(2)} ($answerMatches matches)');

    int tagMatches = 0;
    for (var tag in faq.tags) {
      final tagLower = tag.toLowerCase();
      for (var word in queryWords) {
        if (tagLower.contains(word)) {
          tagMatches++;
        }
      }
    }
    double tagScore = (tagMatches / queryWords.length) * 0.1;
    log('[FAQSearchService] Tag match score: ${tagScore.toStringAsFixed(2)} ($tagMatches matches)');

    final popularityBoost = (faq.popularity / 1000).clamp(0.0, 0.1);
    log('[FAQSearchService] Popularity boost: ${popularityBoost.toStringAsFixed(2)}');

    double totalScore = questionScore + answerScore + tagScore + popularityBoost;
    return totalScore.clamp(0.0, 1.0);
  }

  List<SuggestedAction> _getSuggestedActions(FAQItem faq, String language) {
    final actions = <SuggestedAction>[];

    if (language == 'fr') {
      actions.add(SuggestedAction(id: 'similar_questions', label: 'Questions similaires'));
      if (faq.relatedServiceId != null) {
        actions.add(SuggestedAction(id: 'view_service', label: 'Voir le service'));
      }
      actions.add(SuggestedAction(id: 'more_information', label: 'Plus d\'informations'));
      actions.add(SuggestedAction(id: 'contact_support', label: 'Contacter le support'));
    } else {
      actions.add(SuggestedAction(id: 'similar_questions', label: 'أسئلة مشابهة'));
      if (faq.relatedServiceId != null) {
        actions.add(SuggestedAction(id: 'view_service', label: 'عرض الخدمة'));
      }
      actions.add(SuggestedAction(id: 'more_information', label: 'مزيد من المعلومات'));
      actions.add(SuggestedAction(id: 'contact_support', label: 'الاتصال بالدعم'));
    }

    return actions;
  }

  Future<List<FAQItem>> getRelatedFAQs(String faqId, String language,
      {int limit = 5}) async {
    final faq = knowledgeBase.getFAQ(faqId);
    if (faq == null) return [];

    final allFAQs = knowledgeBase.getAllFAQs();
    final scoredFAQs = allFAQs.where((f) => f.id != faqId).map((f) {
      
      double similarity = 0.0;

      
      final commonTags =
          faq.tags.toSet().intersection(f.tags.toSet()).length;
      similarity += commonTags / faq.tags.length * 0.6;

      
      if (faq.relatedServiceId != null &&
          faq.relatedServiceId == f.relatedServiceId) {
        similarity += 0.4;
      }

      return MapEntry(f, similarity);
    }).toList();

    scoredFAQs.sort((a, b) => b.value.compareTo(a.value));

    return scoredFAQs.take(limit).map((e) => e.key).toList();
  }
}
