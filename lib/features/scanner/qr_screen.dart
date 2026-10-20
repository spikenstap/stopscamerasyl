import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers.dart';
import '../../core/utils/qr_content.dart';
import '../../core/widgets/common.dart';
import '../../models/analysis_type.dart';
import 'scan_controller.dart';

enum QrScanState { permission, ready, scanning, decoded, analyzing, error }

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});
  @override
  ConsumerState<QrScreen> createState() => _QrState();
}

class _QrState extends ConsumerState<QrScreen> with WidgetsBindingObserver {
  final camera = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode],
  );
  StreamSubscription<BarcodeCapture>? subscription;
  String? raw;
  QrContent? decoded;
  QrScanState stage = QrScanState.permission;
  bool failed = false, permissionDenied = false, starting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    subscription = camera.barcodes.listen(detect);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      start();
    });
  }

  Future<void> start() async {
    if (starting || !mounted || raw != null) return;
    starting = true;
    try {
      await camera.start();
      if (mounted) {
        setState(() {
          stage = QrScanState.scanning;
          failed = false;
          permissionDenied = false;
        });
      }
    } on MobileScannerException catch (e) {
      if (mounted) {
        setState(() {
          stage = QrScanState.error;
          failed = true;
          permissionDenied =
              e.errorCode == MobileScannerErrorCode.permissionDenied;
        });
      }
    } finally {
      starting = false;
    }
  }

  void detect(BarcodeCapture capture) {
    if (raw != null || !mounted) return;
    final values = capture.barcodes.map((b) => b.rawValue).whereType<String>();
    if (values.isEmpty) return;
    try {
      final value = values.first;
      final qr = QrContent.decode(value);
      setState(() {
        raw = value;
        decoded = qr;
        stage = QrScanState.decoded;
      });
      unawaited(camera.stop());
    } on FormatException {
      setState(() {
        failed = true;
        stage = QrScanState.error;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!camera.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      if (raw == null) unawaited(start());
    } else {
      unawaited(camera.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(subscription?.cancel());
    unawaited(camera.dispose());
    super.dispose();
  }

  Future<void> analyze() async {
    if (raw == null) return;
    setState(() => stage = QrScanState.analyzing);
    await ref
        .read(scanProvider.notifier)
        .analyze(AnalysisInput(AnalysisType.qr, raw!), context.l);
    if (!mounted) return;
    setState(() => stage = QrScanState.decoded);
    final result = ref.read(scanProvider);
    if (result.item != null) {
      if (result.saveFailed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.saveFailed)));
      }
      await context.push('/result', extra: result.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, state = ref.watch(scanProvider);
    final busy = stage == QrScanState.analyzing;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.checkQr),
        actions: [
          ValueListenableBuilder(
            valueListenable: camera,
            builder: (context, value, _) => IconButton(
              tooltip: l.flash,
              onPressed:
                  value.isRunning && value.torchState != TorchState.unavailable
                  ? () => camera.toggleTorch()
                  : null,
              icon: Icon(
                value.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
          ),
        ],
      ),
      body: PageBody(
        children: [
          Text(l.qrSubtitle),
          const SizedBox(height: 16),
          if (raw == null)
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: camera,
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        error.errorCode ==
                                MobileScannerErrorCode.permissionDenied
                            ? l.qrPermission
                            : l.qrCameraError,
                      ),
                    ),
                  ),
                  overlayBuilder: (context, constraints) => Center(
                    child: IgnorePointer(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (failed || permissionDenied) ...[
            const SizedBox(height: 12),
            Notice(
              permissionDenied ? l.qrPermission : l.qrCameraError,
              warning: true,
            ),
            TextButton(
              onPressed: () => guarded(
                context,
                () => ref.read(callBridgeProvider).invoke<void>('settings'),
              ),
              child: Text(l.openSettings),
            ),
            TextButton(onPressed: start, child: Text(l.retry)),
          ],
          if (decoded != null) ...[
            const SizedBox(height: 16),
            PageHeading(l.qrDecoded, qrTypeLabel(context, decoded!.type.name)),
            AppCard(
              child: SelectableText(
                decoded!.type == QrContentType.wifi
                    ? l.qrWifi
                    : decoded!.type == QrContentType.contact
                    ? l.qrContact
                    : decoded!.content,
              ),
            ),
            const SizedBox(height: 16),
            if (busy) const LinearProgressIndicator(),
            if (state.failure != null)
              Notice(failureText(l, state.failure!), warning: true),
            FilledButton(
              onPressed: busy ? null : analyze,
              child: Text(busy ? l.analyzing : l.startScan),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      setState(() {
                        raw = null;
                        decoded = null;
                        failed = false;
                      });
                      ref.read(scanProvider.notifier).reset();
                      start();
                    },
              child: Text(l.scanAgain),
            ),
          ],
          const SizedBox(height: 16),
          Text(l.privacyNotice),
        ],
      ),
    );
  }
}

String qrTypeLabel(BuildContext context, String type) => switch (type) {
  'url' => context.l.linkMode,
  'text' => context.l.textMode,
  'phone' => context.l.checkPhone,
  'wifi' => context.l.qrWifi,
  'contact' => context.l.qrContact,
  'payment' => context.l.qrPayment,
  'sms' => context.l.qrSms,
  'email' => context.l.qrEmail,
  _ => context.l.qrUnknown,
};
