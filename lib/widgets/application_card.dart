import 'package:flutter/material.dart';
import '../models/application.dart';
import '../models/account.dart';
import '../models/ipo.dart';
import '../utils/constants.dart';

class ApplicationCard extends StatelessWidget {
  final IpoApplication application;
  final Account? account;
  final Ipo? ipo;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    this.account,
    this.ipo,
    required this.onTap,
  });

  Color _getAllotmentColor(String status) {
    switch (status) {
      case AppConstants.allotmentAllotted:
        return Colors.green;
      case AppConstants.allotmentNotAllotted:
        return Colors.red;
      case AppConstants.allotmentPending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allotmentColor = _getAllotmentColor(application.allotmentStatus);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ipo != null) ...[
                          Text(
                            ipo!.companyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          account != null
                              ? '${account!.accountNickname} (${account!.accountHolderName})'
                              : 'Account #${application.accountId}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ipo != null ? Colors.grey[700] : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: application.hasApplied
                          ? Colors.green.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      application.hasApplied ? 'APPLIED' : 'NOT APPLIED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: application.hasApplied ? Colors.green[800] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (application.hasApplied) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem('Lots', '${application.lotsApplied} Lot(s)'),
                    _buildMetaItem('Status', application.applicationStatus),
                    _buildMetaItem('Allotment', application.allotmentStatus, color: allotmentColor),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
