import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/registrar.dart';

class RegistrarProvider extends ChangeNotifier {
  List<Registrar> _registrars = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Registrar> get registrars => _registrars;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RegistrarProvider() {
    loadRegistrars();
  }

  Future<void> loadRegistrars() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _registrars = await DatabaseHelper.instance.getAllRegistrars();
    } catch (e) {
      _errorMessage = 'Failed to load registrars: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRegistrar(Registrar registrar) async {
    try {
      _errorMessage = null;
      final id = await DatabaseHelper.instance.insertRegistrar(registrar);
      final newReg = registrar.copyWith(id: id);
      _registrars.add(newReg);
      _registrars.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add registrar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRegistrar(Registrar registrar) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.updateRegistrar(registrar);
      final index = _registrars.indexWhere((r) => r.id == registrar.id);
      if (index != -1) {
        _registrars[index] = registrar;
        _registrars.sort((a, b) => a.name.compareTo(b.name));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update registrar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRegistrar(int id) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.deleteRegistrar(id);
      _registrars.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete registrar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  static Future<bool> launchRegistrarUrl(String urlStr) async {
    if (urlStr.isEmpty) return false;
    try {
      var uri = Uri.parse(urlStr.trim());
      if (!uri.hasScheme) {
        uri = Uri.parse('https://${urlStr.trim()}');
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
