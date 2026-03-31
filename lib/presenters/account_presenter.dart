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
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _view.showLoggedIn(UserModel(id: user.id, email: user.email));
      } else {
        _view.showLoggedOut();
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  void loadCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _view.showLoggedIn(UserModel(id: user.id, email: user.email));
    } else {
      _view.showLoggedOut();
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
        _view.showLoggedIn(
          UserModel(id: response.user!.id, email: response.user!.email),
        );
      } else {
        _view.showError('Sign in failed');
      }
    } on AuthException catch (e) {
      _view.showError(e.message);
    } catch (e) {
      _view.showError('An unexpected error occurred');
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
        _view.showLoggedIn(
          UserModel(id: response.user!.id, email: response.user!.email),
        );
      } else {
        _view.showError('Sign up failed');
      }
    } on AuthException catch (e) {
      _view.showError(e.message);
    } catch (e) {
      _view.showError('An unexpected error occurred');
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
