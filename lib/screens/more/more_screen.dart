import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/application_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../applications/all_applications_screen.dart';
import 'statistics_screen.dart';
import 'ipo_history_screen.dart';
import 'important_dates_screen.dart';
import 'registrar_links_screen.dart';
import 'api_settings_screen.dart';
import 'backup_restore_screen.dart';
import 'export_report_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _loadSampleData(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Load Demo Sample Data?',
      content: 'This will add sample family accounts and IPO records for demonstration purposes.',
      confirmLabel: 'LOAD DATA',
      cancelLabel: 'CANCEL',
      confirmColor: Theme.of(context).primaryColor,
      icon: Icons.auto_awesome,
    );

    if (confirmed && context.mounted) {
      final accountProv = Provider.of<AccountProvider>(context, listen: false);
      final ipoProv = Provider.of<IpoProvider>(context, listen: false);
      final appProv = Provider.of<ApplicationProvider>(context, listen: false);

      await DatabaseHelper.instance.seedSampleData();
      await accountProv.loadAccounts();
      await ipoProv.loadIpos();
      await appProv.loadApplications();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample data loaded successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More & Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuSection(
            context,
            title: 'TRACKING & ANALYTICS',
            items: [
              _MenuItem(
                icon: Icons.assignment_outlined,
                title: 'All Applications',
                subtitle: 'View and filter all account application records',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllApplicationsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.bar_chart,
                title: 'Statistics & Success Rate',
                subtitle: 'View total allotments, success rate and performance',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.history,
                title: 'IPO History',
                subtitle: 'Past closed IPOs and allotment breakdown',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IpoHistoryScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.calendar_month,
                title: 'Important Dates',
                subtitle: 'Upcoming IPO open, close, allotment & listing dates',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImportantDatesScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMenuSection(
            context,
            title: 'RESOURCES & UTILITIES',
            items: [
              _MenuItem(
                icon: Icons.link,
                title: 'Official Registrar Links',
                subtitle: 'Link Intime, KFintech, Bigshare & official portals',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrarLinksScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.auto_awesome,
                title: 'Load Demo Sample Data',
                subtitle: 'Add sample accounts and IPOs for testing',
                color: Colors.indigo,
                onTap: () => _loadSampleData(context),
              ),
              _MenuItem(
                icon: Icons.cloud_sync_outlined,
                title: 'IPO Data Sync',
                subtitle: 'Add your free IPO Guru API key to auto-fill the IPO calendar',
                color: Colors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ApiSettingsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.backup_outlined,
                title: 'Backup & Restore',
                subtitle: 'Export all your data to a file, or restore from a previous backup',
                color: Colors.deepOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Export Report (PDF)',
                subtitle: 'A readable, shareable snapshot of your accounts, IPOs, and applications',
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExportReportScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.shield_outlined, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 6),
                Text(
                  '100% Offline & Private',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All Demat profiles and PAN data stay locally on your device.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'IPO Tracker v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, {required String title, required List<_MenuItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: item.onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
