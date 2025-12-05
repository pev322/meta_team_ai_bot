enum ResponseSource {
  ruleBased,
  faqSearch,
  localAI,
  onlineAPI,
  fallback,
}

enum ResponseStatus {
  success,
  partial,
  failed,
}

class SuggestedAction {
  final String id;
  final String label;

  SuggestedAction({required this.id, required this.label});

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  factory SuggestedAction.fromJson(Map<String, dynamic> json) {
    return SuggestedAction(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class AssistantResponse {
  final String answer;
  final ResponseSource source;
  final ResponseStatus status;
  final int processingTimeMs;
  final String? relatedServiceId;
  final List<SuggestedAction> suggestedActions;
  final Map<String, dynamic>? metadata;
  final double? confidence;

  AssistantResponse({
    required this.answer,
    required this.source,
    required this.status,
    required this.processingTimeMs,
    this.relatedServiceId,
    this.suggestedActions = const [],
    this.metadata,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'source': source.toString(),
        'status': status.toString(),
        'processingTimeMs': processingTimeMs,
        'relatedServiceId': relatedServiceId,
        'suggestedActions': suggestedActions.map((e) => e.toJson()).toList(),
        'metadata': metadata,
        'confidence': confidence,
      };

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      answer: json['answer'] ?? '',
      source: ResponseSource.values.firstWhere(
        (e) => e.toString() == json['source'],
        orElse: () => ResponseSource.fallback,
      ),
      status: ResponseStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ResponseStatus.failed,
      ),
      processingTimeMs: json['processingTimeMs'] ?? 0,
      relatedServiceId: json['relatedServiceId'],
      suggestedActions: (json['suggestedActions'] as List? ?? [])
          .map((e) => SuggestedAction.fromJson(e))
          .toList(),
      metadata: json['metadata'],
      confidence: json['confidence']?.toDouble(),
    );
  }

  AssistantResponse copyWith({
    String? answer,
    ResponseSource? source,
    ResponseStatus? status,
    int? processingTimeMs,
    String? relatedServiceId,
    List<SuggestedAction>? suggestedActions,
    Map<String, dynamic>? metadata,
    double? confidence,
  }) {
    return AssistantResponse(
      answer: answer ?? this.answer,
      source: source ?? this.source,
      status: status ?? this.status,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      relatedServiceId: relatedServiceId ?? this.relatedServiceId,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      metadata: metadata ?? this.metadata,
      confidence: confidence ?? this.confidence,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AssistantResponse? response;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.response,
    this.isLoading = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'response': response?.toJson(),
        'isLoading': isLoading,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      response: json['response'] != null
          ? AssistantResponse.fromJson(json['response'])
          : null,
      isLoading: json['isLoading'] ?? false,
    );
  }
}
