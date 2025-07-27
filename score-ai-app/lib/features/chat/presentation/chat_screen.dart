import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/features/chat/presentation/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String jobId;
  final Map<String, dynamic> question;

  const ChatScreen({
    super.key,
    required this.jobId,
    required this.question,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];
  String streamedContent = ''; // String to accumulate streamed content
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Update UI when text changes
  }

  void _sendMessage() {
    if (_textController.text.isEmpty) return;

    final message = {
      'role': 'user',
      'content': _textController.text,
    };
    setState(() {
      _chatHistory.add(message);
      _isLoading = true;
      streamedContent = ''; // Reset streamed content for new message
    });

    final responseStream =
        ref.read(chatControllerProvider).getExplanationStream(
              jobId: widget.jobId,
              question: widget.question,
              chatHistory: _chatHistory,
            );

    // Streaming implementation as requested
    responseStream.listen((response) {
      setState(() {
        streamedContent += response; // Append each chunk to the string
      });
    }, onDone: () {
      setState(() {
        _chatHistory.add({'role': 'model', 'content': streamedContent});
        _isLoading = false;
        streamedContent = ''; // Clear after adding to history
      });
    }, onError: (error) {
      setState(() {
        _chatHistory.add({'role': 'model', 'content': 'Error: $error'});
        _isLoading = false;
        streamedContent = '';
      });
    });

    _textController.clear();
  }

  Widget _buildMarkdownContent(String content, {Color? textColor}) {
    try {
      // Use GptMarkdown without math rendering to avoid compatibility issues
      return GptMarkdown(
        content,
        style: TextStyle(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
    } catch (e) {
      // Fallback to plain text if GptMarkdown fails
      return Text(
        content,
        style: TextStyle(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show streaming content while loading
                if (_isLoading && index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildMarkdownContent(
                        streamedContent,
                        textColor: colorScheme.onSurface,
                      ),
                    ),
                  );
                }

                final message = _chatHistory.reversed
                    .toList()[index - (_isLoading ? 1 : 0)];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? colorScheme.primary
                          : colorScheme.secondary.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: isUser
                        ? Text(
                            message['content'],
                            style: const TextStyle(color: Colors.white),
                          )
                        : _buildMarkdownContent(
                            message['content'],
                            textColor: colorScheme.onSurface,
                          ),
                  ),
                );
              },
            ),
          ),
          // Input area with keyboard-aware padding
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: keyboardHeight > 0 ? keyboardHeight + 8 : 8,
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 120, // Limit height for multiline
                      ),
                      child: TextField(
                        controller: _textController,
                        enabled: !_isLoading,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        onSubmitted: (value) {
                          if (!_isLoading && value.trim().isNotEmpty) {
                            _sendMessage();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: (_isLoading || _textController.text.trim().isEmpty)
                          ? null
                          : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
