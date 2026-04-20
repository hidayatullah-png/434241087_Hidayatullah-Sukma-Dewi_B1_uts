// lib/features/notifications/presentation/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Model ──────────────────────────────────────────────────────

enum NotificationType { statusUpdate, newComment, assigned, newTicket }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String ticketId;
  final String createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.ticketId,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    ticketId: ticketId,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

// ── State ──────────────────────────────────────────────────────

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: ganti dengan actual API call
      // final res = await http.get(Uri.parse('$baseUrl/api/notifications'));
      // final list = (jsonDecode(res.body) as List)
      //     .map((e) => AppNotification.fromJson(e))
      //     .toList();

      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(
        isLoading: false,
        notifications: _dummyNotifications,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat notifikasi.',
      );
    }
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
  }

  void deleteNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);
  }

  Future<void> refresh() => fetchNotifications();
}

// ── Provider ───────────────────────────────────────────────────

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
      (ref) => NotificationNotifier(),
    );

// ── Dummy data ─────────────────────────────────────────────────

final _dummyNotifications = [
  const AppNotification(
    id: '1',
    title: 'Status Tiket Diperbarui',
    message: 'Tiket #1024 "Printer lantai 3" telah diubah ke In Progress.',
    type: NotificationType.statusUpdate,
    ticketId: '1024',
    createdAt: '5 menit lalu',
    isRead: false,
  ),
  const AppNotification(
    id: '2',
    title: 'Komentar Baru',
    message: 'Rina Amelia menambahkan komentar pada tiket #1024.',
    type: NotificationType.newComment,
    ticketId: '1024',
    createdAt: '20 menit lalu',
    isRead: false,
  ),
  const AppNotification(
    id: '3',
    title: 'Tiket Di-assign',
    message: 'Tiket #1023 "Akses VPN" telah di-assign ke kamu.',
    type: NotificationType.assigned,
    ticketId: '1023',
    createdAt: '1 jam lalu',
    isRead: false,
  ),
  const AppNotification(
    id: '4',
    title: 'Tiket Baru Masuk',
    message: 'Ada tiket baru #1022 "Email tidak bisa kirim attachment".',
    type: NotificationType.newTicket,
    ticketId: '1022',
    createdAt: '3 jam lalu',
    isRead: true,
  ),
  const AppNotification(
    id: '5',
    title: 'Status Tiket Diperbarui',
    message: 'Tiket #1021 "Laptop tidak bisa booting" telah Selesai.',
    type: NotificationType.statusUpdate,
    ticketId: '1021',
    createdAt: '5 jam lalu',
    isRead: true,
  ),
  const AppNotification(
    id: '6',
    title: 'Komentar Baru',
    message: 'Dani Rahmat membalas komentar kamu pada tiket #1020.',
    type: NotificationType.newComment,
    ticketId: '1020',
    createdAt: '1 hari lalu',
    isRead: true,
  ),
  const AppNotification(
    id: '7',
    title: 'Tiket Baru Masuk',
    message: 'Ada tiket baru #1019 "Internet lambat di ruang meeting".',
    type: NotificationType.newTicket,
    ticketId: '1019',
    createdAt: '1 hari lalu',
    isRead: true,
  ),
];
