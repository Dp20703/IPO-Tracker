import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ipo.dart';
import '../utils/constants.dart';

/// Thrown for any problem talking to the IPO Guru API, with a message
/// that is already safe to show directly to the user.
class IpoSyncException implements Exception {
  final String message;
  IpoSyncException(this.message);

  @override
  String toString() => message;
}

/// Fetches the live IPO calendar from the IPO Guru API (api/v2) and
/// converts it into this app's local [Ipo] model.
///
/// This only ever reads the public market calendar. It never sends the
/// user's PAN, Demat, or application data anywhere.
class IpoSyncService {
  static const String _baseUrl = 'https://www.ipoguru.in/api/v2';

  /// Fetches every Mainboard + SME IPO from the calendar (no date window
  /// limit, so both recently closed and upcoming issues come back) and
  /// returns them as unsaved [Ipo] objects. Each has [Ipo.externalSlug]
  /// set so the caller can upsert against the local database.
  static Future<List<Ipo>> fetchIpoCalendar(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw IpoSyncException('No API key saved yet. Add your IPO Guru API key in More > IPO Data Sync.');
    }

    final uri = Uri.parse('$_baseUrl/ipos?months=0');

    http.Response response;
    try {
      response = await http
          .get(uri, headers: {'X-API-KEY': apiKey.trim()})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw IpoSyncException('Could not reach IPO Guru. Check your internet connection and try again.');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw IpoSyncException('IPO Guru returned an unexpected response. Please try again later.');
    }

    if (response.statusCode == 401) {
      throw IpoSyncException('No API key was sent. Please re-enter your IPO Guru API key.');
    }
    if (response.statusCode == 403) {
      throw IpoSyncException('That API key is invalid or was deactivated. Please check the key.');
    }
    if (response.statusCode == 429) {
      final code = body['error'] as String?;
      if (code == 'daily_quota_reached') {
        final resetsAt = body['resets_at'] as String?;
        throw IpoSyncException(
          'Daily sync limit reached on the free plan.'
          '${resetsAt != null ? ' Resets at $resetsAt.' : ''}',
        );
      }
      throw IpoSyncException('Too many requests. Please wait a minute and try again.');
    }
    if (response.statusCode == 402) {
      throw IpoSyncException(body['message'] as String? ?? 'Your IPO Guru plan does not include this data.');
    }
    if (response.statusCode != 200 || body['success'] != true) {
      throw IpoSyncException(body['message'] as String? ?? 'IPO Guru sync failed (HTTP ${response.statusCode}).');
    }

    final List<dynamic> data = body['data'] as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_mapApiIpoToLocal)
        .toList();
  }

  static Ipo _mapApiIpoToLocal(Map<String, dynamic> json) {
    final String slug = json['slug'] as String? ?? '';
    final String name = (json['display_name'] as String?) ?? (json['name'] as String?) ?? 'Unknown IPO';
    final String type = (json['type'] as String?) == 'SME' ? AppConstants.ipoTypeSme : AppConstants.ipoTypeMainboard;

    final String? priceBand = json['price_band'] as String?;
    final String openDate = (json['open_date'] as String?) ?? '';
    final String closeDate = (json['close_date'] as String?) ?? '';
    final String? allotmentDate = json['allotment_date'] as String?;
    final String? listingDate = json['listing_date'] as String?;

    final bool isListed = json['is_listed'] == true;
    final String apiStatus = (json['status'] as String? ?? '').toUpperCase();

    // Confirmed against the IPO Guru v2 reference: gmp is an object with
    // a "price" (string; "0" is a real nil reading, null means unknown),
    // "percentage", and "updated_at_label" for display. Read defensively
    // regardless, so an unexpected shape just leaves this blank instead
    // of failing the whole sync.
    String? gmp;
    final rawGmp = json['gmp'];
    if (rawGmp is Map) {
      final price = rawGmp['price'];
      if (price != null && price.toString().trim().isNotEmpty) {
        final percentage = rawGmp['percentage'];
        final updatedLabel = rawGmp['updated_at_label'] as String?;
        final buffer = StringBuffer('₹$price');
        if (percentage != null && percentage.toString().trim().isNotEmpty) {
          buffer.write(' (${percentage.toString()}%)');
        }
        if (updatedLabel != null && updatedLabel.isNotEmpty) {
          buffer.write(' as of $updatedLabel');
        }
        gmp = buffer.toString();
      }
    } else if (rawGmp is String && rawGmp.trim().isNotEmpty) {
      gmp = rawGmp.trim();
    }

    String status;
    if (isListed) {
      status = AppConstants.statusListed;
    } else if (apiStatus == 'CLOSED') {
      // The API only distinguishes Upcoming/Open/Closed; once closed but
      // not yet listed, treat it as allotment pending, matching how this
      // app's own date-based status suggestion behaves.
      status = AppConstants.statusAllotmentPending;
    } else if (apiStatus == 'OPEN') {
      status = AppConstants.statusOpen;
    } else {
      status = AppConstants.statusUpcoming;
    }

    return Ipo(
      companyName: name,
      ipoType: type,
      priceBand: priceBand ?? '',
      openDate: openDate,
      closeDate: closeDate,
      allotmentDate: (allotmentDate != null && allotmentDate.isNotEmpty) ? allotmentDate : null,
      listingDate: (listingDate != null && listingDate.isNotEmpty) ? listingDate : null,
      // The free plan does not include registrar contacts; the user can
      // still fill this in manually after syncing, same as any other IPO.
      registrarName: null,
      registrarUrl: null,
      ipoStatus: status,
      notes: 'Synced from IPO Guru',
      externalSlug: slug.isNotEmpty ? slug : null,
      gmp: gmp,
    );
  }
}
