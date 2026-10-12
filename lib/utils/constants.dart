class AppConstants {
  static const String appName = 'IPO Tracker';
  static const String appSubtitle = 'Manage your IPO applications easily';

  // IPO Types
  static const String ipoTypeMainboard = 'Mainboard';
  static const String ipoTypeSme = 'SME';
  static const List<String> ipoTypes = [ipoTypeMainboard, ipoTypeSme];

  // IPO Statuses
  static const String statusUpcoming = 'UPCOMING';
  static const String statusOpen = 'OPEN';
  static const String statusClosed = 'CLOSED';
  static const String statusAllotmentPending = 'ALLOTMENT_PENDING';
  static const String statusListed = 'LISTED';

  static const List<String> ipoStatuses = [
    statusUpcoming,
    statusOpen,
    statusClosed,
    statusAllotmentPending,
    statusListed,
  ];

  // Application Statuses
  static const String appStatusNotApplied = 'NOT_APPLIED';
  static const String appStatusApplied = 'APPLIED';
  static const String appStatusSubmitted = 'SUBMITTED';
  static const String appStatusPending = 'APPLICATION_PENDING';
  static const String appStatusRejected = 'REJECTED';

  static const List<String> appStatuses = [
    appStatusNotApplied,
    appStatusApplied,
    appStatusSubmitted,
    appStatusPending,
    appStatusRejected,
  ];

  // Allotment Statuses
  static const String allotmentNotApplied = 'NOT_APPLIED';
  static const String allotmentPending = 'PENDING';
  static const String allotmentAllotted = 'ALLOTTED';
  static const String allotmentNotAllotted = 'NOT_ALLOTTED';

  static const List<String> allotmentStatuses = [
    allotmentNotApplied,
    allotmentPending,
    allotmentAllotted,
    allotmentNotAllotted,
  ];
}
