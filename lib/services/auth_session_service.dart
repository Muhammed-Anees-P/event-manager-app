import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_data_repository.dart';
import 'supabase_service.dart';

class AuthSessionService {
  static final AuthSessionService instance = AuthSessionService._internal();
  AuthSessionService._internal();

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'saved_username';
  static const String _keyEmail = 'saved_email';

  Future<void> saveSession(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyEmail, email);

    AppDataRepository.instance.setCurrentUser(username, email);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);

    await SupabaseService.instance.signOut();
  }

  Future<bool> checkIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final String? username = prefs.getString(_keyUsername);
    final String? email = prefs.getString(_keyEmail);

    if (isLoggedIn && username != null && email != null) {
      AppDataRepository.instance.setCurrentUser(username, email);
      return true;
    }

    // Check Supabase session if configured
    if (SupabaseService.instance.isConfigured && SupabaseService.instance.client?.auth.currentSession != null) {
      final user = SupabaseService.instance.client!.auth.currentUser;
      if (user != null) {
        final emailStr = user.email ?? 'anees@hayaevents.com';
        final nameStr = emailStr.split('@').first;
        await saveSession(nameStr, emailStr);
        return true;
      }
    }

    return false;
  }
}
