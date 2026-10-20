import 'dart:io';

class UrlInspection {
  const UrlInspection(this.url, this.signals);
  final String url;
  final List<String> signals;
}

class UrlRiskSignals {
  const UrlRiskSignals(this.url, this.signals);
  final String url;
  final List<String> signals;
  Map<String, dynamic> toJson() => {'url': url, 'signals': signals};
  factory UrlRiskSignals.fromUrl(String value) {
    final inspected = UrlUtils.inspect(value);
    return UrlRiskSignals(inspected.url, inspected.signals);
  }
}

class UrlUtils {
  static UrlInspection inspect(String input) {
    var raw = input.trim();
    if (raw.isEmpty || raw.length > 4096 || RegExp(r'\s').hasMatch(raw)) {
      throw const FormatException('Invalid URL');
    }
    if (!raw.contains('://')) raw = 'https://$raw';
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        (!uri.host.contains('.') &&
            InternetAddress.tryParse(uri.host) == null) ||
        uri.host.startsWith('.') ||
        uri.host.endsWith('.') ||
        uri.host.contains('..')) {
      throw const FormatException('Invalid URL');
    }
    final host = uri.host;
    final decodedHost = Uri.decodeComponent(host);
    final ip = InternetAddress.tryParse(host);
    if (uri.port < 1 ||
        uri.port > 65535 ||
        decodedHost.length > 253 ||
        (ip == null &&
            decodedHost
                .split('.')
                .any(
                  (part) =>
                      part.isEmpty ||
                      part.length > 63 ||
                      part.startsWith('-') ||
                      part.endsWith('-') ||
                      !RegExp(r'^[a-zA-Z0-9\u0080-\uFFFF-]+$').hasMatch(part),
                ))) {
      throw const FormatException('Invalid host or port');
    }
    final signals = <String>[
      if (uri.scheme == 'http') 'unencrypted_http',
      if (raw.length > 120) 'long_url',
      if (InternetAddress.tryParse(host) != null) 'ip_address_host',
      if (host.split('.').length > 3) 'many_subdomains',
      if (RegExp(r'\d').allMatches(host).length >= 6) 'many_digits_in_host',
      if (uri.hasPort && ![80, 443].contains(uri.port)) 'unusual_port',
      if (['zip', 'mov', 'top', 'xyz', 'click'].contains(host.split('.').last))
        'tld_requires_context',
      if (raw.contains('@')) 'at_sign',
      if (RegExp(r'[^\x00-\x7F]').hasMatch(raw) || host.contains('xn--'))
        'unicode_or_punycode',
      if ([
        'bit.ly',
        't.co',
        'tinyurl.com',
        'is.gd',
        'cutt.ly',
        'shorturl.at',
      ].any((s) => host == s || host.endsWith('.$s')))
        'url_shortener',
      for (final word in [
        'login',
        'verify',
        'verification',
        'payment',
        'support',
        'secure',
        'account',
        'bank',
        'bonus',
        'gift',
        'free',
        'winner',
        'wallet',
        'crypto',
      ])
        if (raw.toLowerCase().contains(word)) 'keyword:$word',
    ];
    return UrlInspection(uri.toString(), signals);
  }

  static List<UrlRiskSignals> extract(String text) {
    final result = <UrlRiskSignals>[];
    final seen = <String>{};
    for (final match in RegExp(
      r'(?:https?://|www\.)[^\s<>]+',
      caseSensitive: false,
    ).allMatches(text)) {
      final raw = match.group(0)!.replaceFirst(RegExp(r'[.,!?)\];]+$'), '');
      try {
        final inspected = UrlRiskSignals.fromUrl(raw);
        if (seen.add(inspected.url)) result.add(inspected);
      } on FormatException {
        continue;
      }
      if (result.length == 10) break;
    }
    return result;
  }
}
