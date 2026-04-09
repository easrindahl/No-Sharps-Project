import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AccountViewContract {
  void showLoggedIn(UserModel user);
  void showLoggedOut();
  void showError(String message);
  void showLoading();
  void hideLoading();
}

class AccountPresenter {
  final AccountViewContract _view;
  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _authSubscription;

  AccountPresenter(this._view, this._supabase) {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        try {
          final fullUser = await _buildUserModel(user);
          _view.showLoggedIn(fullUser);
        } catch (e) {
          _view.showError('Failed to load account data');
          _view.showLoggedIn(UserModel(id: user.id, email: user.email));
        }
      } else {
        _view.showLoggedOut();
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  Future<void> loadCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final fullUser = await _buildUserModel(user);
        _view.showLoggedIn(fullUser);
      } catch (e) {
        _view.showError('Failed to load rewards data');
        _view.showLoggedIn(UserModel(id: user.id, email: user.email));
      }
    } else {
      _view.showLoggedOut();
    }
  }

  Future<UserModel> _buildUserModel(User user) async {
    final rewards = await _getOrCreateRewards(user.id);

    final int reportCount = (rewards['report_count'] as int?) ?? 0;
    final int pickupCount = (rewards['pickup_count'] as int?) ?? 0;
    final int totalPoints = (rewards['total_points'] as int?) ?? 0;

    return UserModel(
      id: user.id,
      email: user.email,
      reportCount: reportCount,
      pickupCount: pickupCount,
      totalPoints: totalPoints,
    );
  }

  Future<Map<String, dynamic>> _getOrCreateRewards(String userId) async {
    final existing = await _supabase
        .from('user_rewards')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    final inserted = await _supabase
        .from('user_rewards')
        .insert({
          'id': userId,
          'report_count': 0,
          'pickup_count': 0,
          'total_points': 0,
        })
        .select()
        .single();

    return inserted;
  }

  Future<void> refreshRewards() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _view.showLoggedOut();
      return;
    }

    try {
      final fullUser = await _buildUserModel(user);
      _view.showLoggedIn(fullUser);
    } catch (e) {
      _view.showError('Failed to refresh rewards');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _view.showLoading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final fullUser = await _buildUserModel(response.user!);
        _view.showLoggedIn(fullUser);
      } else {
        _view.showError('Sign in failed');
      }
    } on AuthException catch (e) {
      _view.showError(e.message);
    } on PostgrestException catch (e) {
      _view.showError('Database error: ${e.message}');
    } catch (e) {
      _view.showError('An unexpected error occurred: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _view.showLoading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _getOrCreateRewards(response.user!.id);
        final fullUser = await _buildUserModel(response.user!);
        _view.showLoggedIn(fullUser);
      } else {
        _view.showError('Sign up failed');
      }
    } on AuthException catch (e) {
      _view.showError(e.message);
    } on PostgrestException catch (e) {
      _view.showError('Database error: ${e.message}');
    } catch (e) {
      _view.showError('An unexpected error occurred: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> signInWithGoogle() async {
    _view.showLoading();
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.nosharps://login-callback/',
      );
    } on AuthException catch (e) {
      _view.showError(e.message);
      _view.hideLoading();
    } catch (e) {
      _view.showError('Google sign in failed: ${e.toString()}');
      _view.hideLoading();
    }
  }

  Future<void> signOut() async {
    _view.showLoading();
    try {
      await _supabase.auth.signOut();
      _view.showLoggedOut();
    } on AuthException catch (e) {
      _view.showError(e.message);
    } catch (e) {
      _view.showError('Sign out failed');
    } finally {
      _view.hideLoading();
    }
  }
}
