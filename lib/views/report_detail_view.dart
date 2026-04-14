import 'package:flutter/material.dart';
import '../presenters/report_presenter.dart';

class ReportDetailView extends StatelessWidget {
  const ReportDetailView({super.key, required this.report, required this.presenter});

  final Map<String, dynamic> report;
  final ReportPresenter presenter;

  @override
  Widget build(BuildContext context) {
    // Extract data from the report map
    final location = report['location'] as String? ?? 'Unknown location';
    
    // Use the presenter to convert the image_path into a viewable URL.
    // This handles your requirement of images being stored as paths, not URLs
    final imageUrl = presenter.getImageUrl(report);
    final createdRaw = report['created_at'];
    final createdAt = _parseCreatedAt(createdRaw);
    final submittedDate = createdAt != null
        ? MaterialLocalizations.of(context).formatFullDate(createdAt)
        : 'Unknown date';
    final submittedTime = createdAt != null
        ? MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(createdAt),
          )
        : 'Unknown time';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  key: ValueKey(imageUrl), // Bypass potential cache issues
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
                    // Log the detailed error to the console
                    return _buildImagePlaceholder(context, hasError: true);
                  },
                ),
              )
            else
              _buildImagePlaceholder(context),
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
          ],
        ),
      ),
    );
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

  DateTime? _parseCreatedAt(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
