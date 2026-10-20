import 'package:flutter/services.dart';

class CallBridge {
  const CallBridge();
  static const channel = MethodChannel('kz.stopscam/calls');
  Future<T?> invoke<T>(String method, [dynamic args]) async {
    try {
      return await channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    }
  }

  Future<Map<dynamic, dynamic>> status() async =>
      await invoke<Map<dynamic, dynamic>>('status') ?? {};
  Future<void> cache(String number, Map<String, dynamic> reputation) async {
    try {
      await invoke<void>('cache', {'number': number, 'reputation': reputation});
    } on PlatformException {
      /* Manual analysis remains available if native caching fails. */
    }
  }
}
