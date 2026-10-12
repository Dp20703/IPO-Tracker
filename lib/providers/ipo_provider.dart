import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ipo.dart';
import '../services/ipo_sync_service.dart';
import '../utils/constants.dart';

/// Outcome of a call to [IpoProvider.syncFromApi], so the calling screen
/// can show a precise summary or error to the user.
class IpoSyncResult {
  final bool success;
  final int added;
  final int updated;
  final String? errorMessage;

  const IpoSyncResult.ok({required this.added, required this.updated})
      : success = true,
        errorMessage = null;

  const IpoSyncResult.failure(this.errorMessage)
      : success = false,
        added = 0,
        updated = 0;
}

class IpoProvider extends ChangeNotifier {
  List<Ipo> _ipos = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // CURRENT, UPCOMING, CLOSED, ALL
  // Single-select, same pattern as the status filter: tapping Mainboard
  // or SME filters to that type and highlights it; tapping the already
  // -selected one again clears back to 'ALL' (show every type).
  String _selectedTypeFilter = 'ALL'; // MAINBOARD, SME, ALL
  String _sortBy = 'CLOSING_SOON'; // CLOSING_SOON, OPENING_SOON, NAME_ASC, RECENTLY_ADDED

  List<Ipo> get allIpos => _ipos;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  String get selectedTypeFilter => _selectedTypeFilter;
  String get sortBy => _sortBy;

  List<Ipo> get filteredIpos {
    List<Ipo> list = List.from(_ipos);

    // Apply Type Filter (Mainboard / SME / All)
    if (_selectedTypeFilter == 'MAINBOARD') {
      list = list.where((ipo) => ipo.ipoType == AppConstants.ipoTypeMainboard).toList();
    } else if (_selectedTypeFilter == 'SME') {
      list = list.where((ipo) => ipo.ipoType == AppConstants.ipoTypeSme).toList();
    }

    // Apply Status Filter
    if (_selectedFilter == 'CURRENT') {
      list = list.where((ipo) => ipo.ipoStatus == AppConstants.statusOpen).toList();
    } else if (_selectedFilter == 'UPCOMING') {
      list = list.where((ipo) => ipo.ipoStatus == AppConstants.statusUpcoming).toList();
    } else if (_selectedFilter == 'CLOSED') {
      list = list.where((ipo) => 
        ipo.ipoStatus == AppConstants.statusClosed || 
        ipo.ipoStatus == AppConstants.statusAllotmentPending ||
        ipo.ipoStatus == AppConstants.statusListed
      ).toList();
    }

    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((ipo) {
        return ipo.companyName.toLowerCase().contains(q) ||
            ipo.ipoType.toLowerCase().contains(q);
      }).toList();
    }

    // Apply Sort
    switch (_sortBy) {
      case 'OPENING_SOON':
        list.sort((a, b) => a.openDate.compareTo(b.openDate));
        break;
      case 'NAME_ASC':
        list.sort((a, b) => a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
        break;
      case 'RECENTLY_ADDED':
        list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case 'CLOSING_SOON':
      default:
        list.sort((a, b) => a.closeDate.compareTo(b.closeDate));
        break;
    }

    return list;
  }

  List<Ipo> get currentIpos {
    return _ipos.where((ipo) => ipo.ipoStatus == AppConstants.statusOpen).toList();
  }

  List<Ipo> get upcomingIpos {
    return _ipos.where((ipo) => ipo.ipoStatus == AppConstants.statusUpcoming).toList();
  }

  List<Ipo> get closedIpos {
    return _ipos.where((ipo) => 
      ipo.ipoStatus == AppConstants.statusClosed || 
      ipo.ipoStatus == AppConstants.statusAllotmentPending ||
      ipo.ipoStatus == AppConstants.statusListed
    ).toList();
  }

  IpoProvider() {
    loadIpos();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setTypeFilter(String typeFilter) {
    _selectedTypeFilter = typeFilter;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadIpos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ipos = await DatabaseHelper.instance.getAllIpos();
    } catch (e) {
      _errorMessage = 'Failed to load IPOs: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addIpo(Ipo ipo) async {
    try {
      _errorMessage = null;
      final id = await DatabaseHelper.instance.insertIpo(ipo);
      final newIpo = ipo.copyWith(id: id);
      _ipos.insert(0, newIpo);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add IPO: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Inserts several manually-entered or pasted-import IPOs at once and
  /// refreshes the list a single time at the end, rather than notifying
  /// listeners after every row.
  Future<int> addIposBulk(List<Ipo> ipos) async {
    int inserted = 0;
    for (final ipo in ipos) {
      try {
        await DatabaseHelper.instance.insertIpo(ipo);
        inserted++;
      } catch (_) {
        // Skip a row that fails to insert (e.g. a rare constraint clash)
        // rather than aborting the whole batch.
      }
    }
    await loadIpos();
    return inserted;
  }

  Future<bool> updateIpo(Ipo ipo) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.updateIpo(ipo);
      final index = _ipos.indexWhere((i) => i.id == ipo.id);
      if (index != -1) {
        _ipos[index] = ipo;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update IPO: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIpo(int id) async {
    try {
      _errorMessage = null;
      await DatabaseHelper.instance.deleteIpo(id);
      _ipos.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete IPO: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Pulls the live IPO calendar from the IPO Guru API and merges it into
  /// the local database: an IPO already synced before (matched by its
  /// externalSlug) is updated in place; a new one is inserted. Manually
  /// entered IPOs (no externalSlug) are never touched by this.
  Future<IpoSyncResult> syncFromApi(String apiKey) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final fetched = await IpoSyncService.fetchIpoCalendar(apiKey);
      int added = 0;
      int updated = 0;

      for (final incoming in fetched) {
        if (incoming.externalSlug == null) continue;
        final existing = await DatabaseHelper.instance.getIpoByExternalSlug(incoming.externalSlug!);
        if (existing == null) {
          await DatabaseHelper.instance.insertIpo(incoming);
          added++;
        } else {
          // Preserve any registrar info or notes the user has since
          // filled in manually; only refresh the fields the API owns.
          final merged = existing.copyWith(
            companyName: incoming.companyName,
            ipoType: incoming.ipoType,
            priceBand: incoming.priceBand,
            openDate: incoming.openDate,
            closeDate: incoming.closeDate,
            allotmentDate: incoming.allotmentDate,
            listingDate: incoming.listingDate,
            ipoStatus: incoming.ipoStatus,
            gmp: incoming.gmp ?? existing.gmp,
          );
          await DatabaseHelper.instance.updateIpo(merged);
          updated++;
        }
      }

      await loadIpos();
      return IpoSyncResult.ok(added: added, updated: updated);
    } on IpoSyncException catch (e) {
      return IpoSyncResult.failure(e.message);
    } catch (e) {
      return IpoSyncResult.failure('Sync failed: ${e.toString()}');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
