import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/assistant_response.dart';

class OnlineAPIService {
  final Dio _dio;
  final String? apiBaseUrl;
  final String? apiKey;

  OnlineAPIService({
    Dio? dio,
    this.apiBaseUrl,
    this.apiKey,
  }) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    if (apiKey != null) {
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    }
  }

  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<AssistantResponse?> process(String query, String language) async {
    
    if (!await isOnline()) {
      return null;
    }

    if (apiBaseUrl == null) {
      
      return null;
    }

    final startTime = DateTime.now();

    try {
      final response = await _dio.post(
        '$apiBaseUrl/assistant/query',
        data: {
          'query': query,
          'language': language,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200 && response.data != null) {
        return AssistantResponse(
          answer: response.data['answer'] ?? '',
          source: ResponseSource.onlineAPI,
          status: ResponseStatus.success,
          processingTimeMs: processingTime,
          relatedServiceId: response.data['relatedServiceId'],
          suggestedActions: (response.data['suggestedActions'] as List? ?? [])
              .map((e) => SuggestedAction.fromJson(e))
              .toList(),
          confidence: response.data['confidence']?.toDouble() ?? 0.8,
          metadata: response.data['metadata'],
        );
      }

      return null;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return null;
    }
  }

  AssistantResponse? _handleDioError(DioException e) {
    String errorMessage = '';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorMessage =
            'Server error (${e.response?.statusCode}). Please try again later.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Connection error. Please check your internet connection.';
        break;
      default:
        errorMessage = 'An error occurred. Please try again.';
    }

    return AssistantResponse(
      answer: errorMessage,
      source: ResponseSource.onlineAPI,
      status: ResponseStatus.failed,
      processingTimeMs: 0,
      confidence: 0.0,
      metadata: {
        'error': e.message,
        'error_type': e.type.toString(),
      },
    );
  }

  
  Future<bool> sendFeedback({
    required String responseId,
    required bool isHelpful,
    String? comment,
  }) async {
    if (!await isOnline() || apiBaseUrl == null) {
      return false;
    }

    try {
      final response = await _dio.post(
        '$apiBaseUrl/assistant/feedback',
        data: {
          'responseId': responseId,
          'isHelpful': isHelpful,
          'comment': comment,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  
  Future<void> logMetrics({
    required String query,
    required ResponseSource source,
    required int processingTimeMs,
    double? confidence,
  }) async {
    if (!await isOnline() || apiBaseUrl == null) {
      return;
    }

    try {
      await _dio.post(
        '$apiBaseUrl/assistant/metrics',
        data: {
          'query_length': query.length,
          'source': source.toString(),
          'processing_time_ms': processingTimeMs,
          'confidence': confidence,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      
    }
  }

  
  Future<Map<String, dynamic>?> syncKnowledgeBase({
    required DateTime lastSyncTime,
  }) async {
    if (!await isOnline() || apiBaseUrl == null) {
      return null;
    }

    try {
      final response = await _dio.get(
        '$apiBaseUrl/assistant/sync',
        queryParameters: {
          'last_sync': lastSyncTime.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
