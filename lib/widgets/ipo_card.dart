import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ipo.dart';
import '../providers/account_provider.dart';
import '../providers/application_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class IpoCard extends StatelessWidget {
  final Ipo ipo;
  final VoidCallback onTap;

  const IpoCard({
    super.key,
    required this.ipo,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusOpen:
        return const Color(0xFF22C55E); // green
      case AppConstants.statusUpcoming:
        return const Color(0xFFF59E0B); // amber
      case AppConstants.statusClosed:
        return const Color(0xFF94A3B8); // slate
      case AppConstants.statusAllotmentPending:
        return const Color(0xFFA855F7); // purple
      case AppConstants.statusListed:
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusOpen:
        return Icons.radio_button_checked;
      case AppConstants.statusUpcoming:
        return Icons.schedule;
      case AppConstants.statusClosed:
        return Icons.lock_outline;
      case AppConstants.statusAllotmentPending:
        return Icons.hourglass_top;
      case AppConstants.statusListed:
        return Icons.show_chart;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final appProvider = Provider.of<ApplicationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalAccounts = accountProvider.rawAccounts.length;
    final ipoApps = appProvider.getApplicationsForIpo(ipo.id ?? -1);
    final appliedAccountsCount = ipoApps.where((a) => a.hasApplied).length;

    final progress = totalAccounts > 0 ? (appliedAccountsCount / totalAccounts) : 0.0;
    final progressPct = (progress * 100).round();
    final statusColor = _getStatusColor(ipo.ipoStatus);
    final isMainboard = ipo.ipoType == AppConstants.ipoTypeMainboard;
    final typeColor = isMainboard ? const Color(0xFF6366F1) : const Color(0xFFEC4899);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status accent bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [statusColor, statusColor.withOpacity(0.55)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                ipo.companyName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(ipo.ipoStatus), size: 11, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    ipo.ipoStatus.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ipo.ipoType,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${ipo.priceBand}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                        if (ipo.gmp != null && ipo.gmp!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(isDark ? 0.10 : 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, size: 13, color: Colors.amber[700]),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'GMP ${ipo.gmp}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber[isDark ? 300 : 800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'unverified',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.amber[isDark ? 300 : 800]?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildDateColumn(context, 'OPENS', ipo.openDate),
                            Container(
                              width: 1,
                              height: 26,
                              margin: const EdgeInsets.symmetric(horizontal: 14),
                              color: Theme.of(context).dividerColor.withOpacity(0.4),
                            ),
                            _buildDateColumn(context, 'CLOSES', ipo.closeDate),
                            if (ipo.allotmentDate != null && ipo.allotmentDate!.isNotEmpty) ...[
                              Container(
                                width: 1,
                                height: 26,
                                margin: const EdgeInsets.symmetric(horizontal: 14),
                                color: Theme.of(context).dividerColor.withOpacity(0.4),
                              ),
                              _buildDateColumn(context, 'ALLOTMENT', ipo.allotmentDate!),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'APPLICATION PROGRESS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                              ),
                            ),
                            Text(
                              '$appliedAccountsCount/$totalAccounts · $progressPct%',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: appliedAccountsCount == totalAccounts && totalAccounts > 0
                                    ? const Color(0xFF22C55E)
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: appliedAccountsCount == totalAccounts && totalAccounts > 0
                                          ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                          : [
                                              Theme.of(context).primaryColor,
                                              Theme.of(context).primaryColor.withOpacity(0.7),
                                            ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateColumn(BuildContext context, String label, String dateIso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          AppDateUtils.formatShortDateString(dateIso),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
