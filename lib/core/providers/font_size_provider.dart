import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, normal, large }

extension FontSizeLabel on FontSizeOption {
  String get label {
    switch (this) {
      case FontSizeOption.small:
        return 'Kecil';
      case FontSizeOption.normal:
        return 'Normal';
      case FontSizeOption.large:
        return 'Besar';
    }
  }

  double get scale {
    switch (this) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.normal:
        return 1.0;
      case FontSizeOption.large:
        return 1.2;
    }
  }
}

const _fontSizeKey = 'app_font_size';

// Pakai Notifier (Riverpod v2) — tidak butuh legacy import
class FontSizeNotifier extends Notifier<FontSizeOption> {
  @override
  FontSizeOption build() {
    _load();
    return FontSizeOption.normal;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_fontSizeKey);
    switch (saved) {
      case 'small':
        state = FontSizeOption.small;
        break;
      case 'large':
        state = FontSizeOption.large;
        break;
      default:
        state = FontSizeOption.normal;
    }
  }

  Future<void> setSize(FontSizeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, option.name);
    state = option;
  }
}

final fontSizeProvider = NotifierProvider<FontSizeNotifier, FontSizeOption>(
  () => FontSizeNotifier(),
);
