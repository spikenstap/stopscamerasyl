import 'phone_utils.dart';
import 'url_utils.dart';

enum QrContentType {
  url,
  text,
  phone,
  sms,
  email,
  wifi,
  contact,
  payment,
  unknown,
}

class QrContent {
  const QrContent(this.type, this.content, {this.fields = const {}});
  final QrContentType type;

  /// Safe-to-display/store content: credentials in Wi-Fi/contact codes are omitted.
  final String content;
  final Map<String, String> fields;
  static QrContent decode(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.length > 12000) {
      throw const FormatException('Invalid QR');
    }
    final upper = value.toUpperCase();
    if (upper.startsWith('WIFI:')) {
      final security =
          RegExp(r'(?:^|;)T:([^;]*)')
              .firstMatch(value.substring(5))
              ?.group(1) ??
          '';
      return QrContent(
        QrContentType.wifi,
        'WIFI: credentials omitted',
        fields: {'security': security},
      );
    }
    if (upper.startsWith('BEGIN:VCARD') || upper.startsWith('MECARD:')) {
      return const QrContent(
        QrContentType.contact,
        'Contact card: personal fields omitted',
      );
    }
    if (upper.startsWith('TEL:')) {
      return QrContent(QrContentType.phone, PhoneUtils.normalize(value).number);
    }
    if (!value.startsWith('000201') &&
        RegExp(r'^\+?\d[\d ()-]{6,}$').hasMatch(value)) {
      try {
        return QrContent(
          QrContentType.phone,
          PhoneUtils.normalize(value).number,
        );
      } on FormatException {
        return QrContent(QrContentType.unknown, value);
      }
    }
    final uri = Uri.tryParse(value);
    if (uri != null &&
        [
          'bitcoin',
          'ethereum',
          'upi',
          'pay',
          'kaspi',
        ].contains(uri.scheme.toLowerCase())) {
      return QrContent(
        QrContentType.payment,
        value,
        fields: {
          'recipient': uri.queryParameters['pa'] ?? uri.path,
          if (uri.queryParameters['amount'] ?? uri.queryParameters['am']
              case final String amount)
            'amount': amount,
        },
      );
    }
    // EMV payment QR: TLV payload, decoded locally; no payment action is available.
    if (value.startsWith('000201')) {
      final fields = <String, String>{};
      var at = 0;
      while (at + 4 <= value.length) {
        final tag = value.substring(at, at + 2);
        final length = int.tryParse(value.substring(at + 2, at + 4));
        if (length == null || at + 4 + length > value.length) break;
        final part = value.substring(at + 4, at + 4 + length);
        if (tag == '54') fields['amount'] = part;
        if (tag == '59') fields['recipient'] = part;
        at += 4 + length;
      }
      return QrContent(QrContentType.payment, value, fields: fields);
    }
    if (upper.startsWith('SMSTO:') || upper.startsWith('SMS:')) {
      return QrContent(QrContentType.sms, value);
    }
    if (upper.startsWith('MAILTO:') || upper.startsWith('MATMSG:')) {
      return QrContent(QrContentType.email, value);
    }
    try {
      return QrContent(QrContentType.url, UrlUtils.inspect(value).url);
    } on FormatException {
      return QrContent(
        uri?.hasScheme == true ? QrContentType.unknown : QrContentType.text,
        value,
      );
    }
  }
}
