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

  Future<String?> getDisplayImageUrl(Map<String, dynamic> report) async {
    final rawImage = (report['image_path'] ?? report['image_url']) as String?;

    final extractedPath = _extractStoragePath(rawImage);
    if (extractedPath != null) {
      return _buildSignedOrPublicUrl(extractedPath);
    }

    final parsed = Uri.tryParse(rawImage ?? '');
    if (parsed != null && parsed.hasScheme) {
      if (parsed.scheme == 'http' || parsed.scheme == 'https') {
        return rawImage;
      }
    }

    final imagePath = _normalizeImagePath(rawImage);
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    return _buildSignedOrPublicUrl(imagePath);
  }

  String? getImageUrl(Map<String, dynamic> report) {
    final rawImage = (report['image_path'] ?? report['image_url']) as String?;
    final extractedPath = _extractStoragePath(rawImage);
    if (extractedPath != null) {
      return supabase.storage.from('needles').getPublicUrl(extractedPath);
    }

    final parsed = Uri.tryParse(rawImage ?? '');
    if (parsed != null && parsed.hasScheme) {
      if (parsed.scheme == 'http' || parsed.scheme == 'https') {
        return rawImage;
      }
    }

    final imagePath = _normalizeImagePath(rawImage);
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    return supabase.storage.from('needles').getPublicUrl(imagePath);
  }

  Future<String?> _buildSignedOrPublicUrl(String objectPath) async {
    final storage = supabase.storage.from('needles');
    try {
      return await storage.createSignedUrl(objectPath, 3600);
    } catch (_) {
      return storage.getPublicUrl(objectPath);
    }
  }

  String? _extractStoragePath(String? rawPath) {
    if (rawPath == null) return null;

    final parsed = Uri.tryParse(rawPath.trim());
    if (parsed == null || !parsed.hasScheme) return null;

    final segments = parsed.pathSegments;
    if (segments.isEmpty) return null;

    final bucketIndex = segments.indexOf('needles');
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
      return null;
    }

    // Supports:
    // /storage/v1/object/public/needles/<path>
    // /storage/v1/object/sign/needles/<path>
    // /storage/v1/object/authenticated/needles/<path>
    final pathAfterBucket = segments.sublist(bucketIndex + 1).join('/');
    return _normalizeImagePath(pathAfterBucket);
  }

  String? _normalizeImagePath(String? rawPath) {
    if (rawPath == null) return null;

    final trimmed = Uri.decodeComponent(rawPath.trim());
    if (trimmed.isEmpty) return null;

    var normalized = trimmed.replaceFirst(RegExp(r'^/+'), '');

    // Handle values saved as full public-storage path.
    const storagePrefix = 'storage/v1/object/public/needles/';
    if (normalized.startsWith(storagePrefix)) {
      normalized = normalized.substring(storagePrefix.length);
    }

    // Handle values saved with bucket name included.
    const bucketPrefix = 'needles/';
    if (normalized.startsWith(bucketPrefix)) {
      normalized = normalized.substring(bucketPrefix.length);
    }

    // Legacy rows may store only the filename; images live in needles/reports.
    if (!normalized.contains('/')) {
      normalized = 'reports/$normalized';
    }

    return normalized;
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
      try {
        // Keep report submission successful even if rewards RLS blocks writes.
        await _awardReportPoint(currentUser.id);
      } on PostgrestException catch (_) {
        // Rewards are best-effort until user_rewards policies are configured.
      }
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
