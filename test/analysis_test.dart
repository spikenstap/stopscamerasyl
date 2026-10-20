import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/models/scam_analysis.dart';
import 'package:stopscam/core/utils/url_utils.dart';

import 'dart:convert';

void main() {
  final valid = <String, dynamic>{
    'riskScore': 87,
    'confidence': .9,
    'riskLevel': 'critical',
    'isScam': true,
    'category': 'phishing',
    'summary': 'Potential phishing',
    'reasons': ['Urgent request'],
    'recommendations': ['Verify independently'],
  };
  test('Risk boundaries are derived from score', () {
    for (final e in {
      0: 'safe',
      20: 'safe',
      21: 'low',
      40: 'low',
      41: 'medium',
      60: 'medium',
      61: 'high',
      80: 'high',
      81: 'critical',
      100: 'critical',
    }.entries) {
      expect(
        ScamAnalysis.fromJson({...valid, 'riskScore': e.key}).riskLevel,
        e.value,
      );
    }
  });
  test('Parses fenced JSON with braces in strings', () {
    final value = {...valid, 'summary': 'A {brace} in prose'};
    expect(
      ScamAnalysis.parse('Answer:\n```json\n${jsonEncode(value)}\n```').summary,
      'A {brace} in prose',
    );
    expect(
      ScamAnalysis.fromJson(ScamAnalysis.fromJson(valid).toJson()).riskScore,
      87,
    );
  });
  test('Rejects malformed or out-of-range analysis', () {
    for (final value in [null, -1, 101, 87.5, '87']) {
      expect(
        () => ScamAnalysis.fromJson({...valid, 'riskScore': value}),
        throwsFormatException,
      );
    }
    expect(
      () => ScamAnalysis.fromJson({
        ...valid,
        'reasons': ['ok', 5],
      }),
      throwsFormatException,
    );
    expect(() => ScamAnalysis.parse('not JSON'), throwsFormatException);
    expect(
      () => ScamAnalysis.fromJson({...valid, 'category': 'invented'}),
      throwsFormatException,
    );
  });
  test('URL normalization and independent warning signals', () {
    expect(
      UrlUtils.inspect('example.com/path').url,
      'https://example.com/path',
    );
    expect(
      UrlUtils.inspect('http://127.0.0.1/login').signals,
      containsAll(['unencrypted_http', 'ip_address_host', 'keyword:login']),
    );
    expect(
      UrlUtils.inspect('https://a.b.c.example.com/@bank').signals,
      containsAll(['many_subdomains', 'at_sign', 'keyword:bank']),
    );
    expect(
      UrlUtils.inspect('https://bit.ly/a').signals,
      contains('url_shortener'),
    );
    expect(
      UrlUtils.inspect('https://xn--e1afmkfd.xn--p1ai').signals,
      contains('unicode_or_punycode'),
    );
    for (final value in [
      '',
      'hello there',
      'javascript:alert(1)',
      'https://',
      'https://a..com',
    ]) {
      expect(() => UrlUtils.inspect(value), throwsFormatException);
    }
  });
}
