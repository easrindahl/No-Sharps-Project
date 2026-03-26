import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'navigation_shell.dart';

// void main() {
//   runApp(const MyApp());
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await Supabase.initialize(
    url: 'https://sbqgcbiceleykldwzeas.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNicWdjYmljZWxleWtsZHd6ZWFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMDA4MDksImV4cCI6MjA4OTg3NjgwOX0.HI2wdvj1wUxjSgdumTd91UB9mteM80Oah2ORDSMjQBs',
  );
  runApp(MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Sharps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const NavigationShell(),
    );
  }
}
