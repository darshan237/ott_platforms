import 'package:shared_preferences/shared_preferences.dart';

/// Simple repository to persist last selected bottom index.
/// If you don't want persistence, you can replace implementation easily.
class NavigationRepository {
  static const _kSavedIndexKey = 'nav_last_index';

  Future<int> getLastIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kSavedIndexKey) ?? 0;
    } catch (_) {
      return 0; // fallback
    }
  }

  Future<void> saveIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSavedIndexKey, index);
    } catch (_) {
      // ignore errors in simple example
    }
  }
}
