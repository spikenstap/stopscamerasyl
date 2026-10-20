import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        context.go(
          ref.read(preferencesProvider).onboarded ? '/home' : '/onboarding',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.success, size: 76),
          const SizedBox(height: 20),
          Text(
            context.l.appName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    ),
  );
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  bool saving = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    setState(() => saving = true);
    await guarded(context, () async {
      await ref.read(preferencesProvider.notifier).finishOnboarding();
      if (mounted) context.go('/home');
    });
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final titles = [l.onboard1, l.onboard2, l.onboard3];
    final bodies = [l.onboardBody1, l.onboardBody2, l.onboardBody3];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: saving ? null : finish,
                    child: Text(l.skip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: List.generate(
                  3,
                  (i) => Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: .1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              [
                                Icons.shield_outlined,
                                Icons.auto_awesome,
                                Icons.verified_user_outlined,
                              ][i],
                              size: 88,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 38),
                          Text(
                            titles[i],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            bodies[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: page == i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: page == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (page == 2) {
                            finish();
                          } else {
                            controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                  child: Text(page == 2 ? l.begin : l.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
