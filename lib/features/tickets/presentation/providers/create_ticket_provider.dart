// lib/features/tickets/presentation/providers/create_ticket_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// -- Enums --

enum TicketCategory {
  hardware,
  software,
  network,
  account,
  other;

  String get label {
    switch (this) {
      case TicketCategory.hardware:
        return 'Hardware';
      case TicketCategory.software:
        return 'Software';
      case TicketCategory.network:
        return 'Network / Internet';
      case TicketCategory.account:
        return 'Akun & Akses';
      case TicketCategory.other:
        return 'Lainnya';
    }
  }
}

enum TicketPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TicketPriority.low:
        return 'Rendah';
      case TicketPriority.medium:
        return 'Sedang';
      case TicketPriority.high:
        return 'Tinggi';
    }
  }
}

// -- State --

class CreateTicketState {
  final String title;
  final String description;
  final TicketCategory? category;
  final TicketPriority priority;
  final List<File> attachments;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const CreateTicketState({
    this.title = '',
    this.description = '',
    this.category,
    this.priority = TicketPriority.medium,
    this.attachments = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      category != null;

  CreateTicketState copyWith({
    String? title,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    List<File>? attachments,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
  }) {
    return CreateTicketState(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

// -- Notifier --

class CreateTicketNotifier extends StateNotifier<CreateTicketState> {
  CreateTicketNotifier() : super(const CreateTicketState());

  void setTitle(String value) =>
      state = state.copyWith(title: value, error: null);

  void setDescription(String value) =>
      state = state.copyWith(description: value, error: null);

  void setCategory(TicketCategory value) =>
      state = state.copyWith(category: value, error: null);

  void setPriority(TicketPriority value) =>
      state = state.copyWith(priority: value);

  void addAttachment(File file) {
    if (state.attachments.length >= 5) return; // max 5 file
    state = state.copyWith(attachments: [...state.attachments, file]);
  }

  void removeAttachment(int index) {
    final updated = [...state.attachments]..removeAt(index);
    state = state.copyWith(attachments: updated);
  }

  Future<void> submit() async {
    if (!state.isValid) {
      state = state.copyWith(
        error: 'Judul, deskripsi, dan kategori wajib diisi',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      // TODO: ganti dengan actual API call
      // final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/tickets'));
      // request.fields['title'] = state.title;
      // request.fields['description'] = state.description;
      // request.fields['category'] = state.category!.name;
      // request.fields['priority'] = state.priority.name;
      // for (final file in state.attachments) {
      //   request.files.add(await http.MultipartFile.fromPath('attachments[]', file.path));
      // }
      // await request.send();

      await Future.delayed(const Duration(milliseconds: 1000));

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Gagal membuat tiket. Coba lagi.',
      );
    }
  }

  void reset() => state = const CreateTicketState();
}

// -- Provider --

final createTicketProvider =
    StateNotifierProvider.autoDispose<CreateTicketNotifier, CreateTicketState>(
      (ref) => CreateTicketNotifier(),
    );
