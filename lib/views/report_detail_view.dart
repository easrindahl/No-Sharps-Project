import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../presenters/report_presenter.dart';
import 'qr_disposal_view.dart';

class ReportDetailView extends StatefulWidget {
  const ReportDetailView({
    super.key,
    required this.report,
    required this.presenter,
  });

  final Map<String, dynamic> report;
  final ReportPresenter presenter;

  @override
  State<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<ReportDetailView> {
  late Map<String, dynamic> _report;
  bool _working = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
  }

  @override
  Widget build(BuildContext context) {
    final location = _report['location'] as String? ?? 'Unknown location';
    final createdRaw = _report['created_at'];
    final createdAt = _parseCreatedAt(createdRaw);
    final submittedDate = createdAt != null
        ? MaterialLocalizations.of(context).formatFullDate(createdAt)
        : 'Unknown date';
    final submittedTime = createdAt != null
        ? MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(createdAt),
          )
        : 'Unknown time';
    final canManage = widget.presenter.canCurrentUserManageReport(_report);

    final status = (_report['pickup_status'] as String? ?? 'open')
        .trim()
        .toLowerCase();
    final statusText = _statusText(status);
    final statusColor = _statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              enabled: !_working && !_busy,
              onSelected: (value) {
                if (value == 'edit') {
                  _editLocation();
                } else if (value == 'delete') {
                  _deleteReport();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit location'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete report'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<String?>(
              future: widget.presenter.getDisplayImageUrl(_report),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildImageLoading(context);
                }

                final imageUrl = snapshot.data;
                if (imageUrl == null || imageUrl.isEmpty) {
                  return _buildImagePlaceholder(context);
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    key: ValueKey(imageUrl),
                    height: 260,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 260,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Report image failed to load: $imageUrl | $error');
                      return _buildImagePlaceholder(context, hasError: true);
                    },
                  ),
                );
              },
            ),
            if (_working) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Submitted',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$submittedDate - $submittedTime',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            if (status == 'open') ...[
              FilledButton.icon(
                onPressed: (_busy || _working) ? null : _markInProgress,
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Claim Pickup'),
              ),
              const SizedBox(height: 12),
              Text(
                'Claiming a pickup changes its status to In Progress so other volunteers know it is already being handled.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (status == 'in_progress') ...[
              FilledButton.icon(
                onPressed: (_busy || _working) ? null : _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Disposal QR'),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan the QR code on a disposal box to confirm the disposal, award points, and remove the report from the app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editLocation() async {
    final reportId = _report['id']?.toString();
    if (reportId == null || reportId.isEmpty) {
      _showMessage('This report cannot be edited.');
      return;
    }

    final newLocation = await showDialog<String>(
      context: context,
      builder: (context) => _EditLocationDialog(
        initialLocation: _report['location'] as String? ?? '',
      ),
    );

    if (!mounted || newLocation == null) return;
    if (newLocation.isEmpty) {
      _showMessage('Location is required.');
      return;
    }

    setState(() => _working = true);
    try {
      await widget.presenter.updateReportLocation(
        reportId: reportId,
        location: newLocation,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not update report: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteReport() async {
    final reportId = _report['id']?.toString();
    if (reportId == null || reportId.isEmpty) {
      _showMessage('This report cannot be deleted.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
          'This will permanently delete your report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _working = true);
    try {
      await widget.presenter.deleteReport(reportId: reportId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not delete report: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _markInProgress() async {
    final reportId = _report['id']?.toString();
    if (reportId == null || reportId.isEmpty) return;

    setState(() => _busy = true);
    try {
      await widget.presenter.markReportInProgress(reportId);
      if (!mounted) return;

      setState(() {
        _report['pickup_status'] = 'in_progress';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report marked as in progress.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not claim pickup: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openQrScanner() async {
    final qrValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrDisposalView(),
      ),
    );

    if (qrValue == null || qrValue.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await widget.presenter.completeDisposalWithQr(
        report: _report,
        qrValue: qrValue,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disposal confirmed. Points were added and report removed.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not confirm disposal: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildImagePlaceholder(BuildContext context, {bool hasError = false}) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.broken_image_outlined : Icons.image_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                'Could not load image',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoading(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _statusText(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'open':
      default:
        return 'Open';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'open':
      default:
        return Colors.red;
    }
  }
}

class _EditLocationSuggestion {
  final String description;
  final String secondaryText;

  const _EditLocationSuggestion({
    required this.description,
    required this.secondaryText,
  });

  factory _EditLocationSuggestion.fromJson(Map<String, dynamic> json) {
    return _EditLocationSuggestion(
      description: json['description']?.toString() ?? '',
      secondaryText: json['types']?.isNotEmpty == true
          ? (json['types'] as List).first.toString()
          : '',
    );
  }
}

class _EditLocationDialog extends StatefulWidget {
  const _EditLocationDialog({required this.initialLocation});

  final String initialLocation;

  @override
  State<_EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends State<_EditLocationDialog> {
  static const String _googleApiKey = 'AIzaSyCqQ5m2e49uP6D_HfDL-W2otxC3wLuVKbQ';

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _gettingLocation = false;
  bool _settingTextProgrammatically = false;
  List<_EditLocationSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLocation);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_settingTextProgrammatically) return;

    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _getLocationSuggestions(input);
  }

  Future<void> _getLocationSuggestions(String input) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&components=country:us';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final List<dynamic> predictions = data['predictions'] ?? [];
      final suggestions =
          predictions.map((p) => _EditLocationSuggestion.fromJson(p)).toList();

      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted || placemarks.isEmpty) return;
      final place = placemarks.first;
      final address =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';

      _settingTextProgrammatically = true;
      _controller.text = address;
      _settingTextProgrammatically = false;

      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Location'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter location or use your current location',
                  border: const OutlineInputBorder(),
                  suffixIcon: _gettingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.location_on),
                          tooltip: 'Use my location',
                          onPressed: _useCurrentLocation,
                        ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tip: Tap the location icon to use your GPS location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(suggestion.description),
                        subtitle: suggestion.secondaryText.isEmpty
                            ? null
                            : Text(
                                suggestion.secondaryText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () {
                          _settingTextProgrammatically = true;
                          _controller.text = suggestion.description;
                          _settingTextProgrammatically = false;
                          setState(() {
                            _showSuggestions = false;
                            _suggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}
