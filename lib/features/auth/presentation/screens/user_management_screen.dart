import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

// ── Model ──────────────────────────────────────────────────────

class UserItem {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  const UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  UserItem copyWith({bool? isActive}) => UserItem(
    id: id,
    name: name,
    email: email,
    role: role,
    isActive: isActive ?? this.isActive,
  );
}

// ── State ──────────────────────────────────────────────────────

class UserManagementState {
  final List<UserItem> users;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? updatingUserId;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.updatingUserId,
  });

  List<UserItem> get filtered {
    if (searchQuery.isEmpty) return users;
    final q = searchQuery.toLowerCase();
    return users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();
  }

  UserManagementState copyWith({
    List<UserItem>? users,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? updatingUserId,
    bool clearUpdating = false,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      updatingUserId: clearUpdating
          ? null
          : (updatingUserId ?? this.updatingUserId),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final _supabase = Supabase.instance.client;

  UserManagementNotifier() : super(const UserManagementState()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, role, is_active')
          .order('role')
          .order('name');

      final users = (response as List).map((u) {
        return UserItem(
          id: u['id'].toString(),
          name: u['name'] ?? '-',
          email: u['email'] ?? '-',
          role: u['role'] ?? 'user',
          isActive: u['is_active'] ?? true,
        );
      }).toList();

      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat daftar pengguna: $e',
      );
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> toggleActive(UserItem user) async {
    if (state.updatingUserId != null) return;
    state = state.copyWith(updatingUserId: user.id);

    final newStatus = !user.isActive;
    try {
      await _supabase
          .from('users')
          .update({'is_active': newStatus})
          .eq('id', user.id);

      final updated = state.users.map((u) {
        return u.id == user.id ? u.copyWith(isActive: newStatus) : u;
      }).toList();

      state = state.copyWith(users: updated, clearUpdating: true);
    } catch (e) {
      print('Gagal update status user: $e');
      state = state.copyWith(clearUpdating: true);
    }
  }

  Future<void> refresh() => fetchUsers();
}

// ── Provider ───────────────────────────────────────────────────

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>(
      (ref) => UserManagementNotifier(),
    );

// ── Screen ─────────────────────────────────────────────────────

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showToggleConfirm(UserItem user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDeactivating = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.wrnDarkInput : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isDeactivating ? 'Nonaktifkan Pengguna?' : 'Aktifkan Pengguna?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isDeactivating
              ? '${user.name} tidak akan bisa login setelah dinonaktifkan.'
              : 'Aktifkan kembali akun ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(userManagementProvider.notifier).toggleActive(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating
                  ? const Color(0xFFCF6679)
                  : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isDeactivating ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final notifier = ref.read(userManagementProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final filtered = state.filtered;

    // Hitung statistik
    final totalUser = state.users.where((u) => u.role == 'user').length;
    final totalHelpdesk = state.users.where((u) => u.role == 'helpdesk').length;
    final totalInactive = state.users.where((u) => !u.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : notifier.refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Stats ──
          if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _StatBadge(
                    label: 'User',
                    count: totalUser,
                    color: AppColors.wrnBtsPurple,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Helpdesk',
                    count: totalHelpdesk,
                    color: AppColors.wrnLightPurple,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Nonaktif',
                    count: totalInactive,
                    color: const Color(0xFFCF6679),
                  ),
                ],
              ),
            ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.wrnDarkInput : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.wrnShapePurple.withOpacity(0.25)
                      : cs.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: notifier.setSearch,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari nama, email, atau role...',
                  hintStyle: TextStyle(
                    color: cs.onSurface.withOpacity(0.35),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            notifier.setSearch('');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: cs.onSurface.withOpacity(0.4),
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : state.error != null
                ? _ErrorState(message: state.error!, onRetry: notifier.refresh)
                : filtered.isEmpty
                ? _EmptyState(isSearching: state.searchQuery.isNotEmpty)
                : RefreshIndicator(
                    color: cs.primary,
                    onRefresh: notifier.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final isUpdating = state.updatingUserId == user.id;
                        return _UserCard(
                          user: user,
                          isUpdating: isUpdating,
                          isDark: isDark,
                          cs: cs,
                          theme: theme,
                          onToggle: () => _showToggleConfirm(user),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserItem user;
  final bool isUpdating;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _UserCard({
    required this.user,
    required this.isUpdating,
    required this.isDark,
    required this.cs,
    required this.theme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrnDarkInput : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isActive
              ? isDark
                    ? AppColors.wrnShapePurple.withOpacity(0.25)
                    : cs.outlineVariant.withOpacity(0.4)
              : const Color(0xFFCF6679).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: user.isActive
                ? roleColor.withOpacity(0.15)
                : cs.onSurface.withOpacity(0.08),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: user.isActive
                    ? roleColor
                    : cs.onSurface.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: user.isActive
                              ? cs.onSurface
                              : cs.onSurface.withOpacity(0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status badge
                    if (!user.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCF6679).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCF6679),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Toggle button
          isUpdating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? const Color(0xFFCF6679).withOpacity(0.1)
                          : const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: user.isActive
                            ? const Color(0xFFCF6679).withOpacity(0.3)
                            : const Color(0xFF4CAF50).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      user.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outlined,
                      size: 18,
                      color: user.isActive
                          ? const Color(0xFFCF6679)
                          : const Color(0xFF4CAF50),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.wrnShapeRose;
      case 'helpdesk':
        return AppColors.wrnLightPurple;
      default:
        return AppColors.wrnBtsPurple;
    }
  }
}

// ── Helper Widgets ─────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.people_outline,
            size: 64,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Pengguna tidak ditemukan' : 'Belum ada pengguna',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}