import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';

/// Basic structure only; Home features come in a later task.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeTitle)),
      body: const SizedBox.expand(),
    );
  }
}
