import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  // Supabase URL & Key
  static const String supabaseUrl = 'https://bdatlgqdfhqlsxskesej.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_QyT3XwOfZfTR12uMks27oQ_U4vNbUIa';

  bool get isConfigured =>
      supabaseUrl.startsWith('http') &&
      supabaseUrl.contains('supabase.co') &&
      supabaseAnonKey.isNotEmpty;

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (!isConfigured) {
      if (kDebugMode) {
        print('ℹ️ Supabase credentials not set yet. Running in offline/local state mode.');
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      if (kDebugMode) {
        print('⚡ Supabase initialized successfully with URL: $supabaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase Initialization Warning: $e');
      }
    }
  }

  // -----------------------------
  // AUTHENTICATION METHODS
  // -----------------------------

  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) return null;
    return await c.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) return null;
    return await c.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    final c = client;
    if (c == null) return false;
    return await c.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.hayaevents://login-callback',
    );
  }

  Future<void> signOut() async {
    final c = client;
    if (c == null) return;
    await c.auth.signOut();
  }
}
