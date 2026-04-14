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
    return objectPath;
  }

  String? getImageUrl(Map<String, dynamic> report) {
    final imagePath = report['image_path'] as String?;
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    return supabase.storage.from('needles').getPublicUrl(imagePath);
  }

  Future<void> submitReport({
    required String? imagePath,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    final currentUser = supabase.auth.currentUser;
    
    final Map<String, dynamic> reportData = {
      'image_path': imagePath,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().toIso8601String(),
      'user_id': currentUser?.id,
    };

    await supabase.from('reports').insert(reportData);

    if (currentUser != null) {
      await _awardReportPoint(currentUser.id);
    }
  }

  Future<void> _awardReportPoint(String userId) async {
    final existing = await supabase
        .from('user_rewards')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('user_rewards').insert({
        'id': userId,
        'report_count': 1,
        'pickup_count': 0,
        'total_points': 1,
      });
      return;
    }

    final int currentReportCount = (existing['report_count'] as int?) ?? 0;
    final int currentPickupCount = (existing['pickup_count'] as int?) ?? 0;

    await supabase.from('user_rewards').update({
      'report_count': currentReportCount + 1,
      'pickup_count': currentPickupCount,
      'total_points': (currentReportCount + 1) + (currentPickupCount * 2),
    }).eq('id', userId);
  }

  Future<void> awardPickupPoints(String userId) async {
    final existing = await supabase
        .from('user_rewards')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('user_rewards').insert({
        'id': userId,
        'report_count': 0,
        'pickup_count': 1,
        'total_points': 2,
      });
      return;
    }

    final int currentReportCount = (existing['report_count'] as int?) ?? 0;
    final int currentPickupCount = (existing['pickup_count'] as int?) ?? 0;

    await supabase.from('user_rewards').update({
      'report_count': currentReportCount,
      'pickup_count': currentPickupCount + 1,
      'total_points': currentReportCount + ((currentPickupCount + 1) * 2),
    }).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> fetchReports({int limit = 10}) async {
    final rows = await supabase
        .from('reports')
        .select('id, location, created_at, image_path, latitude, longitude')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
