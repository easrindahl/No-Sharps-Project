import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/disposal_box_model.dart';
import '../models/report_model.dart';
import '../presenters/report_presenter.dart';
import 'report_detail_view.dart'; // Import ReportDetailView
import '../presenters/map_presenter.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late final ReportPresenter _presenter;
  late final MapPresenter _mapPresenter;

  List<Map<String, dynamic>> _reports = [];
  bool _feedLoading = true;
  String? _feedError;

  Set<Marker> _markers = {};
  bool _markersLoading = true;
  String? _markersError;

  List<ReportModel> _cachedReportMarkers = [];
  List<DisposalBoxModel> _cachedDisposalBoxes = [];

  GoogleMapController? _mapController;
  String? _selectedReportId;

  static const LatLng _initialPosition = LatLng(46.7834, -92.1006);
  static const double _focusZoom = 16;

  @override
  void initState() {
    super.initState();
    _presenter = ReportPresenter(Supabase.instance.client);
    _mapPresenter = MapPresenter(Supabase.instance.client);
    _loadFeed();
    _loadMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _feedLoading = true;
      _feedError = null;
    });
    try {
      final rows = await _presenter.fetchReports(limit: 30);
      if (!mounted) return;
      setState(() {
        _reports = rows;
        _feedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedError = e.toString();
        _feedLoading = false;
      });
    }
  }

  Set<Marker> _buildMarkers({
    required List<ReportModel> reports,
    required List<DisposalBoxModel> boxes,
  }) {
    final markers = <Marker>{};
    final loc = MaterialLocalizations.of(context);

    for (final r in reports) {
      if (!r.hasCoordinates) continue;
      final created = r.createdAt;
      final createdLabel = created == null ? '' : loc.formatMediumDate(created);
      final isSelected = r.id == _selectedReportId;

      markers.add(
        Marker(
          markerId: MarkerId('report_${r.id}'),
          position: LatLng(r.latitude!, r.longitude!),
          zIndexInt: isSelected ? 2 : 1,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRose : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: r.location?.isNotEmpty == true
                ? r.location
                : 'Needle report',
            snippet: createdLabel.isEmpty ? null : createdLabel,
          ),
        ),
      );
    }

    for (final b in boxes) {
      markers.add(
        Marker(
          markerId: MarkerId('box_${b.id}'),
          position: LatLng(b.latitude, b.longitude),
          zIndexInt: 0,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: b.name),
        ),
      );
    }

    return markers;
  }

  Future<void> _loadMarkers() async {
    setState(() {
      _markersLoading = true;
      _markersError = null;
      _selectedReportId = null;
    });

    try {
      final reports = await _mapPresenter.fetchReportMarkers();
      final boxes = await _mapPresenter.fetchDisposalBoxes();

      if (!mounted) return;
      setState(() {
        _cachedReportMarkers = reports;
        _cachedDisposalBoxes = boxes;
        _markers = _buildMarkers(reports: reports, boxes: boxes);
        _markersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _markersError = e.toString();
        _markersLoading = false;
      });
    }
  }

  void _onFeedReportTap(Map<String, dynamic> row) {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;

    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This report has no map location')),
      );
      return;
    }

    setState(() {
      _selectedReportId = id;
      _markers = _buildMarkers(
        reports: _cachedReportMarkers,
        boxes: _cachedDisposalBoxes,
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), _focusZoom),
    );
  }

  void _openReportDetails(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReportDetailView(report: report, presenter: _presenter),
      ),
    );
  }

  void _onMapTap(LatLng _) {
    if (_selectedReportId == null) return;
    setState(() {
      _selectedReportId = null;
      _markers = _buildMarkers(
        reports: _cachedReportMarkers,
        boxes: _cachedDisposalBoxes,
      );
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadFeed(), _loadMarkers()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_feedLoading || _markersLoading) ? null : _refreshAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 15,
              ),
              onMapCreated: (c) => _mapController = c,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
            ),
          ),
          if (_markersError != null)
            MaterialBanner(
              content: Text('Could not load map markers: $_markersError'),
              leading: const Icon(Icons.warning_amber_outlined),
              actions: [
                TextButton(
                  onPressed: _markersLoading ? null : _loadMarkers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: _ReportsFeed(
              reports: _reports,
              loading: _feedLoading,
              error: _feedError,
              onRetry: _loadFeed,
              presenter: _presenter,
              selectedReportId: _selectedReportId,
              onReportTap: _onFeedReportTap,
              onOpenDetails: _openReportDetails,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsFeed extends StatelessWidget {
  const _ReportsFeed({
    required this.reports,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.presenter,
    required this.selectedReportId,
    required this.onReportTap,
    required this.onOpenDetails,
  });

  final List<Map<String, dynamic>> reports;
  final bool loading;
  final String? error;
  final ReportPresenter presenter;
  final VoidCallback onRetry;
  final String? selectedReportId;
  final void Function(Map<String, dynamic> row) onReportTap;
  final void Function(Map<String, dynamic> report) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (loading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load reports',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (reports.isEmpty) {
      return Center(
        child: Text(
          'No reports yet',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Recent reports',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = reports[index];
              final id = report['id']?.toString();
              final isSelected =
                  id != null && selectedReportId != null && id == selectedReportId;
              return _ReportFeedTile(
                report: report,
                presenter: presenter,
                isSelected: isSelected,
                onTap: () => onReportTap(report),
                onOpenDetails: () => onOpenDetails(report),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportFeedTile extends StatelessWidget {
  const _ReportFeedTile({
    required this.report,
    required this.presenter,
    required this.isSelected,
    required this.onTap,
    required this.onOpenDetails,
  });

  final Map<String, dynamic> report;
  final ReportPresenter presenter;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final location = report['location'] as String? ?? 'Unknown location';
    final createdRaw = report['created_at'] as String?;
    String subtitle = '';
    if (createdRaw != null) {
      final parsed = DateTime.tryParse(createdRaw);
      if (parsed != null) {
        subtitle = MaterialLocalizations.of(context).formatMediumDate(parsed);
      }
    }

    final borderColor = Theme.of(context).colorScheme.primary;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: borderColor, width: 2) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: presenter.getDisplayImageUrl(report),
                  builder: (context, snapshot) {
                    final imageUrl = snapshot.data;
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return _placeholderThumb(context);
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholderThumb(context),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Details',
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.place_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
