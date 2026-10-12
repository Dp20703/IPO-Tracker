import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ipo_provider.dart';
import '../../services/api_key_store.dart';
import '../../widgets/ipo_card.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_ipo_screen.dart';
import 'ipo_detail_screen.dart';
import '../more/api_settings_screen.dart';
import 'import_ipos_screen.dart';
import '../../theme/app_theme.dart';

class _Segment {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.selected, required this.onTap});
}

class IpoScreen extends StatefulWidget {
  const IpoScreen({super.key});

  @override
  State<IpoScreen> createState() => _IpoScreenState();
}

class _IpoScreenState extends State<IpoScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncIpos() async {
    final ipoProvider = Provider.of<IpoProvider>(context, listen: false);
    final apiKey = await ApiKeyStore.getIpoGuruKey();

    if (apiKey == null || apiKey.isEmpty) {
      if (!mounted) return;
      final goToSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API key needed'),
          content: const Text(
            'Add your free IPO Guru API key first to sync the live IPO calendar. '
            'You can still add IPOs manually without one.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ADD KEY')),
          ],
        ),
      );
      if (goToSettings == true && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ApiSettingsScreen()));
      }
      return;
    }

    final result = await ipoProvider.syncFromApi(apiKey);
    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced: ${result.added} new, ${result.updated} updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Sync failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ipoProvider = Provider.of<IpoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search company name or type...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  ipoProvider.setSearchQuery(value);
                },
              )
            : const Text('IPOs Management'),
        actions: [
          if (!_isSearching)
            ipoProvider.isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.playlist_add),
                    tooltip: 'Add multiple IPOs',
                    onSelected: (value) {
                      if (value == 'sync') {
                        _syncIpos();
                      } else if (value == 'import') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ImportIposScreen()),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'sync',
                        child: ListTile(
                          leading: Icon(Icons.cloud_sync_outlined),
                          title: Text('Sync from IPO Guru API'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'import',
                        child: ListTile(
                          leading: Icon(Icons.paste_outlined),
                          title: Text('Import from CSV / pasted text'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ipoProvider.setSearchQuery('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: status, as one enclosed segmented-control track
                // (equal-width segments) instead of loose floating chips.
                // Tap the active one again to clear it and show everything.
                _buildSegmentedTrack([
                  _Segment(
                    label: 'Current',
                    selected: ipoProvider.selectedFilter == 'CURRENT',
                    onTap: () => ipoProvider.setFilter(
                      ipoProvider.selectedFilter == 'CURRENT' ? 'ALL' : 'CURRENT',
                    ),
                  ),
                  _Segment(
                    label: 'Upcoming',
                    selected: ipoProvider.selectedFilter == 'UPCOMING',
                    onTap: () => ipoProvider.setFilter(
                      ipoProvider.selectedFilter == 'UPCOMING' ? 'ALL' : 'UPCOMING',
                    ),
                  ),
                  _Segment(
                    label: 'Closed',
                    selected: ipoProvider.selectedFilter == 'CLOSED',
                    onTap: () => ipoProvider.setFilter(
                      ipoProvider.selectedFilter == 'CLOSED' ? 'ALL' : 'CLOSED',
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // Row 2: type track (Mainboard / SME — independent toggles;
                // both on or both off both mean "show everything") + sort,
                // kept as a separate control since it isn't part of the
                // same choice group.
                Row(
                  children: [
                    Expanded(
                      child: _buildSegmentedTrack([
                        _Segment(
                          label: 'Mainboard',
                          selected: ipoProvider.selectedTypeFilter == 'MAINBOARD',
                          onTap: () => ipoProvider.setTypeFilter(
                            ipoProvider.selectedTypeFilter == 'MAINBOARD' ? 'ALL' : 'MAINBOARD',
                          ),
                        ),
                        _Segment(
                          label: 'SME',
                          selected: ipoProvider.selectedTypeFilter == 'SME',
                          onTap: () => ipoProvider.setTypeFilter(
                            ipoProvider.selectedTypeFilter == 'SME' ? 'ALL' : 'SME',
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    _buildSortButton(ipoProvider),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List View
          Expanded(
            child: ipoProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ipoProvider.filteredIpos.isEmpty
                    ? EmptyState(
                        icon: Icons.business_outlined,
                        title: _searchController.text.isNotEmpty
                            ? 'No IPOs Found'
                            : 'No IPOs Available',
                        message: _searchController.text.isNotEmpty
                            ? 'Try searching with another keyword'
                            : 'Add IPOs manually to track applications and allotment status',
                        actionLabel: _searchController.text.isEmpty ? 'Add IPO' : null,
                        onAction: _searchController.text.isEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddEditIpoScreen(),
                                  ),
                                );
                              }
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ipoProvider.loadIpos();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: ipoProvider.filteredIpos.length,
                          itemBuilder: (context, index) {
                            final ipo = ipoProvider.filteredIpos[index];
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
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'iposFab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditIpoScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add IPO'),
      ),
    );
  }

  /// A single enclosed, equal-width segmented control — like an
  /// iOS/Material tab switcher — instead of individually floating
  /// chips. Every segment shares one bordered track and fills the full
  /// available width via Expanded, so 2 or 3 options always look like
  /// one cohesive, intentional control rather than loose pills with
  /// uneven leftover space.
  Widget _buildSegmentedTrack(List<_Segment> segments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Theme.of(context).colorScheme.onPrimary is unreliable here: this
    // theme builds its ColorScheme.fromSeed() with an explicit `primary`
    // override, but Flutter still auto-derives onPrimary from the
    // original seed-generated tone rather than the override — producing
    // a low-contrast color on top of our actual primary. Using the
    // theme's known brand constants directly with plain white text
    // sidesteps that mismatch entirely.
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    const selectedTextColor = Colors.white;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
      ),
      child: Row(
        children: segments.map((segment) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: segment.onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: segment.selected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: segment.selected
                          ? [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Text(
                      segment.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: segment.selected
                            ? selectedTextColor
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static const Map<String, String> _sortLabels = {
    'CLOSING_SOON': 'Closing Soon',
    'OPENING_SOON': 'Opening Soon',
    'NAME_ASC': 'Company Name',
    'RECENTLY_ADDED': 'Recently Added',
  };

  Widget _buildSortButton(IpoProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      onSelected: provider.setSortBy,
      itemBuilder: (context) => _sortLabels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    if (provider.sortBy == e.key)
                      Icon(Icons.check, size: 16, color: Theme.of(context).primaryColor)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(e.value),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.035),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75)),
            const SizedBox(width: 4),
            Text(
              _sortLabels[provider.sortBy] ?? 'Sort',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
