import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/application.dart';
import '../../models/account.dart';
import '../../models/ipo.dart';
import '../../providers/application_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/ipo_provider.dart';
import '../../widgets/application_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/constants.dart';
import '../../utils/csv_export_utils.dart';
import 'application_detail_screen.dart';

class AllApplicationsScreen extends StatefulWidget {
  const AllApplicationsScreen({super.key});

  @override
  State<AllApplicationsScreen> createState() => _AllApplicationsScreenState();
}

class _AllApplicationsScreenState extends State<AllApplicationsScreen> {
  String _filterStatus = 'ALL'; // ALL, APPLIED, NOT_APPLIED, PENDING, ALLOTTED, NOT_ALLOTTED
  int? _selectedAccountId;
  int? _selectedIpoId;

  Future<void> _exportCsv(
    BuildContext context,
    List<IpoApplication> list,
    List<Account> accounts,
    List<Ipo> ipos,
  ) async {
    try {
      final csv = CsvExportUtils.applicationsToCsv(applications: list, accounts: accounts, ipos: ipos);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/applications_$timestamp.csv');
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'IPO Applications',
          text: 'Applications export from IPO Tracker (${list.length} rows)',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<ApplicationProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final ipoProvider = Provider.of<IpoProvider>(context);

    final accounts = accountProvider.rawAccounts;
    final ipos = ipoProvider.allIpos;

    List<IpoApplication> list = List.from(appProvider.applications);

    // Apply Account Filter
    if (_selectedAccountId != null) {
      list = list.where((app) => app.accountId == _selectedAccountId).toList();
    }

    // Apply IPO Filter
    if (_selectedIpoId != null) {
      list = list.where((app) => app.ipoId == _selectedIpoId).toList();
    }

    // Apply Status Filter
    if (_filterStatus == 'APPLIED') {
      list = list.where((app) => app.hasApplied).toList();
    } else if (_filterStatus == 'NOT_APPLIED') {
      list = list.where((app) => !app.hasApplied).toList();
    } else if (_filterStatus == 'PENDING') {
      list = list.where((app) => app.hasApplied && app.allotmentStatus == AppConstants.allotmentPending).toList();
    } else if (_filterStatus == 'ALLOTTED') {
      list = list.where((app) => app.hasApplied && app.allotmentStatus == AppConstants.allotmentAllotted).toList();
    } else if (_filterStatus == 'NOT_ALLOTTED') {
      list = list.where((app) => app.hasApplied && app.allotmentStatus == AppConstants.allotmentNotAllotted).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export as CSV',
            onPressed: list.isEmpty ? null : () => _exportCsv(context, list, accounts, ipos),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterStatus == 'ALL',
                    onSelected: (_) => setState(() => _filterStatus = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Applied'),
                    selected: _filterStatus == 'APPLIED',
                    onSelected: (_) => setState(() => _filterStatus = 'APPLIED'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending Allotment'),
                    selected: _filterStatus == 'PENDING',
                    onSelected: (_) => setState(() => _filterStatus = 'PENDING'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Allotted'),
                    selected: _filterStatus == 'ALLOTTED',
                    onSelected: (_) => setState(() => _filterStatus = 'ALLOTTED'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Not Allotted'),
                    selected: _filterStatus == 'NOT_ALLOTTED',
                    onSelected: (_) => setState(() => _filterStatus = 'NOT_ALLOTTED'),
                  ),
                ],
              ),
            ),
          ),

          // Secondary Dropdown Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelText: 'Account Filter',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Accounts'),
                      ),
                      ...accounts.map((acc) {
                        return DropdownMenuItem<int?>(
                          value: acc.id,
                          child: Text(acc.accountNickname),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedIpoId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelText: 'IPO Filter',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All IPOs'),
                      ),
                      ...ipos.map((ipo) {
                        return DropdownMenuItem<int?>(
                          value: ipo.id,
                          child: Text(ipo.companyName, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedIpoId = val),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List View
          Expanded(
            child: appProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_late_outlined,
                        title: 'No Applications Tracked',
                        message: 'No applications match your selected filter criteria.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final app = list[index];
                          final acc = accounts.firstWhere(
                            (a) => a.id == app.accountId,
                            orElse: () => Account(
                              accountHolderName: 'Unknown',
                              accountNickname: 'Unknown',
                              panNumber: '',
                              brokerName: '',
                            ),
                          );
                          final ipo = ipos.firstWhere(
                            (i) => i.id == app.ipoId,
                            orElse: () => Ipo(
                              companyName: 'Unknown IPO',
                              ipoType: 'Mainboard',
                              priceBand: '',
                              openDate: '',
                              closeDate: '',
                              ipoStatus: 'CLOSED',
                            ),
                          );

                          return ApplicationCard(
                            application: app,
                            account: acc,
                            ipo: ipo,
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
