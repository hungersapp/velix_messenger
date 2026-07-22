import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool isTyping;

  const TypingIndicator({
    super.key,
    required this.isTyping,
  });

  @override
  State<TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState
    extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isTyping) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(
    covariant TypingIndicator oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTyping && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isTyping &&
        _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(
                  controller: _controller,
                  delay: 0.0,
                ),
                const SizedBox(width: 4),
                _AnimatedDot(
                  controller: _controller,
                  delay: 0.2,
                ),
                const SizedBox(width: 4),
                _AnimatedDot(
                  controller: _controller,
                  delay: 0.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _AnimatedDot({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final value =
            (controller.value + delay) % 1.0;

        final scale =
            0.6 + (value < 0.5 ? value : 1 - value);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}