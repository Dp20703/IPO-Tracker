import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../services/backup_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/registrar_provider.dart';
import '../../widgets/confirmation_dialog.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final file = await BackupService.exportToFile();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'IPO Tracker Backup',
          text: 'IPO Tracker backup — save this file somewhere safe (Drive, email, Files).',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Restore from backup?',
      content: 'Pick a backup JSON file. Data already on this device is kept — matching '
          'accounts (by PAN), IPOs, and registrars are skipped rather than duplicated.',
      confirmLabel: 'CHOOSE FILE',
      cancelLabel: 'CANCEL',
      confirmColor: Theme.of(context).primaryColor,
      icon: Icons.upload_file_outlined,
    );
    if (!confirmed || !mounted) return;

    List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: ${e.toString()}')),
        );
      }
      return;
    }

    if (picked.isEmpty) return; // user cancelled

    setState(() => _importing = true);
    try {
      final bytes = await picked.first.readAsBytes();
      final result = await BackupService.restoreFromJson(utf8.decode(bytes));
      if (!mounted) return;

      // Refresh every provider so the rest of the app reflects the
      // restored data immediately.
      await Provider.of<AccountProvider>(context, listen: false).loadAccounts();
      await Provider.of<IpoProvider>(context, listen: false).loadIpos();
      await Provider.of<ApplicationProvider>(context, listen: false).loadApplications();
      await Provider.of<RegistrarProvider>(context, listen: false).loadRegistrars();

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore complete'),
          content: Text(
            'Accounts: ${result.accountsAdded} added, ${result.accountsSkipped} already existed\n'
            'IPOs: ${result.iposAdded} added, ${result.iposSkipped} already existed\n'
            'Applications: ${result.applicationsAdded} added, ${result.applicationsSkipped} skipped\n'
            'Registrars: ${result.registrarsAdded} added, ${result.registrarsSkipped} already existed',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } on BackupInvalidException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            icon: Icons.upload_outlined,
            iconColor: Colors.blue,
            title: 'Export Backup',
            description: 'Save all your accounts, IPOs, applications, and registrars to one '
                'file, then send it to Drive, email, or wherever you like via the share sheet.',
            buttonLabel: 'EXPORT & SHARE',
            loading: _exporting,
            onPressed: _export,
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.download_outlined,
            iconColor: Colors.green,
            title: 'Restore Backup',
            description: 'Pick a previously exported backup file to bring that data back in. '
                'Nothing already on this device is overwritten or deleted.',
            buttonLabel: 'CHOOSE FILE & RESTORE',
            loading: _importing,
            onPressed: _import,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uninstalling this app deletes its local data permanently. Export a backup '
                    'before uninstalling or switching phones, and keep the file somewhere safe — '
                    'it contains your PAN numbers just like the app does.',
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

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonLabel,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onPressed,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
