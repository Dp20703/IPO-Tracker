import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/ipo.dart';
import '../models/application.dart';
import '../utils/validators.dart';

/// Builds a printable/shareable PDF summarising all local app data —
/// a human-readable report, distinct from the JSON backup (which is
/// for restoring data) and the applications-only CSV (which is for
/// spreadsheet use). PAN numbers are masked, same as everywhere else.
class PdfExportService {
  static Future<Uint8List> generateFullReport({
    required List<Account> accounts,
    required List<Ipo> ipos,
    required List<IpoApplication> applications,
    required int totalAllotted,
    required double allotmentSuccessRate,
  }) async {
    final doc = pw.Document();
    final generatedAt = DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());

    pw.Widget sectionHeader(String title) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text('IPO Tracker — Data Report', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ),
        build: (context) => [
          pw.Text('IPO Tracker', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('Data Report — generated $generatedAt', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(height: 20),

          // Summary
          sectionHeader('SUMMARY'),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('Accounts', accounts.length.toString()),
              _summaryBox('Applications', applications.where((a) => a.hasApplied).length.toString()),
              _summaryBox('Allotted', totalAllotted.toString()),
              _summaryBox('Success Rate', '${allotmentSuccessRate.toStringAsFixed(1)}%'),
            ],
          ),

          // Accounts
          sectionHeader('DEMAT ACCOUNTS (${accounts.length})'),
          if (accounts.isEmpty)
            pw.Text('No accounts added yet.', style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Nickname', 'Holder Name', 'PAN (masked)', 'Broker'],
              data: accounts
                  .map((a) => [
                        a.accountNickname,
                        a.accountHolderName,
                        AppValidators.maskPan(a.panNumber),
                        a.brokerName,
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),

          // Applications
          sectionHeader('APPLICATIONS (${applications.length})'),
          if (applications.isEmpty)
            pw.Text('No applications tracked yet.', style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Company', 'Account', 'Applied', 'Status', 'Allotment', 'Shares'],
              data: applications.map((app) {
                final ipo = ipos.where((i) => i.id == app.ipoId).toList();
                final account = accounts.where((a) => a.id == app.accountId).toList();
                return [
                  ipo.isNotEmpty ? ipo.first.companyName : 'Unknown',
                  account.isNotEmpty ? account.first.accountNickname : 'Unknown',
                  app.hasApplied ? 'Yes' : 'No',
                  app.applicationStatus.replaceAll('_', ' '),
                  app.allotmentStatus.replaceAll('_', ' '),
                  app.sharesAllotted.toString(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'Generated by IPO Tracker. For personal record-keeping only — not investment advice. '
            'GMP figures, where present in the app, are unverified market rumour.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    );
  }
}
