import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../models/vault_entry.dart';
import '../services/clipboard_service.dart';
import '../services/lock_manager.dart';
import '../services/secure_store.dart';
import '../services/vault_service.dart';
import '../widgets/entry_tile.dart';
import 'entry_detail_screen.dart';
import 'entry_edit_screen.dart';
import 'generator_screen.dart';
import 'lock_screen.dart';
import 'settings_screen.dart';

/// The vault list: search, category chips, favorites-only toggle, and
/// per-entry copy/favorite actions.
///
/// Auto-lock: a [LockManager] countdown restarts on every tap; the vault
/// also locks when the app is backgrounded.
class VaultScreen extends StatefulWidget {
  const VaultScreen({required this.vaultService, super.key});

  final VaultService vaultService;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _clipboard = ClipboardService();
  late final LockManager _lockManager;

  List<VaultEntry> _entries = [];
  List<VaultEntry> _filtered = [];
  String? _selectedCategory;
  bool _favoritesOnly = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockManager = LockManager(onLock: _onAutoLock);
    _loadEntries();
    _armAutoLock();
  }

  Future<void> _armAutoLock() async {
    final minutes = await SecureStore().autoLockMinutes;
    _lockManager.unlock(autoLock: Duration(minutes: minutes));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lockManager.lock();
    }
  }

  void _onAutoLock() {
    if (!mounted) return;
    _lockAndGo();
  }

  Future<void> _lockAndGo() async {
    await widget.vaultService.lock();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LockScreen(vaultService: widget.vaultService),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _clipboard.dispose();
    _lockManager.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await widget.vaultService.repository.getAll();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    var list = _entries;
    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }
    if (_favoritesOnly) {
      list = list.where((e) => e.isFavorite).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.username.toLowerCase().contains(query) ||
            e.url.toLowerCase().contains(query);
      }).toList();
    }
    setState(() => _filtered = list);
  }

  Future<void> _copyPassword(VaultEntry entry) async {
    await _clipboard.copySecret(entry.password);
    _lockManager.poke();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied — clipboard clears in 30 seconds.'),
      ),
    );
  }

  Future<void> _toggleFavorite(VaultEntry entry) async {
    await widget.vaultService.repository.setFavorite(entry, !entry.isFavorite);
    _lockManager.poke();
    await _loadEntries();
  }

  Future<void> _openDetail(VaultEntry entry) async {
    _lockManager.poke();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryDetailScreen(
          vaultService: widget.vaultService,
          entry: entry,
        ),
      ),
    );
    await _loadEntries();
  }

  Future<void> _openAdd() async {
    _lockManager.poke();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryEditScreen(vaultService: widget.vaultService),
      ),
    );
    await _loadEntries();
  }

  Future<void> _openGenerator() async {
    _lockManager.poke();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GeneratorScreen(),
      ),
    );
  }

  Future<void> _openSettings() async {
    _lockManager.poke();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(vaultService: widget.vaultService),
      ),
    );
    await _armAutoLock();
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesCount = _entries.where((e) => e.isFavorite).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VaultKey'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Lock vault',
            onPressed: () => _lockManager.lock(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.lock_outline, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'VaultKey',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Offline password manager'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Password generator'),
              onTap: () {
                Navigator.of(context).pop();
                _openGenerator();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                _openSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Lock vault now'),
              onTap: () {
                Navigator.of(context).pop();
                _lockManager.lock();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search title, username or URL',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null && !_favoritesOnly,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = null;
                      _favoritesOnly = false;
                    });
                    _applyFilter();
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text('Favorites ($favoritesCount)'),
                  selected: _favoritesOnly,
                  onSelected: (selected) {
                    setState(() => _favoritesOnly = selected);
                    _applyFilter();
                  },
                ),
                for (final category in VaultCategory.all) ...[
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                        _favoritesOnly = false;
                      });
                      _applyFilter();
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        tooltip: 'Add entry',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key_outlined, size: 64),
              SizedBox(height: 16),
              Text(
                'Your vault is empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Tap + to add your first login. Everything is encrypted '
                'on this device — nothing leaves it.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(
        child: Text('No entries match your search or filter.'),
      );
    }
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final entry = _filtered[index];
        return EntryTile(
          entry: entry,
          onTap: () => _openDetail(entry),
          onToggleFavorite: () => _toggleFavorite(entry),
          onCopyPassword: () => _copyPassword(entry),
        );
      },
    );
  }
}
