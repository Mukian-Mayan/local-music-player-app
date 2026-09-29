import 'package:flutter/material.dart';
import 'interactive_background.dart';

/// A Scaffold that sits on top of the interactive glow background instead
/// of a flat color. Every screen uses this in place of a plain Scaffold.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: InteractiveBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          body: body,
        ),
      ],
    );
  }
}
