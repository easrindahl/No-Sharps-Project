import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../presenters/account_presenter.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView>
    implements AccountViewContract {
  late final AccountPresenter _presenter;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isSignUpMode = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _presenter = AccountPresenter(this, Supabase.instance.client);
    _presenter.loadCurrentUser();
  }

  @override
  void dispose() {
    _presenter.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void showLoggedIn(UserModel user) {
    setState(() {
      _isLoading = false;
      _isLoggedIn = true;
      _user = user;
    });
  }

  @override
  void showLoggedOut() {
    setState(() {
      _isLoading = false;
      _isLoggedIn = false;
      _user = null;
    });
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void showLoading() {
    setState(() => _isLoading = true);
  }

  @override
  void hideLoading() {
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isLoggedIn
          ? _buildLoggedInView()
          : _buildLoggedOutView(),
    );
  }

  Widget _buildLoggedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Signed in as',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? 'Unknown',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _presenter.signOut,
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutView() {
    final heading = _isSignUpMode ? 'Create Account' : 'Sign In';
    final description = _isSignUpMode
        ? 'Create a new account to track your reports.\nYou can report needles without an account.'
        : 'You can report needles without an account.\nSign in to track your reports.';
    final primaryLabel = _isSignUpMode ? 'Create Account' : 'Sign In';
    final togglePrompt = _isSignUpMode
        ? 'Already have an account? '
        : "Don't have an account? ";
    final toggleLabel = _isSignUpMode ? 'Sign In' : 'Create one';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(
            _isSignUpMode ? Icons.person_add_outlined : Icons.person_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            heading,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: _isSignUpMode
                  ? 'Must be at least 6 characters'
                  : null,
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final email = _emailController.text.trim();
              final password = _passwordController.text;
              if (_isSignUpMode) {
                _presenter.signUpWithEmail(email, password);
              } else {
                _presenter.signInWithEmail(email, password);
              }
            },
            child: Text(primaryLabel),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(togglePrompt, style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(
                onTap: () => setState(() => _isSignUpMode = !_isSignUpMode),
                child: Text(
                  toggleLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: TextStyle(color: Colors.grey[600])),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _presenter.signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text('Continue with Google'),
          ),
        ],
      ),
    );
  }
}
