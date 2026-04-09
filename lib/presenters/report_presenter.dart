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

  String? getImageUrl(Map<String, dynamic> report) {
    String? path = report['image_path'] as String?;
    if (path == null || path.isEmpty) return null;
    // Ensure no leading slash which can sometimes malform the public URL
    if (path.startsWith('/')) path = path.substring(1);
    return supabase.storage.from('needles').getPublicUrl(path);
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

  Future<List<Map<String, dynamic>>> fetchReports({int limit = 10}) async {
    final rows = await supabase
        .from('reports')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
