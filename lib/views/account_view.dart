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

  final List<Map<String, dynamic>> _rewardOptions = const [
    {
      'title': '\$5 Coffee Gift Card',
      'points': 10,
      'icon': Icons.local_cafe,
      'description': 'Redeem points for a coffee shop gift card.',
    },
    {
      'title': 'Movie Theater Coupon',
      'points': 10,
      'icon': Icons.movie,
      'description': 'A fun reward for active community volunteers.',
    },
    {
      'title': 'Campus Bookstore Discount',
      'points': 15,
      'icon': Icons.menu_book,
      'description': 'Save on school supplies or campus merchandise.',
    },
    {
      'title': 'Transit Pass Voucher',
      'points': 20,
      'icon': Icons.directions_bus,
      'description': 'Help users get around while helping the community.',
    },
  ];

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
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isLoggedIn = true;
      _user = user;
    });
  }

  @override
  void showLoggedOut() {
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() => _isLoading = true);
  }

  @override
  void hideLoading() {
    if (!mounted) return;
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
    return RefreshIndicator(
      onRefresh: _presenter.refreshRewards,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Icon(Icons.account_circle, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Signed in as',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _user?.email ?? 'Unknown',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildPointsCard(),
          const SizedBox(height: 20),
          _buildHowPointsWorkCard(),
          const SizedBox(height: 24),
          Text(
            'Activity Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Reports',
                  value: '${_user?.reportCount ?? 0}',
                  subtitle: '1 point each',
                  icon: Icons.report_problem_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Disposals',
                  value: '${_user?.pickupCount ?? 0}',
                  subtitle: '2 points each',
                  icon: Icons.delete_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Redeem Shop',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Prototype reward options for your class project.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          ..._rewardOptions.map((reward) => _buildRewardTile(reward)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _presenter.signOut,
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reward Points',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_user?.totalPoints ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Points are updated when you submit reports and when a disposal is confirmed by QR scan.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowPointsWorkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How points work',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRuleRow(
              icon: Icons.report_problem_outlined,
              text: 'Submitting a needle report earns 1 point.',
            ),
            const SizedBox(height: 10),
            _buildRuleRow(
              icon: Icons.qr_code_scanner,
              text: 'Confirming disposal with a disposal-box QR scan earns 2 points.',
            ),
            const SizedBox(height: 10),
            _buildRuleRow(
              icon: Icons.flag_outlined,
              text: 'A claimed report shows In Progress so others know it is being handled.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.green, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(title),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardTile(Map<String, dynamic> reward) {
    final int userPoints = _user?.totalPoints ?? 0;
    final int cost = reward['points'] as int;
    final bool canAfford = userPoints >= cost;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: Icon(
                reward['icon'] as IconData,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(reward['description'] as String),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cost pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          canAfford
                              ? 'Prototype only: redeem flow not implemented yet.'
                              : 'Not enough points yet.',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(84, 32),
                  ),
                  child: const Text('Redeem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutView() {
    final heading = _isSignUpMode ? 'Create Account' : 'Sign In';
    final description = _isSignUpMode
        ? 'Create a new account to track reports, disposal confirmations, and rewards.\nYou can still report needles without an account.'
        : 'You can report needles without an account.\nSign in to track rewards and confirmed disposals.';
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
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
              helperText:
                  _isSignUpMode ? 'Must be at least 6 characters' : null,
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              final email = _emailController.text.trim();
              final password = _passwordController.text;

              if (_isSignUpMode) {
                _presenter.signUpWithEmail(email, password);
              } else {
                _presenter.signInWithEmail(email, password);
              }
            },
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
