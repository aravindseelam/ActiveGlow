import 'package:flutter/material.dart';
import '../config/constants.dart';

/// The bottom input bar with text field and send button.
class ChatInputField extends StatefulWidget {
  final void Function(String message) onSend;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.onSend,
    required this.isLoading,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    _controller.clear();
    setState(() => _hasText = false);
    widget.onSend(text);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingM,
        right: AppConstants.paddingM,
        top: AppConstants.paddingS,
        bottom: AppConstants.paddingS + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── Text Field ────────────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isLoading,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AppConstants.inputHint,
                  hintStyle: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    borderSide: const BorderSide(color: AppConstants.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    borderSide: const BorderSide(color: AppConstants.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    borderSide: const BorderSide(
                      color: AppConstants.brandGreen,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: widget.isLoading
                      ? AppConstants.scaffoldBg
                      : AppConstants.surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppConstants.textPrimary,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            // ── Send Button ───────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: (_hasText && !widget.isLoading)
                    ? const LinearGradient(
                        colors: [AppConstants.brandGreen, AppConstants.brandGreenDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: (_hasText && !widget.isLoading)
                    ? null
                    : AppConstants.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: (_hasText && !widget.isLoading) ? _handleSend : null,
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppConstants.brandGreen,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: _hasText
                                ? Colors.white
                                : AppConstants.textSecondary,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
