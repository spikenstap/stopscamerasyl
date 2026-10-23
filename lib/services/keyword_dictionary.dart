import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';

import '../core/api/backend_client.dart';

class KeywordDictionary {
  KeywordDictionary._(this.data);
  final Map<String, dynamic> data;
  String get lang => data['lang'] as String;
  int get version => data['version'] as int;
  bool get isEmpty =>
      (data['categories'] as List).every((c) => (c['phrases'] as List).isEmpty);
  String get json => jsonEncode(data);

  factory KeywordDictionary.parse(Map<String, dynamic> data) {
    const categories = {
      'bank_security',
      'otp',
      'remote_access',
      'authority',
      'urgency_secrecy',
      'money_transfer',
      'investment',
      'relative_emergency',
    };
    bool integer(dynamic n, int min, int max) =>
        n is int && n >= min && n <= max;
    if (!['ru', 'kk'].contains(data['lang']) ||
        !integer(data['version'], 1, 2147483647) ||
        !integer(data['cautionThreshold'], 2, 50) ||
        !integer(data['dangerThreshold'], 3, 100) ||
        (data['cautionThreshold'] as int) >= (data['dangerThreshold'] as int) ||
        data['categories'] is! List ||
        (data['categories'] as List).length != 8) {
      throw const FormatException('Invalid dictionary');
    }
    final seenCategories = <String>{}, seenPhrases = <String>{};
    final identifier = RegExp(r'^[a-z][a-z0-9_]{0,63}$');
    for (final c in data['categories'] as List) {
      if (c is! Map ||
          !categories.contains(c['id']) ||
          !seenCategories.add(c['id'] as String) ||
          c['phrases'] is! List ||
          (c['phrases'] as List).length > 100) {
        throw const FormatException('Invalid category');
      }
      for (final p in c['phrases'] as List) {
        if (p is! Map ||
            p['id'] is! String ||
            !identifier.hasMatch(p['id'] as String) ||
            !seenPhrases.add(p['id'] as String) ||
            !integer(p['weight'], 1, 5) ||
            p['variants'] is! List ||
            (p['variants'] as List).isEmpty ||
            (p['variants'] as List).length > 12) {
          throw const FormatException('Invalid phrase');
        }
        for (final v in p['variants'] as List) {
          if (v is! String || v.trim().length < 2 || v.length > 160) {
            throw const FormatException('Invalid variant');
          }
          for (final word in v.split(RegExp(r'\s+'))) {
            if (word.contains('*') &&
                (!word.endsWith('*') ||
                    '*'.allMatches(word).length != 1 ||
                    word.length < 4)) {
              throw const FormatException('Invalid stem');
            }
          }
        }
      }
    }
    return KeywordDictionary._(data);
  }
}

class KeywordDictionaryStore {
  KeywordDictionaryStore(
    this.backend, {
    DeviceCredentialStore? storage,
    Future<String> Function(String)? readAsset,
  }) : storage = storage ?? const SecureDeviceCredentialStore(),
       readAsset = readAsset ?? rootBundle.loadString;
  final BackendClient backend;
  final DeviceCredentialStore storage;
  final Future<String> Function(String) readAsset;
  final _current = <String, KeywordDictionary>{};
  final _etags = <String, String>{};
  final _updates = <String, Future<KeywordDictionary>>{};

  Future<KeywordDictionary> verify(
    Map<String, dynamic> envelope,
    String lang,
    int minimumVersion, {
    bool allowEqual = false,
  }) async {
    final encoded = envelope['payload'], signature = envelope['signature'];
    if (encoded is! String ||
        encoded.length > 32000 ||
        signature is! String ||
        signature.length > 100) {
      throw const FormatException('Invalid envelope');
    }
    final bytes = base64Decode(encoded), signed = base64Decode(signature);
    final publicKey = base64Decode(
      (await readAsset('assets/call_keywords/public_key.txt')).trim(),
    );
    if (bytes.length > 24000 ||
        signed.length != 64 ||
        publicKey.length != 32 ||
        !await Ed25519().verify(
          bytes,
          signature: Signature(
            signed,
            publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
          ),
        )) {
      throw const FormatException('Invalid signature');
    }
    final dictionary = KeywordDictionary.parse(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
    if (dictionary.lang != lang ||
        dictionary.version < minimumVersion ||
        (!allowEqual && dictionary.version == minimumVersion)) {
      throw const FormatException('Dictionary rollback');
    }
    return dictionary;
  }

  Future<KeywordDictionary> load(String lang) async {
    if (_current.containsKey(lang)) return _current[lang]!;
    if (!['ru', 'kk'].contains(lang)) {
      throw const FormatException('Invalid language');
    }
    var dictionary = KeywordDictionary.parse(
      jsonDecode(await readAsset('assets/call_keywords/$lang.json'))
          as Map<String, dynamic>,
    );
    try {
      final saved = await storage.read('stopscam.keywords.v1:$lang');
      if (saved != null) {
        final envelope = jsonDecode(saved) as Map<String, dynamic>;
        final cached = await verify(
          envelope,
          lang,
          dictionary.version,
          allowEqual: true,
        );
        if (cached.version == dictionary.version &&
            !_same(cached, dictionary)) {
          throw const FormatException('Conflicting dictionary version');
        }
        dictionary = cached;
        _etags[lang] = await _etag(envelope);
      }
    } on Object {
      // Invalid cache never replaces the dictionary bundled with the APK.
    }
    return _current[lang] = dictionary;
  }

  Future<String> _etag(Map<String, dynamic> envelope) async {
    final hash = await Sha256().hash(
      base64Decode(envelope['payload'] as String),
    );
    return '"${hash.bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join()}"';
  }

  bool _same(KeywordDictionary a, KeywordDictionary b) {
    dynamic ordered(dynamic value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: ordered(value[key])};
      }
      if (value is List) return value.map(ordered).toList();
      return value;
    }

    return jsonEncode(ordered(a.data)) == jsonEncode(ordered(b.data));
  }

  Future<KeywordDictionary> update(String lang) async {
    final pending = _updates[lang];
    if (pending != null) return pending;
    final operation = _update(lang);
    _updates[lang] = operation;
    try {
      return await operation;
    } finally {
      _updates.remove(lang);
    }
  }

  Future<KeywordDictionary> _update(String lang) async {
    final current = await load(lang);
    final envelope = await backend.keywords(
      lang,
      current.version,
      _etags[lang],
    );
    if (envelope['notModified'] == true) return current;
    final next = await verify(
      envelope,
      lang,
      current.version,
      allowEqual: true,
    );
    if (next.version == current.version && !_same(next, current)) {
      throw const FormatException('Conflicting dictionary version');
    }
    await storage.write('stopscam.keywords.v1:$lang', jsonEncode(envelope));
    _etags[lang] = await _etag(envelope);
    return _current[lang] = next;
  }
}
