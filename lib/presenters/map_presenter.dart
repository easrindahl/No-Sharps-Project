import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/disposal_box_model.dart';
import '../models/report_model.dart';

class MapPresenter {
  final SupabaseClient supabase;
  MapPresenter(this.supabase);

  Future<List<ReportModel>> fetchReportMarkers({int limit = 200}) async {
    final rows = await supabase
        .from('reports')
        .select(
          'id, location, created_at, image_path, latitude, longitude, '
          'pickup_status, pickup_user_id, pickup_claimed_at',
        )
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((r) => ReportModel.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<List<DisposalBoxModel>> fetchDisposalBoxes() async {
    final rows = await supabase
        .from('disposal_boxes')
        .select('id, name, latitude, longitude');

    return (rows as List)
        .map((r) => DisposalBoxModel.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }
}
