import 'package:flutter/material.dart';

class CopilotInputBar extends StatefulWidget {
  const CopilotInputBar({
    required this.enabled,
    required this.onSend,
    super.key,
  });

  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  State<CopilotInputBar> createState() {
    return _CopilotInputBarState();
  }
}

class _CopilotInputBarState
    extends State<CopilotInputBar> {
  final TextEditingController controller =
      TextEditingController();

  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void submit() {
    final value = controller.text.trim();

    if (value.isEmpty || !widget.enabled) {
      return;
    }

    widget.onSend(value);
    controller.clear();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction:
                    TextInputAction.newline,
                decoration: InputDecoration(
                  hintText:
                      'Pergunte ao Copiloto Atlas...',
                  prefixIcon: const Icon(
                    Icons.chat_bubble_outline,
                  ),
                  filled: true,
                  fillColor:
                      const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  submit();
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed:
                  widget.enabled ? submit : null,
              style: IconButton.styleFrom(
                backgroundColor:
                    const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                minimumSize: const Size(
                  50,
                  50,
                ),
              ),
              icon: const Icon(
                Icons.send_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
