
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Duluth's Sharps Reporting App!"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // Report Button
            SizedBox(
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

            const SizedBox(height: 20),

            // Cleanup Services Button 
            SizedBox(
              width: double.infinity,
              height: 100,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/cleanup_services'),
                icon: const Icon(Icons.cleaning_services, size: 45),
                label: const Text(
                  'Needle Cleanup Services',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
