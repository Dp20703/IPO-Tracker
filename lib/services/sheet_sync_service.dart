import 'package:http/http.dart' as http;
import '../utils/ipo_import_parser.dart';

class SheetSyncException implements Exception {
  final String message;
  SheetSyncException(this.message);
  @override
  String toString() => message;
}

/// Pulls the IPO calendar from a plain public CSV URL — typically a
/// Google Sheet the app owner maintains and publishes via
/// File > Share > Publish to web > CSV. This needs no API key and has
/// no daily call limit, because it's just a static file fetch; every
/// install can point at the same URL.
class SheetSyncService {
  static Future<List<ParsedIpoRow>> fetchAndParse(String url) async {
    if (url.trim().isEmpty) {
      throw SheetSyncException('No shared list URL set yet. Add one in More > IPO Data Sync.');
    }

    Uri uri;
    try {
      uri = Uri.parse(url.trim());
      if (!uri.isScheme('HTTP') && !uri.isScheme('HTTPS')) {
        throw const FormatException();
      }
    } catch (_) {
      throw SheetSyncException('That URL doesn\'t look valid. Check it starts with https://');
    }

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw SheetSyncException('Could not reach that URL. Check your internet connection and the link.');
    }

    if (response.statusCode != 200) {
      throw SheetSyncException('The shared list could not be loaded (HTTP ${response.statusCode}). '
          'Check the link is still published and publicly viewable.');
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw SheetSyncException('The shared list is empty.');
    }
    // A published-to-web Google Sheet that's been unpublished, or a wrong
    // link, often returns an HTML error/login page instead of a CSV.
    if (body.startsWith('<')) {
      throw SheetSyncException(
          'That link didn\'t return a CSV file (got a webpage instead). '
          'Make sure the sheet is published as CSV and shared publicly.');
    }

    return IpoImportParser.parse(body);
  }
}
