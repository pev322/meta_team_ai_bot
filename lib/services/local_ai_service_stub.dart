
import 'package:flutter/foundation.dart';
import '../models/assistant_response.dart';
import '../core/knowledge_base.dart';

class LocalAIService {
  final KnowledgeBase knowledgeBase;

  LocalAIService(this.knowledgeBase);

  Future<void> initialize() async {
    debugPrint('Local AI Service not available on web platform');
  }

  Future<AssistantResponse?> process(String query, String language) async {
    
    return null;
  }

  bool get isAvailable => false;

  Future<void> dispose() async {
    
  }
}
