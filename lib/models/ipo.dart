import '../utils/constants.dart';

class Ipo {
  final int? id;
  final String companyName;
  final String ipoType;
  final String priceBand;
  final String openDate;
  final String closeDate;
  final String? allotmentDate;
  final String? listingDate;
  final String? registrarName;
  final String? registrarUrl;
  final String ipoStatus;
  final String? notes;
  final String? externalSlug; // set when this IPO was created/synced from the IPO Guru API
  final String? gmp; // Grey Market Premium — unofficial market rumour, never treat as verified

  Ipo({
    this.id,
    required this.companyName,
    required this.ipoType,
    required this.priceBand,
    required this.openDate,
    required this.closeDate,
    this.allotmentDate,
    this.listingDate,
    this.registrarName,
    this.registrarUrl,
    required this.ipoStatus,
    this.notes,
    this.externalSlug,
    this.gmp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'ipoType': ipoType,
      'priceBand': priceBand,
      'openDate': openDate,
      'closeDate': closeDate,
      'allotmentDate': allotmentDate,
      'listingDate': listingDate,
      'registrarName': registrarName,
      'registrarUrl': registrarUrl,
      'ipoStatus': ipoStatus,
      'notes': notes,
      'externalSlug': externalSlug,
      'gmp': gmp,
    };
  }

  factory Ipo.fromMap(Map<String, dynamic> map) {
    return Ipo(
      id: map['id'] as int?,
      companyName: map['companyName'] as String? ?? '',
      ipoType: map['ipoType'] as String? ?? AppConstants.ipoTypeMainboard,
      priceBand: map['priceBand'] as String? ?? '',
      openDate: map['openDate'] as String? ?? '',
      closeDate: map['closeDate'] as String? ?? '',
      allotmentDate: map['allotmentDate'] as String?,
      listingDate: map['listingDate'] as String?,
      registrarName: map['registrarName'] as String?,
      registrarUrl: map['registrarUrl'] as String?,
      ipoStatus: map['ipoStatus'] as String? ?? AppConstants.statusUpcoming,
      notes: map['notes'] as String?,
      externalSlug: map['externalSlug'] as String?,
      gmp: map['gmp'] as String?,
    );
  }

  Ipo copyWith({
    int? id,
    String? companyName,
    String? ipoType,
    String? priceBand,
    String? openDate,
    String? closeDate,
    String? allotmentDate,
    String? listingDate,
    String? registrarName,
    String? registrarUrl,
    String? ipoStatus,
    String? notes,
    String? externalSlug,
    String? gmp,
  }) {
    return Ipo(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      ipoType: ipoType ?? this.ipoType,
      priceBand: priceBand ?? this.priceBand,
      openDate: openDate ?? this.openDate,
      closeDate: closeDate ?? this.closeDate,
      allotmentDate: allotmentDate ?? this.allotmentDate,
      listingDate: listingDate ?? this.listingDate,
      registrarName: registrarName ?? this.registrarName,
      registrarUrl: registrarUrl ?? this.registrarUrl,
      ipoStatus: ipoStatus ?? this.ipoStatus,
      notes: notes ?? this.notes,
      externalSlug: externalSlug ?? this.externalSlug,
      gmp: gmp ?? this.gmp,
    );
  }

  // Suggest status based on dates if user hasn't explicitly set it
  static String calculateSuggestedStatus(String openDateStr, String closeDateStr, String? allotmentDateStr, String? listingDateStr) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final open = DateTime.parse(openDateStr);
      final close = DateTime.parse(closeDateStr);

      final openDay = DateTime(open.year, open.month, open.day);
      final closeDay = DateTime(close.year, close.month, close.day);

      if (today.isBefore(openDay)) {
        return AppConstants.statusUpcoming;
      } else if (!today.isAfter(closeDay)) {
        return AppConstants.statusOpen;
      }

      if (listingDateStr != null && listingDateStr.isNotEmpty) {
        final listing = DateTime.parse(listingDateStr);
        final listingDay = DateTime(listing.year, listing.month, listing.day);
        if (!today.isBefore(listingDay)) {
          return AppConstants.statusListed;
        }
      }

      if (allotmentDateStr != null && allotmentDateStr.isNotEmpty) {
        final allotment = DateTime.parse(allotmentDateStr);
        final allotmentDay = DateTime(allotment.year, allotment.month, allotment.day);
        if (today.isBefore(allotmentDay) || today.isAtSameMomentAs(allotmentDay)) {
          return AppConstants.statusAllotmentPending;
        }
      }

      return AppConstants.statusClosed;
    } catch (_) {
      return AppConstants.statusUpcoming;
    }
  }
}
