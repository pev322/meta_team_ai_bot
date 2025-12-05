import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/assistant_response.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final AssistantResponse? response;
  final DateTime timestamp;
  final Function(SuggestedAction)? onSuggestedAction;
  final bool isLoading;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.response,
    required this.timestamp,
    this.onSuggestedAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator(context);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                ),
              )
            else
              MarkdownBody(
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
            if (response != null && !isUser) ...[
              const SizedBox(height: 8),
              _buildResponseMetadata(context),
            ],
            if (response?.suggestedActions.isNotEmpty == true && !isUser) ...[
              const SizedBox(height: 12),
              _buildSuggestedActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              tr('chat.thinking'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseMetadata(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getSourceIcon(),
          size: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${response!.processingTimeMs}ms',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (response!.confidence != null) ...[
          const SizedBox(width: 8),
          Text(
            '${(response!.confidence! * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getSourceIcon() {
    switch (response!.source) {
      case ResponseSource.ruleBased:
        return Icons.flash_on;
      case ResponseSource.faqSearch:
        return Icons.search;
      case ResponseSource.localAI:
        return Icons.psychology;
      case ResponseSource.onlineAPI:
        return Icons.cloud;
      case ResponseSource.fallback:
        return Icons.help_outline;
    }
  }

  Widget _buildSuggestedActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: response!.suggestedActions.map((action) {
        return ActionChip(
          label: Text(
            action.label,
            style: const TextStyle(fontSize: 12),
          ),
          onPressed: () {
            if (onSuggestedAction != null) {
              onSuggestedAction!(action);
            }
          },
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        );
      }).toList(),
    );
  }
}
