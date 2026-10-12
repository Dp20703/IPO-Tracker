import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ipo.dart';
import '../../models/application.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/registrar_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/confirmation_dialog.dart';
import '../applications/application_detail_screen.dart';
import 'add_edit_ipo_screen.dart';

class IpoDetailScreen extends StatefulWidget {
  final Ipo ipo;

  const IpoDetailScreen({super.key, required this.ipo});

  @override
  State<IpoDetailScreen> createState() => _IpoDetailScreenState();
}

class _IpoDetailScreenState extends State<IpoDetailScreen> {
  void _openRegistrarUrl() async {
    final url = widget.ipo.registrarUrl;
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No registrar URL specified for this IPO')),
      );
      return;
    }

    final launched = await RegistrarProvider.launchRegistrarUrl(url);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open official registrar URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteIpo() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete IPO?',
      content: 'Are you sure you want to delete this IPO? All account application records associated with this IPO will be permanently deleted.',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      confirmColor: Colors.red,
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed && mounted) {
      final provider = Provider.of<IpoProvider>(context, listen: false);
      final success = await provider.deleteIpo(widget.ipo.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('IPO deleted successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to delete IPO'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ipo = widget.ipo;
    final accountProvider = Provider.of<AccountProvider>(context);
    final appProvider = Provider.of<ApplicationProvider>(context);

    final accounts = accountProvider.rawAccounts;
    final totalAccounts = accounts.length;
    final ipoApps = appProvider.getApplicationsForIpo(ipo.id ?? -1);
    final appliedCount = ipoApps.where((a) => a.hasApplied).length;
    final progress = totalAccounts > 0 ? (appliedCount / totalAccounts) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(ipo.companyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditIpoScreen(ipo: ipo),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteIpo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // IPO Overview Header Card
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ipo.ipoType == AppConstants.ipoTypeMainboard
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ipo.ipoType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ipo.ipoType == AppConstants.ipoTypeMainboard
                                ? Colors.blue[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ipo.ipoStatus.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ipo.companyName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price Band: ${ipo.priceBand}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (ipo.gmp != null && ipo.gmp!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: Colors.amber[900]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'GMP: ${ipo.gmp} — unofficial grey market rumour, not verified data or investment advice',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[900],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key Dates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KEY TIMELINE DATES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildDateTile('Open Date', ipo.openDate, Icons.calendar_today)),
                      Expanded(child: _buildDateTile('Close Date', ipo.closeDate, Icons.event_busy)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTile(
                          'Allotment Date',
                          ipo.allotmentDate ?? 'N/A',
                          Icons.how_to_reg,
                        ),
                      ),
                      Expanded(
                        child: _buildDateTile(
                          'Listing Date',
                          ipo.listingDate ?? 'N/A',
                          Icons.show_chart,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Registrar & Official Link Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REGISTRAR & ALLOTMENT LINK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 20),
                  Builder(builder: (context) {
                    final hasName = ipo.registrarName != null && ipo.registrarName!.isNotEmpty;
                    final hasUrl = ipo.registrarUrl != null && ipo.registrarUrl!.isNotEmpty;

                    if (!hasName && !hasUrl) {
                      // Nothing filled in yet — offer a direct shortcut to
                      // add it, rather than a dead-end "Not Specified".
                      return Row(
                        children: [
                          Icon(Icons.business_center_outlined, color: Colors.grey[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Not added yet — the free API plan doesn\'t include this, so add it manually if you know it.',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddEditIpoScreen(ipo: ipo)),
                              );
                            },
                            child: const Text('ADD'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Icon(Icons.business_center, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasName ? ipo.registrarName! : 'Registrar link available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hasUrl)
                                Text(
                                  ipo.registrarUrl!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: (ipo.registrarUrl != null && ipo.registrarUrl!.isNotEmpty)
                        ? _openRegistrarUrl
                        : null,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('CHECK ALLOTMENT STATUS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ACCOUNT x IPO MATRIX SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MY ACCOUNTS APPLICATION TRACKING',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.grey,
                ),
              ),
              Text(
                '$appliedCount / $totalAccounts Applied',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                appliedCount == totalAccounts && totalAccounts > 0
                    ? Colors.green
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (accounts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'No Demat accounts added yet.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Go to the Accounts tab to add Demat accounts to track applications',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              final app = appProvider.getApplication(ipo.id!, acc.id!) ??
                  IpoApplication(ipoId: ipo.id!, accountId: acc.id!);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplicationDetailScreen(
                          ipo: ipo,
                          account: acc,
                          application: app,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: app.hasApplied
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          child: Icon(
                            app.hasApplied ? Icons.check_circle : Icons.circle_outlined,
                            size: 20,
                            color: app.hasApplied ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc.accountNickname,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                acc.accountHolderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: app.hasApplied
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                app.hasApplied ? 'Applied (${app.lotsApplied} Lot)' : 'Not Applied',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: app.hasApplied ? Colors.green[800] : Colors.grey[700],
                                ),
                              ),
                            ),
                            if (app.hasApplied) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Allotment: ${app.allotmentStatus}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: app.allotmentStatus == AppConstants.allotmentAllotted
                                      ? Colors.green
                                      : app.allotmentStatus == AppConstants.allotmentNotAllotted
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_note, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, String dateIso, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              AppDateUtils.formatDateString(dateIso),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
