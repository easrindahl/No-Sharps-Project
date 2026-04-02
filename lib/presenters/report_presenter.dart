import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPresenter {
  final SupabaseClient supabase;
  ReportPresenter(this.supabase);

  Future<String?> uploadImage(File imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = (DateTime.now().microsecondsSinceEpoch % 1000000)
        .toString();
    final objectPath = 'reports/needle_${randomId}_$timestamp.jpg';
    final storage = supabase.storage.from('needles');
    final res = await storage.upload(objectPath, imageFile);
    if (res.isEmpty) return null;
    // store the file path so the report row can match exactly on timestamped path
    return objectPath;
  }

  Future<void> submitReport({
    required String? imagePath,
    required String location,
  }) async {
    await supabase.from('reports').insert({
      'image_path': imagePath,
      'location': location,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
