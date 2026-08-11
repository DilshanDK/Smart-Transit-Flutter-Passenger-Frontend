import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/secure_storage.dart';

/// Simple cubit that manages light/dark theme mode and persists it.
class ThemeCubit extends Cubit<bool> {
  // state = true means dark mode
  ThemeCubit() : super(true);

  static const _key = 'is_dark_theme';

  /// Load the saved preference. Call this once at startup.
  Future<void> load() async {
    final saved = await SecureStorage.readValue(_key);
    emit(saved == 'false' ? false : true); // default: dark
  }

  Future<void> setDark(bool isDark) async {
    await SecureStorage.writeValue(_key, isDark ? 'true' : 'false');
    emit(isDark);
  }

  void toggle() => setDark(!state);
}
