import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPresenter {
  final SupabaseClient supabase;
  ReportPresenter(this.supabase);

  Future<String?> uploadImage(File imageFile) async {
    final fileName = 'needle_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = supabase.storage.from('needles');
    final res = await storage.upload(fileName, imageFile);
    if (res.isEmpty) return null;
    final url = storage.getPublicUrl(fileName);
    return url;
  }

  Future<void> submitReport({
    required String? imageUrl,
    required String location,
  }) async {
    await supabase.from('reports').insert({
      'image_url': imageUrl,
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
