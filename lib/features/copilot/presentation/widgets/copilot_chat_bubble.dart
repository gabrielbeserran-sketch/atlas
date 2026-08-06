import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class CopilotChatBubble extends StatelessWidget {
  const CopilotChatBubble({
    required this.message,
    required this.onActionPressed,
    required this.onFeedback,
    super.key,
  });

  final AtlasCopilotMessage message;
  final ValueChanged<AtlasCopilotAction> onActionPressed;

  final void Function(
    String messageId,
    AtlasCopilotMessageFeedback feedback,
  ) onFeedback;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 760,
        ),
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF1B5E20)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
              isUser ? 18 : 4,
            ),
            bottomRight: Radius.circular(
              isUser ? 4 : 18,
            ),
          ),
          boxShadow: isUser
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser
                      ? Icons.person_outline
                      : Icons.auto_awesome_outlined,
                  size: 17,
                  color: isUser
                      ? Colors.white70
                      : const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 7),
                Text(
                  isUser ? 'Você' : 'Copiloto Atlas',
                  style: TextStyle(
                    color: isUser
                        ? Colors.white70
                        : const Color(0xFF1B5E20),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message.intent != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      atlasCopilotIntentLabel(
                        message.intent!,
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white54
                            : Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 9),
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : const Color(0xFF263238),
                height: 1.48,
                fontSize: 14,
              ),
            ),
            if (message.actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.actions.map((action) {
                  return OutlinedButton.icon(
                    onPressed: () {
                      onActionPressed(action);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF1B5E20),
                      side: const BorderSide(
                        color: Color(0xFF1B5E20),
                      ),
                      visualDensity:
                          VisualDensity.compact,
                    ),
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                    ),
                    label: Text(action.label),
                  );
                }).toList(),
              ),
            ],
            if (!isUser) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (message.confidence != null)
                    Expanded(
                      child: Text(
                        'Confiança: '
                        '${(message.confidence! * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 9,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  _FeedbackButton(
                    tooltip: 'Resposta útil',
                    selected: message.feedback ==
                        AtlasCopilotMessageFeedback.useful,
                    icon: Icons.thumb_up_outlined,
                    selectedIcon: Icons.thumb_up,
                    color: const Color(0xFF1B5E20),
                    onPressed: () {
                      onFeedback(
                        message.id,
                        AtlasCopilotMessageFeedback.useful,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _FeedbackButton(
                    tooltip: 'Resposta não útil',
                    selected: message.feedback ==
                        AtlasCopilotMessageFeedback.notUseful,
                    icon: Icons.thumb_down_outlined,
                    selectedIcon: Icons.thumb_down,
                    color: const Color(0xFFC62828),
                    onPressed: () {
                      onFeedback(
                        message.id,
                        AtlasCopilotMessageFeedback.notUseful,
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            selected ? selectedIcon : icon,
            size: 17,
            color: selected ? color : Colors.black38,
          ),
        ),
      ),
    );
  }
}
