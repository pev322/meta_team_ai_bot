import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/hybrid_assistant.dart';
import '../core/knowledge_base.dart';
import '../models/assistant_response.dart';
import '../models/service_info.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/connectivity_indicator.dart';

class ChatScreen extends StatefulWidget {
  final bool isDialog;
  // По умолчанию false, так как мы теперь используем его как главный экран
  const ChatScreen({super.key, this.isDialog = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late HybridAssistant _assistant;
  bool _isInitialized = false;
  // Добавили переменную для хранения текста ошибки
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAssistant();
  }

  Future<void> _initializeAssistant() async {
    try {
      final knowledgeBase = KnowledgeBase();
      _assistant = HybridAssistant(knowledgeBase: knowledgeBase);
      await _assistant.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null; // Сбрасываем ошибку при успехе
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize assistant: $e');
      if (mounted) {
        setState(() {
          // Показываем ошибку пользователю, вместо бесконечной загрузки
          _errorMessage = 'Initialization Error: $e';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty || !_isInitialized) return;

    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final loadingMessage = ChatMessage(
      id: 'loading',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(loadingMessage);
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final language = context.locale.languageCode;
      final response = await _assistant.processQuery(text, language);

      final assistantMessage = ChatMessage(
        id: DateTime.now().toString(),
        text: response.answer,
        isUser: false,
        timestamp: DateTime.now(),
        response: response,
      );

      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(assistantMessage);
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
      });
      debugPrint('Error processing query: $e');
      // Опционально: можно добавить сообщение об ошибке в чат
    }
  }

  void _handleSuggestedAction(SuggestedAction action) {
    debugPrint('Suggested action tapped: ${action.id}');

    switch (action.id) {
      case 'download_forms':
        _addBotMessage('Voici le lien pour télécharger les formulaires: [lien de téléchargement](https://example.com/forms)');
        break;
      case 'frequent_questions':
      case 'similar_questions':
        _showPopularQuestions();
        break;
      case 'make_appointment':
        _addBotMessage('Vous pouvez prendre rendez-vous en suivant ce lien: [Prendre rendez-vous](https://google.com)');
        break;
      case 'view_details':
      case 'more_information':
        _addBotMessage('Pour plus de détails, veuillez consulter notre site web: [Plus d\'informations](https://example.com)');
        break;
      case 'view_service':
      case 'view_services':
        _showServices();
        break;
      case 'contact_support':
        _addBotMessage('Vous pouvez contacter le support à l\'adresse suivante: support@example.com');
        break;
      default:
        // Default behavior: submit the action label as a new query
        _handleSubmit(action.label);
    }
  }

  void _addBotMessage(String text) {
    final botMessage = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(botMessage);
    });
    _scrollToBottom();
  }

  void _showPopularQuestions() {
    // This is a placeholder. In a real app, you would fetch this from the knowledge base.
    final popularQuestions = [
      'Comment renouveler mon passeport?',
      'Quels sont les documents pour une carte d\'identité?',
      'Où puis-je obtenir un acte de naissance?',
    ];

    final questionsAsMarkdown = popularQuestions.map((q) => '- $q').join('\n');
    _addBotMessage('Voici quelques questions fréquentes:\n$questionsAsMarkdown');
  }

  void _showServices() {
    final services = _assistant.knowledgeBase.getAllServices();
    final language = context.locale.languageCode;
    final serviceNames = services.map((s) => '- ${language == 'fr' ? s.nameFr : s.nameAr}').join('\n');
    _addBotMessage('Voici la liste des services disponibles:\n$serviceNames');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Основной контент чата
    Widget content = Column(
      children: [
        const ConnectivityIndicator(),
        
        // Логика отображения: Ошибка -> Загрузка -> Чат
        if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeAssistant,
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            ),
          )
        else if (!_isInitialized)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatBubble(
                        message: message.text,
                        isUser: message.isUser,
                        response: message.response,
                        timestamp: message.timestamp,
                        onSuggestedAction: _handleSuggestedAction,
                        isLoading: message.isLoading,
                      );
                    },
                  ),
          ),
          
        // Показываем поле ввода только если инициализация прошла успешно (или даже если нет, но заблокировано)
        _buildInputArea(),
      ],
    );

    // Если это используется как диалог (на всякий случай оставили поддержку)
    if (widget.isDialog) {
      return Material(
        child: content,
      );
    }

    // Стандартный Scaffold для использования на весь экран (в iframe)
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('chat.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final currentLocale = context.locale;
              final newLocale = currentLocale.languageCode == 'fr'
                  ? const Locale('ar', 'SA')
                  : const Locale('fr', 'FR');
              context.setLocale(newLocale);
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showStatistics();
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              // Блокируем ввод, если не инициализировано
              enabled: _isInitialized, 
              decoration: InputDecoration(
                hintText: tr('chat.input_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            // Блокируем кнопку
            onPressed: _isInitialized ? () => _handleSubmit(_textController.text) : null,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              tr('welcome.title'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              tr('welcome.description'),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    // Проверка на null для безопасности, если assistant не инициализирован
    if (!_isInitialized) return;

    final stats = _assistant.getStatistics();
    final successRate = (stats['success_rate'] as double? ?? 0.0) * 100;
    final avgTime = (stats['average_time'] as num? ?? 0).toDouble();
    final sources = stats['sources'] as Map? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total queries: ${stats['total_queries']}'),
            Text('Average time: ${avgTime.toStringAsFixed(0)}ms'),
            Text('Success rate: ${successRate.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            const Text('Sources:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...sources.entries.map((e) {
              return Text('${e.key}: ${e.value}');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    // Проверка на инициализацию перед вызовом dispose
    if (_isInitialized) {
      _assistant.dispose();
    }
    super.dispose();
  }
}