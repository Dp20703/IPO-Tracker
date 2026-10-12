import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/confirmation_dialog.dart';
import 'add_edit_account_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  bool _showPan = false;

  void _toggleShowPan() async {
    if (_showPan) {
      setState(() {
        _showPan = false;
      });
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reveal PAN Number?',
      content: 'Are you sure you want to reveal the full unmasked PAN number on screen?',
      confirmLabel: 'SHOW PAN',
      cancelLabel: 'CANCEL',
      confirmColor: Theme.of(context).primaryColor,
      icon: Icons.security,
    );

    if (confirmed && mounted) {
      setState(() {
        _showPan = true;
      });
    }
  }

  void _deleteAccount() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Account?',
      content: 'Are you sure you want to delete this account? Related IPO application tracking records for this account will also be removed.',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      confirmColor: Colors.red,
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed && mounted) {
      final provider = Provider.of<AccountProvider>(context, listen: false);
      final success = await provider.deleteAccount(widget.account.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.accountNickname),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditAccountScreen(account: account),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAccount,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Summary Header Card
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      account.accountHolderName.isNotEmpty
                          ? account.accountHolderName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountNickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.accountHolderName,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    context,
                    label: 'Broker Name',
                    value: account.brokerName,
                    icon: Icons.account_balance,
                  ),
                  const SizedBox(height: 14),
                  
                  // PAN Row with Show/Hide toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge, size: 20, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAN Number',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _showPan ? account.panNumber : AppValidators.maskPan(account.panNumber),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _toggleShowPan,
                        icon: Icon(_showPan ? Icons.visibility_off : Icons.visibility, size: 18),
                        label: Text(_showPan ? 'Hide' : 'Show PAN'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (account.dpId != null && account.dpId!.isNotEmpty) ...[
                    _buildDetailRow(
                      context,
                      label: 'DP ID',
                      value: account.dpId!,
                      icon: Icons.numbers,
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (account.clientId != null && account.clientId!.isNotEmpty) ...[
                    _buildDetailRow(
                      context,
                      label: 'Client ID',
                      value: account.clientId!,
                      icon: Icons.person_pin,
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (account.notes != null && account.notes!.isNotEmpty) ...[
                    _buildDetailRow(
                      context,
                      label: 'Notes',
                      value: account.notes!,
                      icon: Icons.notes,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
