import 'package:flutter/material.dart';

class SafetyView extends StatelessWidget {
  const SafetyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: Center(
        child: Text(
          'Safety page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
