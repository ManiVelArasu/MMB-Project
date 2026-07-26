import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProviderGenerator<T extends ChangeNotifier> extends StatelessWidget {
  const ProviderGenerator(
      {super.key, required this.controller, required this.builder});

  final T controller;
  final Widget Function(BuildContext c, T provider) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (_) => controller,
      builder: (context, child1) => ConsumerGenerator<T>(
          builder: (context, provider) => builder(context, provider)),
    );
  }
}

class ConsumerGenerator<T> extends StatelessWidget {
  const ConsumerGenerator({super.key, required this.builder});

  final Widget Function(BuildContext c, T provider) builder;

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
        builder: (context, provider, child2) => builder(context, provider));
  }
}

class MultiProviderGenerator extends StatelessWidget {
  const MultiProviderGenerator(
      {super.key, required this.providers, required this.builder});

  final List<ChangeNotifierProvider> providers;
  final Widget Function(
      BuildContext c,
      ) builder;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      builder: (context, child) => builder(context),
    );
  }
}
