import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/assistant_response.dart';
import '../core/knowledge_base.dart';

class LocalAIService {
  final KnowledgeBase knowledgeBase;
  bool _isInitialized = false;
  bool _isModelAvailable = false;

  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  List<String>? _vocabList;

  
  static const int clsTokenId = 101;  
  static const int sepTokenId = 102;  
  static const int padTokenId = 0;    
  static const int maxSequenceLength = 384;

  LocalAIService(this.knowledgeBase);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        _isModelAvailable = false;
      } else if (Platform.isAndroid || Platform.isIOS) {
        _isModelAvailable = await _initMobileModel();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Local AI: $e');
      _isModelAvailable = false;
      _isInitialized = true;
    }
  }

  Future<bool> _initMobileModel() async {
    try {
      debugPrint('Loading DistilBERT model...');
      
      
      
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      debugPrint('Model loaded successfully');

      
      await _loadVocabulary();
      debugPrint('Vocabulary loaded: ${_vocab?.length ?? 0} tokens');

      return true;
    } catch (e) {
      debugPrint('Failed to load local AI model: $e');
      return false;
    }
  }

  Future<void> _loadVocabulary() async {
    try {
      final vocabText = await rootBundle.loadString('assets/models/vocab.txt');
      final lines = vocabText.split('\n');

      _vocab = {};
      _vocabList = [];

      for (int i = 0; i < lines.length; i++) {
        final token = lines[i].trim();
        
        _vocab![token] = i;
        _vocabList!.add(token);
      }
    } catch (e) {
      debugPrint('Error loading vocabulary: $e');
      throw Exception('Failed to load vocabulary');
    }
  }

  Future<AssistantResponse?> process(String query, String language) async {
    if (!_isInitialized || !_isModelAvailable || _interpreter == null) {
      return null;
    }

    final startTime = DateTime.now();

    try {
      
      final context = _buildContext(language, query);
      if (context.isEmpty) {
        debugPrint('Empty context from knowledge base');
        return null;
      }

      
      final tokenized = _tokenizeQuestionContext(query, context);
      if (tokenized == null) {
        debugPrint('Tokenization failed');
        return null;
      }

      
      _interpreter!.allocateTensors();

      final inputIds = tokenized['input_ids'] as List<List<int>>;
      final attentionMask = tokenized['attention_mask'] as List<List<int>>;

      final startLogitsOutput = List.generate(
        1,
        (_) => List<double>.filled(maxSequenceLength, 0.0),
      );
      final endLogitsOutput = List.generate(
        1,
        (_) => List<double>.filled(maxSequenceLength, 0.0),
      );

      _interpreter!.runForMultipleInputs(
        [inputIds, attentionMask],
        {
          0: startLogitsOutput,
          1: endLogitsOutput,
        },
      );

      final startLogits = startLogitsOutput[0];
      final endLogits = endLogitsOutput[0];

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;

      
      final answer = _extractAnswer(
        tokenized['tokens'] as List<String>,
        startLogits,
        endLogits,
        tokenized['question_length'] as int,
      );

      
      
      
      if (answer != null && answer['text'].length > 2) {
        final confidence = answer['confidence'] as double;
        
        
        if (confidence > 0.5 && !answer['text'].contains('[CLS]')) {
             debugPrint('[Local AI] Found Answer: ${answer['text']} (Conf: $confidence)');
             
             return AssistantResponse(
            answer: answer['text'],
            source: ResponseSource.localAI,
            status: ResponseStatus.success,
            processingTimeMs: processingTime,
            confidence: confidence,
            metadata: {
              'note': 'Extracted by Local AI',
              'start_index': answer['start'],
              'end_index': answer['end'],
            },
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in local AI processing: $e');
      return null;
    }
  }

  
  
  String _cleanText(String text) {
    if (text.isEmpty) return "";

    
    String clean = text.toLowerCase();

    
    clean = _removeAccents(clean);

    
    
    clean = clean.replaceAll(RegExp(r"([.,!?;:()\[\]'\-])"), ' \$1 ');

    
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    return clean;
  }

  String _removeAccents(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz'; 
    
    for (int i = 0; i < withDia.length; i++) {
      if (str.contains(withDia[i])) {
        str = str.replaceAll(withDia[i], withoutDia[i]);
      }
    }
    return str;
  }

  

  String _buildContext(String language, String query) {
    final services = knowledgeBase.getAllServices();
    final faqs = knowledgeBase.getAllFAQs();
    
    
    final cleanQuery = _cleanText(query);
    final queryWords = cleanQuery.split(' ');
    
    final relevanceScores = <MapEntry<dynamic, int>>[];

    for (var service in services) {
      int score = 0;
      final serviceName = language == 'fr' 
          ? _cleanText(service.nameFr) 
          : _cleanText(service.nameAr);
      
      
      for (var word in queryWords) {
        if (word.length < 3) continue; 
        if (serviceName.contains(word)) score += 5;
      }
      relevanceScores.add(MapEntry(service, score));
    }

    relevanceScores.sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    int charCount = 0;
    
    
    const int maxChars = 1500; 

    if (language == 'fr') {
      for (var entry in relevanceScores) {
        
        if (buffer.isNotEmpty && entry.value == 0) break; 

        final service = entry.key;
        final priceText = service.price != null
            ? (service.price! > 0 ? 'cout: ${service.price!.toStringAsFixed(2)} eur. ' : 'cout: gratuit. ')
            : '';
        final timeText = service.processingTime.isNotEmpty
            ? 'delai: ${service.processingTime}. '
            : '';
        
        
        final text = 'pour ${service.nameFr}: ${service.descriptionFr} $priceText$timeText documents: ${service.requirements.join(", ")}. ';
        
        if (charCount + text.length > maxChars) break;
        buffer.write(text);
        charCount += text.length;
      }
      
      
      for (var faq in faqs) {
        final text = 'question: ${faq.questionFr} reponse: ${faq.answerFr}. ';
        if (charCount + text.length > maxChars) break;
        buffer.write(text);
        charCount += text.length;
      }
    } else {
      
      for (var entry in relevanceScores) {
        if (buffer.isNotEmpty && entry.value == 0) break;
        final service = entry.key;
         final text = 'الخدمة ${service.nameAr}: ${service.descriptionAr}. ';
        if (charCount + text.length > maxChars) break;
        buffer.write(text);
        charCount += text.length;
      }
    }

    return buffer.toString();
  }

  Map<String, dynamic>? _tokenizeQuestionContext(String question, String context) {
    if (_vocab == null || _vocabList == null) return null;

    try {
      
      final cleanQuestion = _cleanText(question);
      final cleanContext = _cleanText(context);

      final questionTokens = _tokenize(cleanQuestion);
      final contextTokens = _tokenize(cleanContext);

      
      final tokens = <String>['[CLS]'];
      tokens.addAll(questionTokens);
      tokens.add('[SEP]');

      final questionLength = tokens.length;

      tokens.addAll(contextTokens);
      tokens.add('[SEP]');

      if (tokens.length > maxSequenceLength) {
        tokens.removeRange(maxSequenceLength, tokens.length);
        
        tokens[maxSequenceLength - 1] = '[SEP]';
      }

      final inputIds = tokens.map((token) {
        return _vocab![token] ?? _vocab!['[UNK]'] ?? 100;
      }).toList();

      final attentionMask = List<int>.filled(inputIds.length, 1, growable: true);

      while (inputIds.length < maxSequenceLength) {
        inputIds.add(padTokenId);
        attentionMask.add(0);
      }

      return {
        'input_ids': [inputIds],
        'attention_mask': [attentionMask],
        'tokens': tokens,
        'question_length': questionLength,
      };
    } catch (e) {
      debugPrint('Tokenization error: $e');
      return null;
    }
  }

  List<String> _tokenize(String text) {
    final tokens = <String>[];
    
    final words = text.split(' '); 

    for (final word in words) {
      if (word.isEmpty) continue;

      if (_vocab!.containsKey(word)) {
        tokens.add(word);
      } else {
        final subwords = _tokenizeWord(word);
        tokens.addAll(subwords);
      }
    }
    return tokens;
  }

  List<String> _tokenizeWord(String word) {
    
    if (word.length > 100) return ['[UNK]'];

    final tokens = <String>[];
    bool isBad = false;
    int start = 0;
    
    final subTokens = <String>[];

    while (start < word.length) {
      int end = word.length;
      String? curSubstr;

      
      while (start < end) {
        String substr = word.substring(start, end);
        if (start > 0) {
          substr = '##$substr';
        }

        if (_vocab!.containsKey(substr)) {
          curSubstr = substr;
          break;
        }
        end--;
      }

      if (curSubstr == null) {
        isBad = true;
        break;
      }

      subTokens.add(curSubstr);
      start = end;
    }

    if (isBad) {
      return ['[UNK]'];
    }

    tokens.addAll(subTokens);
    return tokens;
  }

  Map<String, dynamic>? _extractAnswer(
    List<String> tokens,
    List<double> startLogits,
    List<double> endLogits,
    int questionLength,
  ) {
    double bestScore = double.negativeInfinity;
    int bestStart = 0;
    int bestEnd = 0;

    
    
    for (int start = questionLength; start < tokens.length - 1; start++) {
      if (tokens[start] == '[SEP]') continue;

      for (int end = start; end < math.min(start + 30, tokens.length - 1); end++) {
        if (tokens[end] == '[SEP]') break;

        final score = startLogits[start] + endLogits[end];
        if (score > bestScore) {
          bestScore = score;
          bestStart = start;
          bestEnd = end;
        }
      }
    }
    
    if (bestStart == 0 && bestEnd == 0) return null;

    final answerTokens = tokens.sublist(bestStart, bestEnd + 1);
    final List<String> words = [];
    String currentWord = '';

    for (final token in answerTokens) {
      
      if (token.startsWith('[')) continue; 

      if (token.startsWith('##')) {
        currentWord += token.substring(2);
      } else {
        if (currentWord.isNotEmpty) {
          words.add(currentWord);
        }
        currentWord = token;
      }
    }
    if (currentWord.isNotEmpty) words.add(currentWord);

    
    String answerText = words.join(' ').trim();
    answerText = answerText
        .replaceAll(RegExp(r'\s+([.,!?;:])'), '\$1') 
        .replaceAll(RegExp(r"'\s+"), "'"); 

    final confidence = _calculateConfidenceFromLogits(
      startLogits[bestStart],
      endLogits[bestEnd],
    );

    return {
      'text': answerText,
      'start': bestStart,
      'end': bestEnd,
      'confidence': confidence,
    };
  }

  double _calculateConfidenceFromLogits(double startLogit, double endLogit) {
    final score = (startLogit + endLogit) / 2.0;
    final confidence = 1.0 / (1.0 + math.exp(-score));
    return confidence.clamp(0.0, 1.0);
  }

  bool get isAvailable => _isInitialized && _isModelAvailable;

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _vocab = null;
    _vocabList = null;
    _isInitialized = false;
    _isModelAvailable = false;
  }
}