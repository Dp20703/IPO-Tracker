import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/account_provider.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/application_provider.dart';
import '../../services/pdf_export_service.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  bool _generating = false;

  Future<void> _generateAndShare() async {
    setState(() => _generating = true);
    try {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      final ipoProvider = Provider.of<IpoProvider>(context, listen: false);
      final appProvider = Provider.of<ApplicationProvider>(context, listen: false);

      final bytes = await PdfExportService.generateFullReport(
        accounts: accountProvider.rawAccounts,
        ipos: ipoProvider.allIpos,
        applications: appProvider.applications,
        totalAllotted: appProvider.totalAllotted,
        allotmentSuccessRate: appProvider.allotmentSuccessRate,
      );

      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: 'ipo_tracker_report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Report (PDF)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Full Data Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generates a readable PDF covering your Demat accounts (PAN masked) and every '
                    'application with its status and allotment outcome — handy for sharing with '
                    'family or keeping a printable record.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generating ? null : _generateAndShare,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.share_outlined),
                      label: Text(_generating ? 'Generating…' : 'Generate & Share PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a readable snapshot for sharing or printing — it is not a backup. '
                    'To restore your data on another device, use Backup & Restore instead.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
