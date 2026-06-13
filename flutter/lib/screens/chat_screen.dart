import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/message_model.dart';
import '../services/chat_api_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // ── State ───────────────────────────────────────────────────────────────────
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String _sessionId = '';
  bool _isTyping = false;
  bool _isConnected = true;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls down when keyboard appears
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ── Session management ─────────────────────────────────────────────────────

  Future<void> _initSession() async {
    // Restore a previous session ID so the user can continue a conversation
    // even after a hot restart (in dev) or app relaunch.
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString('session_id');

    if (existingId != null && existingId.isNotEmpty) {
      _sessionId = existingId;
    } else {
      _sessionId = const Uuid().v4();
      await prefs.setString('session_id', _sessionId);
    }

    // Check backend reachability
    final reachable = await ChatApiService.instance.isBackendReachable();
    setState(() => _isConnected = reachable);

    // Show Skye's welcome message
    _addBotMessage(AppConstants.welcomeMessage);
  }

  Future<void> _startNewConversation() async {
    // 1. Clear backend session history
    await ChatApiService.instance.clearSession(_sessionId);

    // 2. Generate a fresh session ID and save it
    _sessionId = const Uuid().v4();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', _sessionId);

    // 3. Clear local UI
    setState(() {
      _messages.clear();
      _isTyping = false;
    });

    // 4. Re-show welcome message
    _addBotMessage(AppConstants.welcomeMessage);
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  Future<void> _handleSend(String userText) async {
    if (userText.trim().isEmpty) return;

    // Add user bubble to UI immediately
    setState(() {
      _messages.add(MessageModel(
        id:         const Uuid().v4(),
        text:       userText,
        role:       MessageRole.user,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await ChatApiService.instance.sendMessage(
        sessionId: _sessionId,
        message:   userText,
      );
      _addBotMessage(reply);
    } catch (e) {
      // Catch-all block handles network exceptions, JSON formats, or server drops
      _addBotMessage(
        '⚠️ I had trouble connecting to Skye. Please try again.\n\n*Details: $e*',
      );
    } finally {
      setState(() => _isTyping = false);
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(MessageModel(
        id:         const Uuid().v4(),
        text:       text,
        role:       MessageRole.bot,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Quick suggestion chips ─────────────────────────────────────────────────

  static const List<String> _suggestions = [
    '🧴 Show me your products',
    '💪 Post-workout routine',
    '🌙 Nighttime skincare',
    '☀️ Best SPF for outdoor sports',
    '💧 Fix my dry skin',
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppConstants.scaffoldBg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // ── Connection warning banner ───────────────────────────────
            if (!_isConnected)
              _ConnectionBanner(onRetry: _retryConnection),

            // ── Message list ───────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingM,
                      ),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == _messages.length) {
                          return const TypingIndicator();
                        }
                        return MessageBubble(message: _messages[index]);
                      },
                    ),
            ),

            // ── Suggestion chips (only when < 2 messages) ─────────────
            if (_messages.length <= 1 && !_isTyping)
              _SuggestionChips(
                suggestions: _suggestions,
                onTap: _handleSend,
              ),

            // ── Input field ────────────────────────────────────────────
            ChatInputField(
              onSend:    _handleSend,
              isLoading: _isTyping,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConstants.brandGreen, AppConstants.brandGreenDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          // Bot avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConstants.botName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8FFE1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    AppConstants.botSubtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // New conversation button
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
          tooltip: 'New conversation',
          onPressed: () => _showNewConversationDialog(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Conversation'),
        content: const Text(
          'Start fresh? This will clear your current chat history with Skye.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.brandGreen,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _startNewConversation();
            },
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryConnection() async {
    final reachable = await ChatApiService.instance.isBackendReachable();
    setState(() => _isConnected = reachable);
    if (reachable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Connected to Skye!')),
      );
    }
  }
}

// ── Suggestion chips ──────────────────────────────────────────────────────────
class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;

  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          return ActionChip(
            label: Text(
              suggestions[i],
              style: const TextStyle(fontSize: 13),
            ),
            backgroundColor: AppConstants.brandGreenLight,
            side: BorderSide(color: AppConstants.brandGreen.withOpacity(0.4)),
            onPressed: () => onTap(
              suggestions[i].replaceAll(RegExp(r'[^\w\s,\?!]'), '').trim(),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

// ── Connection warning banner ─────────────────────────────────────────────────
class _ConnectionBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ConnectionBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingXS,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Cannot reach Skye backend. Check your API URL in constants.dart.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.brandGreen, AppConstants.brandGreenDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          const Text(
            'Loading Skye…',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }
}
