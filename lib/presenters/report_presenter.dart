import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPresenter {
  final SupabaseClient supabase;
  ReportPresenter(this.supabase);

  Future<String?> uploadImage(File imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId =
        (DateTime.now().microsecondsSinceEpoch % 1000000).toString();
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

    final pathAfterBucket = segments.sublist(bucketIndex + 1).join('/');
    return _normalizeImagePath(pathAfterBucket);
  }

  String? _normalizeImagePath(String? rawPath) {
    if (rawPath == null) return null;

    final trimmed = Uri.decodeComponent(rawPath.trim());
    if (trimmed.isEmpty) return null;

    var normalized = trimmed.replaceFirst(RegExp(r'^/+'), '');

    const storagePrefix = 'storage/v1/object/public/needles/';
    if (normalized.startsWith(storagePrefix)) {
      normalized = normalized.substring(storagePrefix.length);
    }

    const bucketPrefix = 'needles/';
    if (normalized.startsWith(bucketPrefix)) {
      normalized = normalized.substring(bucketPrefix.length);
    }

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
      'pickup_status': 'open',
      'pickup_user_id': null,
      'pickup_claimed_at': null,
    };

    await supabase.from('reports').insert(reportData);

    if (currentUser != null) {
      try {
        await _awardReportPoint(currentUser.id);
      } on PostgrestException catch (_) {}
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
        .select(
          'id, location, created_at, image_path, latitude, longitude, pickup_status, pickup_user_id, pickup_claimed_at',
        )
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> markReportInProgress(String reportId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in to claim a pickup.');
    }

    await supabase.from('reports').update({
      'pickup_status': 'in_progress',
      'pickup_user_id': currentUser.id,
      'pickup_claimed_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  Future<void> completeDisposalWithQr({
    required Map<String, dynamic> report,
    required String qrValue,
  }) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in to confirm disposal.');
    }

    final reportId = report['id']?.toString();
    if (reportId == null || reportId.isEmpty) {
      throw Exception('Invalid report id.');
    }

    final disposalBoxId = _extractDisposalBoxId(qrValue);

    await supabase.from('disposal_events').insert({
      'report_id': reportId,
      'disposed_by': currentUser.id,
      'disposal_box_id': disposalBoxId,
      'qr_code': qrValue,
      'location': report['location'],
      'image_path': report['image_path'],
      'latitude': report['latitude'],
      'longitude': report['longitude'],
      'reported_created_at': report['created_at'],
      'disposed_at': DateTime.now().toIso8601String(),
    });

    try {
      await awardPickupPoints(currentUser.id);
    } on PostgrestException catch (_) {}

    await supabase.from('reports').delete().eq('id', reportId);
  }

  String _extractDisposalBoxId(String qrValue) {
    final trimmed = qrValue.trim();

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final qp = uri.queryParameters;
      if ((qp['box_id'] ?? '').trim().isNotEmpty) {
        return qp['box_id']!.trim();
      }
      if ((qp['id'] ?? '').trim().isNotEmpty) {
        return qp['id']!.trim();
      }
    }

    if (trimmed.contains('box:')) {
      return trimmed.split('box:').last.trim();
    }

    return trimmed;
  }

  ReportStatusUiData statusUi(String? rawStatus) {
    final status = (rawStatus ?? 'open').trim().toLowerCase();

    switch (status) {
      case 'in_progress':
        return const ReportStatusUiData(
          label: 'In Progress',
          markerHue: 30.0,
        );
      case 'completed':
        return const ReportStatusUiData(
          label: 'Completed',
          markerHue: 120.0,
        );
      case 'open':
      default:
        return const ReportStatusUiData(
          label: 'Open',
          markerHue: 0.0,
        );
    }
  }
}

class ReportStatusUiData {
  final String label;
  final double markerHue;

  const ReportStatusUiData({
    required this.label,
    required this.markerHue,
  });
}
