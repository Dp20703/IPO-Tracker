import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/application.dart';
import '../utils/constants.dart';

class ApplicationProvider extends ChangeNotifier {
  List<IpoApplication> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<IpoApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ApplicationProvider() {
    loadApplications();
  }

  Future<void> loadApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await DatabaseHelper.instance.getAllApplications();
    } catch (e) {
      _errorMessage = 'Failed to load applications: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<IpoApplication> getApplicationsForIpo(int ipoId) {
    return _applications.where((app) => app.ipoId == ipoId).toList();
  }

  List<IpoApplication> getApplicationsForAccount(int accountId) {
    return _applications.where((app) => app.accountId == accountId).toList();
  }

  IpoApplication? getApplication(int ipoId, int accountId) {
    try {
      return _applications.firstWhere((app) => app.ipoId == ipoId && app.accountId == accountId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveApplication(IpoApplication application) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.insertOrUpdateApplication(application);
      await loadApplications();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save application: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteApplication(int id) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.deleteApplication(id);
      _applications.removeWhere((app) => app.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete application: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Helper Stats Calculation
  int get totalAppliedApplications => _applications.where((app) => app.hasApplied).length;
  
  int get totalAllotmentPending => _applications.where((app) => 
    app.hasApplied && app.allotmentStatus == AppConstants.allotmentPending
  ).length;

  int get totalAllotted => _applications.where((app) => 
    app.hasApplied && app.allotmentStatus == AppConstants.allotmentAllotted
  ).length;

  int get totalNotAllotted => _applications.where((app) => 
    app.hasApplied && app.allotmentStatus == AppConstants.allotmentNotAllotted
  ).length;

  double get allotmentSuccessRate {
    final appliedCount = totalAppliedApplications;
    if (appliedCount == 0) return 0.0;
    return (totalAllotted / appliedCount) * 100;
  }
}
