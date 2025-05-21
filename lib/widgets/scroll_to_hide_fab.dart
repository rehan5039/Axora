import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollToHideFab extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Duration duration;

  const ScrollToHideFab({
    Key? key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<ScrollToHideFab> createState() => _ScrollToHideFabState();
}

class _ScrollToHideFabState extends State<ScrollToHideFab> {
  bool isVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listen);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listen);
    super.dispose();
  }

  void listen() {
    final direction = widget.controller.position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      show();
    } else if (direction == ScrollDirection.reverse) {
      hide();
    }
  }

  void show() {
    if (!isVisible) setState(() => isVisible = true);
  }

  void hide() {
    if (isVisible) setState(() => isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: widget.duration,
      offset: isVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: widget.duration,
        opacity: isVisible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
} 