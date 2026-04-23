import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPresenter {
  static const int _reportPointValue = 1;
  static const int _pickupPointValue = 2;

  final SupabaseClient supabase;
  ReportPresenter(this.supabase);

  String? get currentUserId => supabase.auth.currentUser?.id;

  bool canCurrentUserManageReport(Map<String, dynamic> report) {
    final ownerId = report['user_id']?.toString();
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return false;
    if (ownerId == null || ownerId.isEmpty) return false;
    return ownerId == userId;
  }

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
    await _incrementRewards(
      userId: userId,
      reportDelta: 1,
      pickupDelta: 0,
    );
  }

  Future<void> awardPickupPoints(String userId) async {
    await _incrementRewards(
      userId: userId,
      reportDelta: 0,
      pickupDelta: 2,
    );
  }

  Future<void> _incrementRewards({
    required String userId,
    required int reportDelta,
    required int pickupDelta,
  }) async {
    final existing = await supabase
        .from('user_rewards')
        .select()
        .eq('id', userId)
        .maybeSingle();

    final int currentReportCount = (existing?['report_count'] as num?)?.toInt() ??
        0;
    final int currentPickupCount = (existing?['pickup_count'] as num?)?.toInt() ??
        0;

    final int nextReportCount = currentReportCount + reportDelta;
    final int nextPickupCount = currentPickupCount + pickupDelta;
    final int nextTotalPoints =
        (nextReportCount * _reportPointValue) +
        (nextPickupCount * _pickupPointValue);

    if (existing == null) {
      await supabase.from('user_rewards').insert({
        'id': userId,
        'report_count': nextReportCount,
        'pickup_count': nextPickupCount,
        'total_points': nextTotalPoints,
      });
    } else {
      await supabase.from('user_rewards').update({
        'report_count': nextReportCount,
        'pickup_count': nextPickupCount,
        'total_points': nextTotalPoints,
      }).eq('id', userId);
    }

    await _syncProfilePoints(userId, nextTotalPoints);
  }

  Future<void> _syncProfilePoints(String userId, int totalPoints) async {
    final currentUser = supabase.auth.currentUser;

    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('profiles').insert({
        'id': userId,
        'email': currentUser?.id == userId ? currentUser?.email : null,
        'points': totalPoints,
      });
      return;
    }

    await supabase
        .from('profiles')
        .update({'points': totalPoints})
        .eq('id', userId);
  }

  Future<void> updateReportLocation({
    required String reportId,
    required String location,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('You must be signed in to edit reports.');
    }

    await supabase
        .from('reports')
        .update({'location': location.trim()})
        .eq('id', reportId)
        .eq('user_id', userId);
  }

  Future<void> deleteReport({required String reportId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('You must be signed in to delete reports.');
    }

    final existing = await supabase
        .from('reports')
      .select('image_path')
        .eq('id', reportId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      throw StateError('Report not found or not owned by current user.');
    }

    await supabase
        .from('reports')
        .delete()
        .eq('id', reportId)
        .eq('user_id', userId);

    final imagePath = _normalizeImagePath(existing['image_path'] as String?);
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        await supabase.storage.from('needles').remove([imagePath]);
      } catch (_) {
        // Do not fail deletion if image cleanup is blocked by storage policy.
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchReports({int limit = 10}) async {
    final rows = await supabase
        .from('reports')
        .select(
      'id, location, created_at, image_path, latitude, longitude, pickup_status, pickup_user_id, pickup_claimed_at, user_id',
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
