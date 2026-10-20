import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/common.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/scanner/phone_screen.dart';
import '../features/scanner/qr_screen.dart';
import '../features/history/history_screen.dart';
import '../features/education/education_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/result/result_screen.dart';
import '../models/scan_history_item.dart';
import '../features/numbers/numbers_screen.dart';
import '../features/numbers/number_editor.dart';
import '../features/numbers/number_details.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/phone',
        builder: (_, s) =>
            PhoneScreen(initialPhone: s.uri.queryParameters['phone']),
      ),
      GoRoute(path: '/education', builder: (_, _) => const EducationScreen()),
      GoRoute(
        path: '/number-edit',
        builder: (_, s) => NumberEditor(phone: s.uri.queryParameters['phone']),
      ),
      GoRoute(
        path: '/number-details',
        builder: (_, s) =>
            NumberDetailsScreen(phone: s.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(
        path: '/number-report',
        builder: (_, s) =>
            NumberReportEditor(phone: s.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(path: '/qr', builder: (_, _) => const QrScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (_, s) => ScannerScreen(
                  isUrl: s.uri.queryParameters['mode'] == 'url',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/numbers',
                builder: (_, _) => const NumbersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/result',
        redirect: (_, s) => s.extra is ScanHistoryItem ? null : '/history',
        pageBuilder: (_, s) => CustomTransitionPage(
          key: s.pageKey,
          child: ResultScreen(item: s.extra! as ScanHistoryItem),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: shell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          shell.goBranch(i);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: l.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            label: l.scan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.contact_phone_outlined),
            label: l.numbersNav,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l.settings,
          ),
        ],
      ),
    );
  }
}
