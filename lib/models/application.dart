import '../utils/constants.dart';

class IpoApplication {
  final int? id;
  final int ipoId;
  final int accountId;
  final bool hasApplied;
  final int lotsApplied;
  final String applicationStatus;
  final String allotmentStatus;
  final int sharesAllotted;
  final String? applicationDate;
  final String? notes;

  IpoApplication({
    this.id,
    required this.ipoId,
    required this.accountId,
    this.hasApplied = false,
    this.lotsApplied = 1,
    this.applicationStatus = AppConstants.appStatusNotApplied,
    this.allotmentStatus = AppConstants.allotmentNotApplied,
    this.sharesAllotted = 0,
    this.applicationDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ipoId': ipoId,
      'accountId': accountId,
      'hasApplied': hasApplied ? 1 : 0,
      'lotsApplied': lotsApplied,
      'applicationStatus': applicationStatus,
      'allotmentStatus': allotmentStatus,
      'sharesAllotted': sharesAllotted,
      'applicationDate': applicationDate,
      'notes': notes,
    };
  }

  factory IpoApplication.fromMap(Map<String, dynamic> map) {
    return IpoApplication(
      id: map['id'] as int?,
      ipoId: map['ipoId'] as int,
      accountId: map['accountId'] as int,
      hasApplied: (map['hasApplied'] as int? ?? 0) == 1,
      lotsApplied: map['lotsApplied'] as int? ?? 1,
      applicationStatus: map['applicationStatus'] as String? ?? AppConstants.appStatusNotApplied,
      allotmentStatus: map['allotmentStatus'] as String? ?? AppConstants.allotmentNotApplied,
      sharesAllotted: map['sharesAllotted'] as int? ?? 0,
      applicationDate: map['applicationDate'] as String?,
      notes: map['notes'] as String?,
    );
  }

  IpoApplication copyWith({
    int? id,
    int? ipoId,
    int? accountId,
    bool? hasApplied,
    int? lotsApplied,
    String? applicationStatus,
    String? allotmentStatus,
    int? sharesAllotted,
    String? applicationDate,
    String? notes,
  }) {
    return IpoApplication(
      id: id ?? this.id,
      ipoId: ipoId ?? this.ipoId,
      accountId: accountId ?? this.accountId,
      hasApplied: hasApplied ?? this.hasApplied,
      lotsApplied: lotsApplied ?? this.lotsApplied,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      allotmentStatus: allotmentStatus ?? this.allotmentStatus,
      sharesAllotted: sharesAllotted ?? this.sharesAllotted,
      applicationDate: applicationDate ?? this.applicationDate,
      notes: notes ?? this.notes,
    );
  }
}
