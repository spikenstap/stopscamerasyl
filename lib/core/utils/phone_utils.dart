import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class NormalizedPhone {
  const NormalizedPhone(this.number, this.country);
  final String number, country;
}

abstract final class PhoneUtils {
  static NormalizedPhone normalize(String raw) {
    var value = raw.trim();
    if (value.toLowerCase().startsWith('tel:')) value = value.substring(4);
    if (!RegExp(r'^\+?[0-9 ()\-.]+$').hasMatch(value) || value.length > 40) {
      throw const FormatException('Invalid phone');
    }
    value = value.replaceAll(RegExp(r'[ ()\-.]'), '');
    if (value.startsWith('00')) value = '+${value.substring(2)}';
    if (value.length == 11 && value.startsWith('8')) {
      value = '+7${value.substring(1)}';
    }
    if (value.length == 11 && value.startsWith('7')) value = '+$value';
    try {
      final phone = PhoneNumber.parse(value, callerCountry: IsoCode.KZ);
      if (!phone.isValid()) throw const FormatException('Invalid phone');
      return NormalizedPhone(phone.international, phone.isoCode.name);
    } on Object {
      throw const FormatException('Invalid phone');
    }
  }
}
