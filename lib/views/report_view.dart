import 'package:flutter/material.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Needle')),
      body: Center(
        child: Text(
          'Report page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
