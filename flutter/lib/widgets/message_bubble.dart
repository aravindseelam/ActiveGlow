import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../config/constants.dart';
import '../models/message_model.dart';

/// Renders a single chat bubble for either the user or Skye (bot).
class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _UserBubble(message: message) : _BotBubble(message: message);
  }
}

// ── User Bubble (right-aligned, green) ────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final MessageModel message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 60,
        right: AppConstants.paddingM,
        top: AppConstants.paddingXS,
        bottom: AppConstants.paddingXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: AppConstants.userBubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(AppConstants.radiusL),
                  topRight:    Radius.circular(AppConstants.radiusL),
                  bottomLeft:  Radius.circular(AppConstants.radiusL),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: AppConstants.userBubbleText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppConstants.brandGreenDark,
            child: const Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ],
      ),
    )
        .animate()
        .slideX(begin: 0.3, end: 0, duration: 250.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }
}

// ── Bot Bubble (left-aligned, white card) ─────────────────────────────────────
class _BotBubble extends StatelessWidget {
  final MessageModel message;
  const _BotBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.paddingM,
        right: 60,
        top: AppConstants.paddingXS,
        bottom: AppConstants.paddingXS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.brandGreen, AppConstants.brandGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppConstants.botBubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(AppConstants.radiusL),
                  topRight:    Radius.circular(AppConstants.radiusL),
                  bottomLeft:  Radius.circular(4),
                  bottomRight: Radius.circular(AppConstants.radiusL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // Use Markdown to render Skye's formatted responses (bullets, bold, etc.)
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: AppConstants.botBubbleText,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                  listBullet: const TextStyle(
                    color: AppConstants.brandGreen,
                    fontSize: 15,
                  ),
                  blockquote: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                shrinkWrap: true,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(begin: -0.3, end: 0, duration: 250.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }
}
