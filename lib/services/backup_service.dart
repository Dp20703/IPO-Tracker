import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/ipo.dart';
import '../models/application.dart';
import '../models/registrar.dart';
import '../utils/constants.dart';

/// Summary of what happened during a restore, so the screen can show the
/// user a precise breakdown instead of a vague "done".
class RestoreResult {
  final int accountsAdded;
  final int accountsSkipped;
  final int iposAdded;
  final int iposSkipped;
  final int applicationsAdded;
  final int applicationsSkipped;
  final int registrarsAdded;
  final int registrarsSkipped;

  RestoreResult({
    required this.accountsAdded,
    required this.accountsSkipped,
    required this.iposAdded,
    required this.iposSkipped,
    required this.applicationsAdded,
    required this.applicationsSkipped,
    required this.registrarsAdded,
    required this.registrarsSkipped,
  });
}

class BackupInvalidException implements Exception {
  final String message;
  BackupInvalidException(this.message);
  @override
  String toString() => message;
}

/// Exports every table (accounts, IPOs, applications, registrars) to a
/// single JSON file the user can save anywhere via the share sheet, and
/// restores from that same file later — on this device or a new one.
///
/// This is a plain, versioned JSON format rather than a raw copy of the
/// SQLite file, so a restore still works even if a future app version
/// changes the database schema.
class BackupService {
  static const int _formatVersion = 1;

  /// Builds the backup JSON and writes it to a temporary file, ready to
  /// be handed to the OS share sheet. Returns the file.
  static Future<File> exportToFile() async {
    final db = DatabaseHelper.instance;

    final accounts = await db.getAllAccounts();
    final ipos = await db.getAllIpos();
    final applications = await db.getAllApplications();
    final registrars = await db.getAllRegistrars();

    final backup = {
      'app': 'IPO Tracker',
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'ipos': ipos.map((i) => i.toMap()).toList(),
      'applications': applications.map((a) => a.toMap()).toList(),
      'registrars': registrars.map((r) => r.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/ipo_tracker_backup_$timestamp.json');
    return file.writeAsString(jsonString);
  }

  /// Reads a backup JSON file (previously produced by [exportToFile]) and
  /// merges it into the current local database.
  ///
  /// This never overwrites or deletes existing data:
  /// - An account whose PAN already exists is skipped (its existing row
  ///   is reused so applications still link up correctly).
  /// - An IPO matching an existing one by company name + open + close
  ///   date is skipped, same reasoning.
  /// - A registrar whose name already exists is skipped.
  /// - Applications are upserted by (ipo, account) pair, same as the
  ///   rest of the app already does.
  static Future<RestoreResult> restoreFromJson(String content) async {
    late Map<String, dynamic> backup;
    try {
      backup = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw BackupInvalidException('This file is not readable as an IPO Tracker backup.');
    }

    if (backup['accounts'] is! List ||
        backup['ipos'] is! List ||
        backup['applications'] is! List ||
        backup['registrars'] is! List) {
      throw BackupInvalidException('This does not look like a valid IPO Tracker backup file.');
    }

    final db = DatabaseHelper.instance;

    final existingAccounts = await db.getAllAccounts();
    final existingIpos = await db.getAllIpos();
    final existingRegistrars = await db.getAllRegistrars();

    // Maps from the id inside the backup file to the id actually used in
    // this device's database, so applications can be relinked correctly.
    final accountIdMap = <int, int>{};
    final ipoIdMap = <int, int>{};

    int accountsAdded = 0, accountsSkipped = 0;
    int iposAdded = 0, iposSkipped = 0;
    int registrarsAdded = 0, registrarsSkipped = 0;
    int applicationsAdded = 0, applicationsSkipped = 0;

    for (final raw in backup['accounts'] as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final incoming = Account.fromMap(map);
      final oldId = map['id'] as int?;

      final match = existingAccounts.where((a) => a.panNumber == incoming.panNumber).toList();
      if (match.isNotEmpty) {
        accountsSkipped++;
        if (oldId != null && match.first.id != null) {
          accountIdMap[oldId] = match.first.id!;
        }
        continue;
      }

      final newId = await db.insertAccount(Account(
        accountHolderName: incoming.accountHolderName,
        accountNickname: incoming.accountNickname,
        panNumber: incoming.panNumber,
        dpId: incoming.dpId,
        clientId: incoming.clientId,
        brokerName: incoming.brokerName,
        notes: incoming.notes,
        createdAt: incoming.createdAt,
      ));
      accountsAdded++;
      if (oldId != null) accountIdMap[oldId] = newId;
    }

    for (final raw in backup['ipos'] as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final incoming = Ipo.fromMap(map);
      final oldId = map['id'] as int?;

      final match = existingIpos.where((i) =>
          i.companyName == incoming.companyName &&
          i.openDate == incoming.openDate &&
          i.closeDate == incoming.closeDate).toList();
      if (match.isNotEmpty) {
        iposSkipped++;
        if (oldId != null && match.first.id != null) {
          ipoIdMap[oldId] = match.first.id!;
        }
        continue;
      }

      final newId = await db.insertIpo(Ipo(
        companyName: incoming.companyName,
        ipoType: incoming.ipoType,
        priceBand: incoming.priceBand,
        openDate: incoming.openDate,
        closeDate: incoming.closeDate,
        allotmentDate: incoming.allotmentDate,
        listingDate: incoming.listingDate,
        registrarName: incoming.registrarName,
        registrarUrl: incoming.registrarUrl,
        ipoStatus: incoming.ipoStatus,
        notes: incoming.notes,
        externalSlug: incoming.externalSlug,
      ));
      iposAdded++;
      if (oldId != null) ipoIdMap[oldId] = newId;
    }

    for (final raw in backup['registrars'] as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final incoming = Registrar.fromMap(map);

      final exists = existingRegistrars.any((r) => r.name == incoming.name);
      if (exists) {
        registrarsSkipped++;
        continue;
      }
      await db.insertRegistrar(Registrar(name: incoming.name, url: incoming.url));
      registrarsAdded++;
    }

    for (final raw in backup['applications'] as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final oldIpoId = map['ipoId'] as int?;
      final oldAccountId = map['accountId'] as int?;

      final newIpoId = oldIpoId != null ? ipoIdMap[oldIpoId] : null;
      final newAccountId = oldAccountId != null ? accountIdMap[oldAccountId] : null;

      if (newIpoId == null || newAccountId == null) {
        applicationsSkipped++;
        continue;
      }

      final incoming = IpoApplication(
        ipoId: newIpoId,
        accountId: newAccountId,
        hasApplied: (map['hasApplied'] as int? ?? 0) == 1,
        lotsApplied: map['lotsApplied'] as int? ?? 1,
        applicationStatus: map['applicationStatus'] as String? ?? AppConstants.appStatusNotApplied,
        allotmentStatus: map['allotmentStatus'] as String? ?? AppConstants.allotmentNotApplied,
        sharesAllotted: map['sharesAllotted'] as int? ?? 0,
        applicationDate: map['applicationDate'] as String?,
        notes: map['notes'] as String?,
      );
      await db.insertOrUpdateApplication(incoming);
      applicationsAdded++;
    }

    return RestoreResult(
      accountsAdded: accountsAdded,
      accountsSkipped: accountsSkipped,
      iposAdded: iposAdded,
      iposSkipped: iposSkipped,
      applicationsAdded: applicationsAdded,
      applicationsSkipped: applicationsSkipped,
      registrarsAdded: registrarsAdded,
      registrarsSkipped: registrarsSkipped,
    );
  }
}
