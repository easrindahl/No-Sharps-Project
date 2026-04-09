
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome to Duluth's Sharps Reporting App!")),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Align (
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            height: 100,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/report'),
              icon: const Icon(Icons.add_box_outlined, size: 45),
              label: const Text(
                'Report a Needle',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
