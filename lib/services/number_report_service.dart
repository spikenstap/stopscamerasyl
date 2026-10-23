import '../core/api/backend_client.dart';
import '../core/utils/phone_utils.dart';
import '../models/personal_number.dart';
import 'number_repository.dart';

enum ReportSharingResult { localOnly, shared, sharingFailed }

class NumberReportService {
  NumberReportService(this.repository, this.backend, this.sharingEnabled);
  final NumberRepository repository;
  final BackendClient backend;
  final bool Function() sharingEnabled;

  Future<ReportSharingResult> save(
    String phone,
    ReportCategory category,
    String note,
  ) async {
    final normalized = PhoneUtils.normalize(phone).number;
    await repository.report(normalized, category, note);
    if (!sharingEnabled() || category == ReportCategory.unknown) {
      return ReportSharingResult.localOnly;
    }
    try {
      final result = await backend.post('/v1/phone/report', {
        'phoneNumber': normalized,
        'category': category.name,
      });
      return result['accepted'] == true
          ? ReportSharingResult.shared
          : ReportSharingResult.sharingFailed;
    } on Object {
      // A network failure must never undo or duplicate the saved local report.
      return ReportSharingResult.sharingFailed;
    }
  }
}
