import 'package:flutter/material.dart';


import '../provider_builder/provider_builder.dart';
import 'local_provider.dart';

class AppLocalProviders extends StatelessWidget {
  const AppLocalProviders({super.key, required this.child});

  final Widget Function(BuildContext context, LocaleProvider localeProvider)
  child;

  @override
  Widget build(BuildContext context) {
    return ConsumerGenerator<LocaleProvider>(
      builder: (c, provider) {
        return child(c, provider);
      },
    );
  }
}
