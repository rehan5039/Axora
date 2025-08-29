import 'package:flutter/material.dart';

class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final EdgeInsets padding;

  const SafeAreaWrapper({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
} 