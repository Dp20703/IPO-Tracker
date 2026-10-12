import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/application_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/ipo_card.dart';
import '../../utils/constants.dart';
import '../ipos/ipo_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  List<String> _calculatePendingActions(BuildContext context) {
    final ipoProvider = Provider.of<IpoProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final appProvider = Provider.of<ApplicationProvider>(context);

    final actions = <String>[];
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T').first;
    final totalAccounts = accountProvider.rawAccounts.length;

    for (var ipo in ipoProvider.allIpos) {
      // 1. Closes Today
      if (ipo.closeDate == todayStr && ipo.ipoStatus == AppConstants.statusOpen) {
        actions.add('🔥 "${ipo.companyName}" closes today!');
      }

      // 2. Listing Today
      if (ipo.listingDate == todayStr) {
        actions.add('🚀 "${ipo.companyName}" lists today!');
      }

      // 3. Application not completed for all accounts for OPEN ipos
      if (ipo.ipoStatus == AppConstants.statusOpen && totalAccounts > 0) {
        final ipoApps = appProvider.getApplicationsForIpo(ipo.id ?? -1);
        final appliedCount = ipoApps.where((a) => a.hasApplied).length;
        if (appliedCount < totalAccounts) {
          actions.add('⏳ "${ipo.companyName}": Only $appliedCount of $totalAccounts accounts applied');
        }
      }

      // 4. Allotment Pending
      if (ipo.ipoStatus == AppConstants.statusAllotmentPending ||
          (ipo.allotmentDate == todayStr && ipo.ipoStatus == AppConstants.statusClosed)) {
        final ipoApps = appProvider.getApplicationsForIpo(ipo.id ?? -1);
        final hasPendingAllotment = ipoApps.any(
            (a) => a.hasApplied && a.allotmentStatus == AppConstants.allotmentPending);
        if (hasPendingAllotment) {
          actions.add('📋 "${ipo.companyName}" allotment status is pending');
        }
      }
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final ipoProvider = Provider.of<IpoProvider>(context);
    final appProvider = Provider.of<ApplicationProvider>(context);

    final currentCount = ipoProvider.currentIpos.length;
    final upcomingCount = ipoProvider.upcomingIpos.length;
    final appliedCount = appProvider.totalAppliedApplications;
    final pendingAllotmentCount = appProvider.totalAllotmentPending;

    final pendingActions = _calculatePendingActions(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPO Tracker'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ipoProvider.loadIpos();
          await appProvider.loadApplications();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Summary Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                DashboardCard(
                  title: 'Current IPOs',
                  value: '$currentCount',
                  icon: Icons.local_fire_department,
                  color: Colors.green,
                  onTap: () {
                    ipoProvider.setFilter('CURRENT');
                    onNavigateTab?.call(1);
                  },
                ),
                DashboardCard(
                  title: 'Upcoming IPOs',
                  value: '$upcomingCount',
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                  onTap: () {
                    ipoProvider.setFilter('UPCOMING');
                    onNavigateTab?.call(1);
                  },
                ),
                DashboardCard(
                  title: 'Applied Applications',
                  value: '$appliedCount',
                  icon: Icons.assignment_turned_in,
                  color: Colors.purple,
                  onTap: () {
                    onNavigateTab?.call(3); // Navigate to More / All Applications
                  },
                ),
                DashboardCard(
                  title: 'Allotment Pending',
                  value: '$pendingAllotmentCount',
                  icon: Icons.hourglass_top,
                  color: Colors.orange,
                  onTap: () {
                    onNavigateTab?.call(3);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CURRENT IPOS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CURRENT IPOS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ipoProvider.setFilter('CURRENT');
                    onNavigateTab?.call(1);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (ipoProvider.currentIpos.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text(
                        'No Current IPOs Open Right Now',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check upcoming IPOs to plan your applications',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...ipoProvider.currentIpos.map((ipo) {
                return IpoCard(
                  ipo: ipo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IpoDetailScreen(ipo: ipo),
                      ),
                    );
                  },
                );
              }),

            const SizedBox(height: 24),

            // PENDING ACTIONS SECTION
            const Text(
              'PENDING ACTIONS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            if (pendingActions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No pending actions 🎉',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingActions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.amber.withOpacity(0.2),
                        child: const Icon(Icons.notifications_active, size: 16, color: Colors.amber),
                      ),
                      title: Text(
                        pendingActions[index],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      dense: true,
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
