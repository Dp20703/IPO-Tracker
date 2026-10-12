import '../models/ipo.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// Result of parsing one non-blank line of pasted IPO data.
class ParsedIpoRow {
  final int lineNumber;
  final String rawLine;
  final Ipo? ipo;
  final String? error;

  ParsedIpoRow({
    required this.lineNumber,
    required this.rawLine,
    this.ipo,
    this.error,
  });

  bool get isValid => ipo != null && error == null;
}

/// Expected column order (comma or tab separated), only the first three
/// are required:
///   Company Name, Open Date, Close Date, Type, Price Band,
///   Allotment Date, Listing Date, Registrar Name, Registrar URL, Notes
class IpoImportParser {
  static const sampleTemplate =
      'Company Name,Open Date,Close Date,Type,Price Band,Allotment Date,Listing Date\n'
      'Sample Textiles Ltd,2026-10-06,2026-10-08,Mainboard,₹210 - ₹225,2026-10-10,2026-10-14\n'
      'Sample Auto Components SME,10/10/2026,14/10/2026,SME,₹95 - ₹100,,';

  static List<ParsedIpoRow> parse(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final results = <ParsedIpoRow>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // Skip an optional header row (e.g. "Company Name, Open Date, ...")
      final lowerLine = line.toLowerCase();
      if (i == 0 && lowerLine.contains('company') && (lowerLine.contains('open') || lowerLine.contains('date'))) {
        continue;
      }

      final cols = _splitLine(line);

      if (cols.isEmpty || cols[0].trim().isEmpty) {
        results.add(ParsedIpoRow(lineNumber: lineNumber, rawLine: line, error: 'Missing company name'));
        continue;
      }
      final companyName = cols[0].trim();

      if (cols.length < 3) {
        results.add(ParsedIpoRow(
          lineNumber: lineNumber,
          rawLine: line,
          error: 'Expected at least Company Name, Open Date, Close Date',
        ));
        continue;
      }

      final openDt = AppDateUtils.parseFlexible(cols[1]);
      final closeDt = AppDateUtils.parseFlexible(cols[2]);

      if (openDt == null) {
        results.add(ParsedIpoRow(lineNumber: lineNumber, rawLine: line, error: 'Could not read Open Date "${cols[1]}"'));
        continue;
      }
      if (closeDt == null) {
        results.add(ParsedIpoRow(lineNumber: lineNumber, rawLine: line, error: 'Could not read Close Date "${cols[2]}"'));
        continue;
      }
      if (closeDt.isBefore(openDt)) {
        results.add(ParsedIpoRow(lineNumber: lineNumber, rawLine: line, error: 'Close Date is before Open Date'));
        continue;
      }

      final typeRaw = cols.length > 3 ? cols[3].trim().toLowerCase() : '';
      final ipoType = typeRaw.contains('sme') ? AppConstants.ipoTypeSme : AppConstants.ipoTypeMainboard;

      final priceBand = cols.length > 4 ? cols[4].trim() : '';

      final allotmentDt = cols.length > 5 ? AppDateUtils.parseFlexible(cols[5]) : null;
      final listingDt = cols.length > 6 ? AppDateUtils.parseFlexible(cols[6]) : null;
      final registrarName = cols.length > 7 && cols[7].trim().isNotEmpty ? cols[7].trim() : null;
      final registrarUrl = cols.length > 8 && cols[8].trim().isNotEmpty ? cols[8].trim() : null;
      final notes = cols.length > 9 && cols[9].trim().isNotEmpty ? cols[9].trim() : null;
      final gmp = cols.length > 10 && cols[10].trim().isNotEmpty ? cols[10].trim() : null;

      final openIso = AppDateUtils.toIsoDate(openDt);
      final closeIso = AppDateUtils.toIsoDate(closeDt);
      final allotmentIso = allotmentDt != null ? AppDateUtils.toIsoDate(allotmentDt) : null;
      final listingIso = listingDt != null ? AppDateUtils.toIsoDate(listingDt) : null;

      final status = Ipo.calculateSuggestedStatus(openIso, closeIso, allotmentIso, listingIso);

      final ipo = Ipo(
        companyName: companyName,
        ipoType: ipoType,
        priceBand: priceBand,
        openDate: openIso,
        closeDate: closeIso,
        allotmentDate: allotmentIso,
        listingDate: listingIso,
        registrarName: registrarName,
        registrarUrl: registrarUrl,
        ipoStatus: status,
        notes: notes,
        gmp: gmp,
      );

      results.add(ParsedIpoRow(lineNumber: lineNumber, rawLine: line, ipo: ipo));
    }

    return results;
  }

  /// Splits one line on commas or tabs, respecting double-quoted fields
  /// so a price band like "₹210 - ₹225" (no comma) or a quoted
  /// "Company, Ltd" style name still parses correctly.
  static List<String> _splitLine(String line) {
    final delimiter = line.contains('\t') && !line.contains(',') ? '\t' : ',';
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }
}
