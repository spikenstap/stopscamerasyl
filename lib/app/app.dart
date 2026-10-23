import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../services/call_listening_bridge.dart';
import '../localization/generated/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import '../features/settings/call_protection.dart';

class StopScamApp extends ConsumerWidget {
  const StopScamApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(backendInitializationProvider);
    final prefs = ref.watch(preferencesProvider);
    ref.listen(callListeningEventsProvider, (previous, next) {
      final event = next.asData?.value;
      final wasDanger = previous?.asData?.value['level'] == 'DANGER';
      if (event?['open'] == true ||
          (event?['level'] == 'DANGER' && !wasDanger)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(routerProvider).go('/call-listening');
        });
      }
    });
    return MaterialApp.router(
      builder: (context, child) =>
          CallEventSync(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      routerConfig: ref.watch(routerProvider),
      locale: Locale(prefs.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: prefs.theme,
    );
  }
}
