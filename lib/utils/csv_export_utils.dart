import '../models/application.dart';
import '../models/account.dart';
import '../models/ipo.dart';
import 'validators.dart';

class CsvExportUtils {
  /// Escapes a single CSV field: wraps in quotes and doubles any inner
  /// quotes if the value contains a comma, quote, or newline.
  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Builds a CSV report of applications, joined against their account
  /// and IPO so it reads as one flat table. PAN numbers are masked, same
  /// as everywhere else in the app.
  static String applicationsToCsv({
    required List<IpoApplication> applications,
    required List<Account> accounts,
    required List<Ipo> ipos,
  }) {
    final headers = [
      'Company Name',
      'Account Nickname',
      'Account Holder',
      'PAN (masked)',
      'Broker',
      'Applied',
      'Lots Applied',
      'Application Status',
      'Allotment Status',
      'Shares Allotted',
      'Application Date',
      'Notes',
    ];

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escape).join(','));

    for (final app in applications) {
      final account = accounts.where((a) => a.id == app.accountId).toList();
      final ipo = ipos.where((i) => i.id == app.ipoId).toList();

      final row = [
        ipo.isNotEmpty ? ipo.first.companyName : 'Unknown IPO',
        account.isNotEmpty ? account.first.accountNickname : 'Unknown',
        account.isNotEmpty ? account.first.accountHolderName : 'Unknown',
        account.isNotEmpty ? AppValidators.maskPan(account.first.panNumber) : '',
        account.isNotEmpty ? account.first.brokerName : '',
        app.hasApplied ? 'Yes' : 'No',
        app.lotsApplied.toString(),
        app.applicationStatus,
        app.allotmentStatus,
        app.sharesAllotted.toString(),
        app.applicationDate ?? '',
        app.notes ?? '',
      ];

      buffer.writeln(row.map(_escape).join(','));
    }

    return buffer.toString();
  }
}
