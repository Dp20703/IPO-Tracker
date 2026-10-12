import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../widgets/account_card.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_account_screen.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search holder name, nickname, broker...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  accountProvider.setSearchQuery(value);
                },
              )
            : const Text('Demat Accounts'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  accountProvider.setSearchQuery('');
                }
              });
            },
          ),
        ],
      ),
      body: accountProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : accountProvider.accounts.isEmpty
              ? EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: _searchController.text.isNotEmpty
                      ? 'No Accounts Found'
                      : 'No accounts added yet',
                  message: _searchController.text.isNotEmpty
                      ? 'Try searching with a different keyword'
                      : 'Store your family Demat account profiles and PAN details safely',
                  actionLabel: _searchController.text.isEmpty ? 'Add Your First Account' : null,
                  onAction: _searchController.text.isEmpty
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEditAccountScreen(),
                            ),
                          );
                        }
                      : null,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await accountProvider.loadAccounts();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: accountProvider.accounts.length,
                    itemBuilder: (context, index) {
                      final account = accountProvider.accounts[index];
                      return AccountCard(
                        account: account,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountDetailScreen(account: account),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accountsFab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditAccountScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }
}
