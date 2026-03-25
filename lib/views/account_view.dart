import 'package:flutter/material.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: Text(
          'Account page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
