import 'package:flutter/material.dart';

/// Ricostruisce da zero l'intero albero dell'app (provider compresi) leggendo
/// di nuovo lo stato salvato. Serve dopo un ripristino da cloud, un logout o
/// un reset totale: i provider hanno già letto i dati vecchi all'avvio.
class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?._restart();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
