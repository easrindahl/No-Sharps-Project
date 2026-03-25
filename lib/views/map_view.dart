import 'package:flutter/material.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Center(
        child: Text(
          'Map page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
