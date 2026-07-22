import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onEmojiPressed;
  final VoidCallback? onVelixPressed;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSend;
  final VoidCallback? onVoice;

  const MessageInput({
    super.key,
    required this.controller,
    this.onEmojiPressed,
    this.onVelixPressed,
    this.onChanged,
    this.onSend,
    this.onVoice,
  });

  @override
  State<MessageInput> createState() =>
      _MessageInputState();
}

class _MessageInputState
    extends State<MessageInput> {

  bool get _hasText =>
      widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          12,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [

            /// Emoji
            IconButton(
              onPressed: widget.onEmojiPressed,
              icon: const Icon(
                Icons.emoji_emotions_outlined,
              ),
            ),

            /// Text Field
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: widget.onChanged,
              ),
            ),

            const SizedBox(width: 8),

            /// Velix Button
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: widget.onVelixPressed,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(
                    child: Text(
                      "Ⓥ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            /// Send / Voice
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: _hasText
                    ? widget.onSend
                    : widget.onVoice,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    _hasText
                        ? Icons.send_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
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