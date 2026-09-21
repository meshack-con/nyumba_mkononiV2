import 'dart:async';
import 'package:flutter/material.dart';

import '../services/groq_service.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  _ChatMessage({required this.role, required this.fullText, String? displayedText, this.typing = false})
      : displayedText = displayedText ?? fullText;
  final String role; // 'user' au 'assistant'
  final String fullText;
  String displayedText;
  bool typing;
}

class HelpAssistantScreen extends StatefulWidget {
  const HelpAssistantScreen({super.key});
  @override
  State<HelpAssistantScreen> createState() => _HelpAssistantScreenState();
}

class _HelpAssistantScreenState extends State<HelpAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();
    final welcome = _ChatMessage(
      role: 'assistant',
      fullText: 'Habari! Mimi ni Msaidizi wa Nyumba Mkononi. '
          'Naweza kukusaidia kuhusu kutafuta nyumba, kuweka tangazo, vichujio vya utafutaji, '
          'malipo ya tangazo, na huduma nyingine za jukwaa hili. Una swali gani leo?',
      displayedText: '',
    );
    _messages.add(welcome);
    _startTyping(welcome);
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTyping(_ChatMessage message) {
    message.typing = true;
    var index = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index >= message.fullText.length) {
        timer.cancel();
        setState(() => message.typing = false);
        return;
      }
      // Chapa herufi chache kwa wakati mmoja ili mwendo usiwe wa polepole mno
      final next = (index + 2).clamp(0, message.fullText.length);
      setState(() => message.displayedText = message.fullText.substring(0, next));
      index = next;
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    final userMessage = _ChatMessage(role: 'user', fullText: text);
    setState(() {
      _messages.add(userMessage);
      _sending = true;
    });
    _scrollToBottom();
    try {
      final history = _messages.map((m) => {'role': m.role, 'content': m.fullText}).toList();
      final reply = await GroqService.ask(history);
      final assistantMessage = _ChatMessage(role: 'assistant', fullText: reply, displayedText: '');
      setState(() => _messages.add(assistantMessage));
      _startTyping(assistantMessage);
    } on GroqException catch (error) {
      setState(() => _messages.add(_ChatMessage(role: 'assistant', fullText: error.message)));
    } catch (_) {
      setState(() => _messages.add(_ChatMessage(
            role: 'assistant',
            fullText: 'Samahani, kuna tatizo la mtandao. Jaribu tena baadaye.',
          )));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Msaada', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _bubble(_messages[index]),
            ),
          ),
          if (_sending) const Padding(padding: EdgeInsets.only(left: 16, bottom: 6), child: _TypingIndicator()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Andika swali lako kuhusu Nyumba Mkononi...',
                        filled: true,
                        fillColor: AppTheme.sand,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.sand,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: RichText(text: _parseInlineMarkdown(message.displayedText, TextStyle(color: isUser ? Colors.white : AppTheme.navy, height: 1.4, fontSize: 14.5))),
      ),
    );
  }

  /// Inageuza "**maneno**" kuwa maandishi mazito (bold) halisi, bila
  /// kuonyesha alama za nyota kwenye skrini.
  TextSpan _parseInlineMarkdown(String text, TextStyle baseStyle) {
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    final spans = <TextSpan>[];
    var lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: match.group(1), style: baseStyle.copyWith(fontWeight: FontWeight.w800)));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }
    return TextSpan(style: baseStyle, children: spans);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          const Text('Msaidizi anaandika...', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      );
}
