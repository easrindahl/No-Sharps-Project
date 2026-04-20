import 'package:flutter/material.dart';
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

    final status = (_report['pickup_status'] as String? ?? 'open').trim().toLowerCase();
    final statusText = _statusText(status);
    final statusColor = _statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
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
              '$submittedDate • $submittedTime',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            if (status == 'open') ...[
              FilledButton.icon(
                onPressed: _busy ? null : _markInProgress,
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
                onPressed: _busy ? null : _openQrScanner,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not claim pickup: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm disposal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
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
