import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/account.dart';

class AccountProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Account> get accounts {
    if (_searchQuery.isEmpty) {
      return _accounts;
    }
    final q = _searchQuery.toLowerCase();
    return _accounts.where((acc) {
      return acc.accountHolderName.toLowerCase().contains(q) ||
          acc.accountNickname.toLowerCase().contains(q) ||
          acc.brokerName.toLowerCase().contains(q);
    }).toList();
  }

  List<Account> get rawAccounts => _accounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  AccountProvider() {
    loadAccounts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accounts = await DatabaseHelper.instance.getAllAccounts();
    } catch (e) {
      _errorMessage = 'Failed to load accounts: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isPanUnique(String pan, [int? currentAccountId]) {
    final cleanPan = pan.trim().toUpperCase();
    return !_accounts.any((acc) => acc.panNumber.toUpperCase() == cleanPan && acc.id != currentAccountId);
  }

  Future<bool> addAccount(Account account) async {
    try {
      _errorMessage = null;
      if (!isPanUnique(account.panNumber)) {
        _errorMessage = 'An account with this PAN already exists.';
        notifyListeners();
        return false;
      }
      final id = await DatabaseHelper.instance.insertAccount(account);
      final newAcc = account.copyWith(id: id);
      _accounts.add(newAcc);
      _accounts.sort((a, b) => a.accountHolderName.compareTo(b.accountHolderName));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save account: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      _errorMessage = null;
      if (!isPanUnique(account.panNumber, account.id)) {
        _errorMessage = 'An account with this PAN already exists.';
        notifyListeners();
        return false;
      }
      await DatabaseHelper.instance.updateAccount(account);
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        _accounts.sort((a, b) => a.accountHolderName.compareTo(b.accountHolderName));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update account: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.deleteAccount(id);
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete account: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
