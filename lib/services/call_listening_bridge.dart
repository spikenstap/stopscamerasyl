import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import 'keyword_dictionary.dart';

class CallListeningBridge {
  const CallListeningBridge();
  static const channel = MethodChannel('kz.stopscam/listening');
  static const eventChannel = EventChannel('kz.stopscam/listening/events');
  Future<Map<String, dynamic>> status() async {
    try {
      return Map<String, dynamic>.from(
        await channel.invokeMapMethod('status') ?? {},
      );
    } on MissingPluginException {
      return {'available': false};
    }
  }

  Stream<Map<String, dynamic>> get events async* {
    try {
      await for (final event in eventChannel.receiveBroadcastStream()) {
        yield Map<String, dynamic>.from(event as Map);
      }
    } on MissingPluginException {
      yield {};
    }
  }

  Future<bool> permission() async =>
      await channel.invokeMethod<bool>('permission') ?? false;
  Future<void> start(KeywordDictionary dictionary, bool saveTranscript) =>
      channel.invokeMethod('start', {
        'consent': true,
        'language': dictionary.lang,
        'dictionary': dictionary.json,
        'saveTranscript': saveTranscript,
      });
  Future<void> stop() => channel.invokeMethod('stop');
  Future<String?> savedTranscript() =>
      channel.invokeMethod<String>('savedTranscript');
  Future<void> deleteTranscript() => channel.invokeMethod('deleteTranscript');
}

final callListeningProvider = Provider<CallListeningBridge>(
  (ref) => const CallListeningBridge(),
);
final callListeningEventsProvider = StreamProvider<Map<String, dynamic>>(
  (ref) => ref.watch(callListeningProvider).events,
);
final keywordDictionaryProvider = Provider<KeywordDictionaryStore>(
  (ref) => KeywordDictionaryStore(ref.watch(backendClientProvider)),
);
