import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/personal_number.dart';
import '../../services/number_repository.dart';

final numberRepositoryProvider = Provider<NumberRepository>(
  (ref) => const NumberRepository(),
);
final numbersProvider = FutureProvider<List<PersonalNumber>>(
  (ref) => ref.watch(numberRepositoryProvider).all(),
  retry: (_, _) => null,
);
final personalNumberProvider = FutureProvider.family<PersonalNumber?, String>((
  ref,
  phone,
) {
  ref.watch(numbersProvider);
  return ref.watch(numberRepositoryProvider).find(phone);
}, retry: (_, _) => null);
final numberReportsProvider = FutureProvider.family<List<NumberReport>, String>(
  (ref, phone) {
    ref.watch(numbersProvider);
    return ref.watch(numberRepositoryProvider).reports(phone);
  },
  retry: (_, _) => null,
);
