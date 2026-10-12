import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/application_provider.dart';
import '../../widgets/dashboard_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ipoProvider = Provider.of<IpoProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final appProvider = Provider.of<ApplicationProvider>(context);

    final totalIpos = ipoProvider.allIpos.length;
    final totalAccounts = accountProvider.rawAccounts.length;
    final totalApplications = appProvider.totalAppliedApplications;
    final totalAllotments = appProvider.totalAllotted;
    final totalNotAllotted = appProvider.totalNotAllotted;
    final totalPending = appProvider.totalAllotmentPending;

    final successRate = appProvider.allotmentSuccessRate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Success Rate Card
          Card(
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'ALLOTMENT SUCCESS RATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${successRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalAllotments Allotted out of $totalApplications Applications',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              DashboardCard(
                title: 'Total IPOs Tracked',
                value: '$totalIpos',
                icon: Icons.business,
                color: Colors.blue,
              ),
              DashboardCard(
                title: 'Total Demat Accounts',
                value: '$totalAccounts',
                icon: Icons.account_balance_wallet,
                color: Colors.teal,
              ),
              DashboardCard(
                title: 'Total Applications',
                value: '$totalApplications',
                icon: Icons.assignment_turned_in,
                color: Colors.purple,
              ),
              DashboardCard(
                title: 'Total Allotments',
                value: '$totalAllotments',
                icon: Icons.stars,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Allotment Breakdown Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ALLOTMENT BREAKDOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildStatItem('Allotted Applications', '$totalAllotments', Colors.green),
                  const SizedBox(height: 12),
                  _buildStatItem('Not Allotted Applications', '$totalNotAllotted', Colors.red),
                  const SizedBox(height: 12),
                  _buildStatItem('Pending Allotments', '$totalPending', Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
