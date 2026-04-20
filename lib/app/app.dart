// Root application widget.
//
// M0 placeholder: a bare MaterialApp so the scaffold launches and the smoke
// test has something to find. Theme, locale, go_router, and ProviderScope
// wiring all land in M4 per PRD → Bootstrap Sequence and Routing Structure.

import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Ledgerly',
      home: Scaffold(body: Center(child: Text('Ledgerly'))),
    );
  }
}
