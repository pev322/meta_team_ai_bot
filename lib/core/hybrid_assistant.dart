import 'package:flutter/foundation.dart';
import '../models/assistant_response.dart';
import '../services/rule_based_service.dart';
import '../services/faq_search_service.dart';
import '../services/local_ai_service.dart';
import '../services/online_api_service.dart';
import 'knowledge_base.dart';

class HybridAssistant {
  final KnowledgeBase knowledgeBase;
  late final RuleBasedService ruleBasedService;
  late final FAQSearchService faqSearchService;
  late final LocalAIService localAIService;
  late final OnlineAPIService onlineAPIService;

  bool _isInitialized = false;
  final List<Map<String, dynamic>> _metrics = [];

  HybridAssistant({
    required this.knowledgeBase,
    String? apiBaseUrl,
    String? apiKey,
  }) {
    ruleBasedService = RuleBasedService(knowledgeBase);
    faqSearchService = FAQSearchService(knowledgeBase);
    localAIService = LocalAIService(knowledgeBase);
    onlineAPIService = OnlineAPIService(apiBaseUrl: apiBaseUrl, apiKey: apiKey);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await knowledgeBase.initialize();

      await localAIService.initialize();

      _isInitialized = true;
      debugPrint('HybridAssistant initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize HybridAssistant: $e');
      throw Exception('Failed to initialize assistant: $e');
    }
  }

  String _cleanText(String text) {
    return text
        .replaceAll(r'$1', '')
        .replaceAll(r'$', '')
        .replaceAll(' .', '.')
        .replaceAll(' ,', ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<AssistantResponse> processQuery(String query, String language) async {
    if (!_isInitialized) {
      await initialize();
    }

    final queryStartTime = DateTime.now();
    AssistantResponse? response;

    try {
      response = await ruleBasedService.process(query, language);
      if (response != null) {
        _logMetrics(query, response, queryStartTime);
        return response;
      }
    } catch (e) {
      debugPrint('Rule-based service error: $e');
    }

    try {
      response = await faqSearchService.process(query, language);
      if (response != null) {
        _logMetrics(query, response, queryStartTime);
        return response;
      }
    } catch (e) {
      debugPrint('FAQ search service error: $e');
    }

    try {
      if (localAIService.isAvailable) {
        await Future.delayed(const Duration(milliseconds: 50));

        response = await localAIService.process(query, language);

        if (response != null && response.status != ResponseStatus.failed) {
          final cleanAnswer = _cleanText(response.answer);

          final cleanResponse = AssistantResponse(
            answer: cleanAnswer,
            source: response.source,
            status: response.status,
            processingTimeMs: response.processingTimeMs,
            confidence: response.confidence,
            suggestedActions: response.suggestedActions,
          );

          _logMetrics(query, cleanResponse, queryStartTime);
          return cleanResponse;
        }
      }
    } catch (e) {
      debugPrint('Local AI service error: $e');
    }

    try {
      response = await onlineAPIService.process(query, language);
      if (response != null && response.status != ResponseStatus.failed) {
        _logMetrics(query, response, queryStartTime);
        return response;
      }
    } catch (e) {
      debugPrint('Online API service error: $e');
    }

    final processingTime = DateTime.now()
        .difference(queryStartTime)
        .inMilliseconds;
    debugPrint(
      '[HybridAssistant] No answer found from any service. Creating fallback response.',
    );
    final fallbackResponse = _createFallbackResponse(language, processingTime);
    _logMetrics(query, fallbackResponse, queryStartTime);
    return fallbackResponse;
  }

  AssistantResponse _createFallbackResponse(
    String language,
    int processingTime,
  ) {
    debugPrint(
      '[HybridAssistant] Creating fallback response for language "$language".',
    );
    final answer = language == 'fr'
        ? 'Désolé, je n\'ai pas pu trouver une réponse précise à votre question. '
              'Voici quelques suggestions:\n\n'
              '- Reformulez votre question\n'
              '- Consultez nos services disponibles\n'
              '- Contactez notre support pour une assistance personnalisée'
        : 'عذراً، لم أتمكن من العثور على إجابة دقيقة لسؤالك. '
              'إليك بعض الاقتراحات:\n\n'
              '- أعد صياغة سؤالك\n'
              '- استعرض خدماتنا المتاحة\n'
              '- اتصل بدعمنا للحصول على مساعدة مخصصة';

    return AssistantResponse(
      answer: answer,
      source: ResponseSource.fallback,
      status: ResponseStatus.partial,
      processingTimeMs: processingTime,
      confidence: 0.0,
      suggestedActions: language == 'fr'
          ? [
              SuggestedAction(id: 'view_services', label: 'Voir les services'),
              SuggestedAction(
                id: 'frequent_questions',
                label: 'Questions fréquentes',
              ),
              SuggestedAction(
                id: 'contact_support',
                label: 'Contacter le support',
              ),
            ]
          : [
              SuggestedAction(id: 'view_services', label: 'عرض الخدمات'),
              SuggestedAction(
                id: 'frequent_questions',
                label: 'الأسئلة الشائعة',
              ),
              SuggestedAction(id: 'contact_support', label: 'الاتصال بالدعم'),
            ],
    );
  }

  void _logMetrics(
    String query,
    AssistantResponse response,
    DateTime startTime,
  ) {
    final totalTime = DateTime.now().difference(startTime).inMilliseconds;

    final metrics = {
      'query': query,
      'source': response.source.toString(),
      'processing_time': response.processingTimeMs,
      'total_time': totalTime,
      'confidence': response.confidence,
      'status': response.status.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _metrics.add(metrics);

    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }

    debugPrint('Query processed: ${response.source} in ${totalTime}ms');

    _sendMetricsToServer(query, response);
  }

  Future<void> _sendMetricsToServer(
    String query,
    AssistantResponse response,
  ) async {
    try {
      await onlineAPIService.logMetrics(
        query: query,
        source: response.source,
        processingTimeMs: response.processingTimeMs,
        confidence: response.confidence,
      );
    } catch (e) {
    }
  }

  Map<String, dynamic> getStatistics() {
    if (_metrics.isEmpty) {
      return {'total_queries': 0, 'average_time': 0, 'sources': {}};
    }

    final sourceCount = <String, int>{};
    int totalTime = 0;

    for (var metric in _metrics) {
      final source = metric['source'] as String;
      sourceCount[source] = (sourceCount[source] ?? 0) + 1;
      totalTime += metric['total_time'] as int;
    }

    return {
      'total_queries': _metrics.length,
      'average_time': totalTime / _metrics.length,
      'sources': sourceCount,
      'success_rate': _calculateSuccessRate(),
    };
  }

  double _calculateSuccessRate() {
    if (_metrics.isEmpty) return 0.0;

    int successCount = 0;
    for (var metric in _metrics) {
      if (metric['status'] == ResponseStatus.success.toString()) {
        successCount++;
      }
    }

    return successCount / _metrics.length;
  }

  List<Map<String, dynamic>> getRecentQueries({int limit = 10}) {
    return _metrics.reversed.take(limit).toList();
  }

  Future<bool> sendFeedback({
    required String responseId,
    required bool isHelpful,
    String? comment,
  }) async {
    return await onlineAPIService.sendFeedback(
      responseId: responseId,
      isHelpful: isHelpful,
      comment: comment,
    );
  }

  Future<void> syncKnowledgeBase() async {
    try {
      final syncData = await onlineAPIService.syncKnowledgeBase(
        lastSyncTime: DateTime.now().subtract(const Duration(days: 7)),
      );

      if (syncData != null) {
        debugPrint('Knowledge base synced successfully');
      }
    } catch (e) {
      debugPrint('Failed to sync knowledge base: $e');
    }
  }

  Future<void> dispose() async {
    await localAIService.dispose();
    await knowledgeBase.close();
    _isInitialized = false;
  }
}