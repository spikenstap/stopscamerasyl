import 'dart:convert';

import '../core/api/backend_client.dart';

import '../core/storage/local_storage.dart';

class PhoneReputation {
  const PhoneReputation({
    this.status = 'unknown',
    this.confidence = 0,
    this.confirmed = false,
    this.source = '',
    this.reason = 'not_configured',
    this.expiresAt,
  });
  final String status, source, reason;
  final double confidence;
  final bool confirmed;
  final DateTime? expiresAt;
  Map<String, dynamic> toJson() => {
    'status': status,
    'confidence': confidence,
    'confirmed': confirmed,
    'source': source,
    'reason': reason,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
  };
  factory PhoneReputation.fromJson(Map<String, dynamic> j) {
    final confidence = j['confidence'];
    if (!['unknown', 'clear', 'flagged'].contains(j['status']) ||
        confidence is! num ||
        !confidence.isFinite ||
        confidence < 0 ||
        confidence > 1 ||
        j['confirmed'] is! bool ||
        j['source'] is! String ||
        (j['status'] != 'unknown' && (j['source'] as String).trim().isEmpty)) {
      throw const FormatException('Invalid reputation');
    }
    return PhoneReputation(
      status: j['status'] as String,
      confidence: confidence.toDouble(),
      confirmed: j['confirmed'] as bool,
      source: j['source'] as String,
      reason: j['reason'] as String? ?? '',
      expiresAt: j['expiresAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(j['expiresAt'] as int)
          : null,
    );
  }
}

abstract class PhoneReputationService {
  Future<PhoneReputation> checkNumber(String phoneNumber);
}

class ConfigurablePhoneReputationService implements PhoneReputationService {
  ConfigurablePhoneReputationService(this.storage, this.backend);
  final LocalStorage storage;
  final BackendClient backend;
  @override
  Future<PhoneReputation> checkNumber(String phoneNumber) async {
    if (!backend.isConfigured) return const PhoneReputation();
    final url = backend.baseUrl;
    final cacheKey = 'reputation:$url:$phoneNumber';
    final raw = storage.prefs.getString(cacheKey);
    if (raw != null) {
      try {
        final cached = PhoneReputation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        final now = DateTime.now();
        if (cached.expiresAt?.isAfter(now) == true &&
            !cached.expiresAt!.isAfter(now.add(const Duration(hours: 24)))) {
          return cached;
        }
      } on Object {
        /* Invalid cache is ignored; the provider is checked again. */
      }
    }
    try {
      final payload = await backend.post('/v1/phone/check', {
        'phoneNumber': phoneNumber,
      });
      // Cache lifetime is locally capped at 24h; providers cannot extend it.
      final expiry = DateTime.now().add(const Duration(hours: 24));
      final supplied = payload['expiresAt'];
      if (supplied != null && supplied is! int) {
        return const PhoneReputation(reason: 'unavailable');
      }
      if (supplied is int &&
          supplied <= DateTime.now().millisecondsSinceEpoch) {
        return const PhoneReputation(reason: 'unavailable');
      }
      payload['expiresAt'] =
          supplied is int && supplied < expiry.millisecondsSinceEpoch
          ? supplied
          : expiry.millisecondsSinceEpoch;
      final rep = PhoneReputation.fromJson(payload);
      await storage.setString(cacheKey, jsonEncode(rep.toJson()));
      return rep;
    } on Object {
      return const PhoneReputation(reason: 'unavailable');
    }
  }
}
