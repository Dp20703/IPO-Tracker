import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/application_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../ipos/ipo_detail_screen.dart';

class IpoHistoryScreen extends StatelessWidget {
  const IpoHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ipoProvider = Provider.of<IpoProvider>(context);
    final appProvider = Provider.of<ApplicationProvider>(context);

    final closedIpos = ipoProvider.closedIpos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPO History'),
      ),
      body: closedIpos.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No Completed IPOs',
              message: 'Closed and listed IPOs will appear here with detailed allotment summaries.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: closedIpos.length,
              itemBuilder: (context, index) {
                final ipo = closedIpos[index];
                final apps = appProvider.getApplicationsForIpo(ipo.id ?? -1);
                final appliedApps = apps.where((a) => a.hasApplied).toList();

                final appliedCount = appliedApps.length;
                final allottedCount = appliedApps
                    .where((a) => a.allotmentStatus == AppConstants.allotmentAllotted)
                    .length;
                final notAllottedCount = appliedApps
                    .where((a) => a.allotmentStatus == AppConstants.allotmentNotAllotted)
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IpoDetailScreen(ipo: ipo),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ipo.companyName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ipo.ipoStatus.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Closed: ${AppDateUtils.formatDateString(ipo.closeDate)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricTile('Applied', '$appliedCount Accounts', Colors.blue),
                              _buildMetricTile('Allotted', '$allottedCount', Colors.green),
                              _buildMetricTile('Not Allotted', '$notAllottedCount', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
