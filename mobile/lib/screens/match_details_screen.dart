import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({
    super.key,
    required this.result,
  });

  final Map<String, dynamic> result;

  @override
  State<MatchDetailsScreen> createState() =>
      _MatchDetailsScreenState();
}

class _MatchDetailsScreenState
    extends State<MatchDetailsScreen> {
  bool isLoading = false;

  late String currentStatus;
  late String? createdAt;
  late String? removalRequestedAt;
  late String? removedAt;

  String? message;

  @override
  void initState() {
    super.initState();

    currentStatus =
        widget.result['status']?.toString() ??
            'possible_match';

    createdAt =
        widget.result['created_at']?.toString();

    removalRequestedAt =
        widget.result['removal_requested_at']
            ?.toString();

    removedAt =
        widget.result['removed_at']?.toString();
  }

  String get resultId {
    return widget.result['id']?.toString() ?? '';
  }

  String get sourceName {
    return widget.result['source_name']
            ?.toString() ??
        'Unknown source';
  }

  String get matchedName {
    return widget.result['matched_name']
            ?.toString() ??
        'Not available';
  }

  String get matchedEmail {
    return widget.result['matched_email']
            ?.toString() ??
        'Not available';
  }

  String get matchedPhone {
    return widget.result['matched_phone']
            ?.toString() ??
        'Not available';
  }

  String get matchedAddress {
    return widget.result['matched_address']
            ?.toString() ??
        'Not available';
  }

  String get sourceUrl {
    return widget.result['source_url']
            ?.toString() ??
        'Not available';
  }

  String get confidence {
    final value =
        widget.result['confidence_score'];

    if (value == null) {
      return 'Not available';
    }

    return '$value%';
  }

  String friendlyStatus(String status) {
    if (status == 'possible_match') {
      return 'Possible Match';
    }

    if (status == 'removal_requested') {
      return 'Removal Requested';
    }

    if (status == 'removed') {
      return 'Removed';
    }

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return '';
          }

          return '${word[0].toUpperCase()}'
              '${word.substring(1)}';
        })
        .join(' ');
  }

  Color statusColor(
    BuildContext context,
  ) {
    if (currentStatus == 'removed') {
      return Colors.green;
    }

    if (currentStatus ==
        'removal_requested') {
      return Colors.orange;
    }

    return Theme.of(context)
        .colorScheme
        .error;
  }

  IconData statusIcon() {
    if (currentStatus == 'removed') {
      return Icons.check_circle_outline;
    }

    if (currentStatus ==
        'removal_requested') {
      return Icons.schedule;
    }

    return Icons.warning_amber_rounded;
  }

  String formatDateTime(
    String? rawValue,
  ) {
    if (rawValue == null ||
        rawValue.trim().isEmpty) {
      return 'Not yet';
    }

    final parsed =
        DateTime.tryParse(rawValue);

    if (parsed == null) {
      return rawValue;
    }

    final local = parsed.toLocal();

    final month =
        local.month.toString().padLeft(2, '0');

    final day =
        local.day.toString().padLeft(2, '0');

    final year =
        local.year.toString().padLeft(4, '0');

    var hour = local.hour;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final period =
        hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$month/$day/$year at '
        '$hour:$minute $period';
  }

  String removalAge() {
    if (removalRequestedAt == null ||
        removalRequestedAt!.trim().isEmpty) {
      return 'Removal request pending';
    }

    final parsed =
        DateTime.tryParse(
          removalRequestedAt!,
        );

    if (parsed == null) {
      return 'Removal request pending';
    }

    final requested = parsed.toLocal();
    final now = DateTime.now();

    final requestedDay = DateTime(
      requested.year,
      requested.month,
      requested.day,
    );

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final days =
        today.difference(requestedDay).inDays;

    if (days <= 0) {
      return 'Requested today';
    }

    if (days == 1) {
      return 'Requested yesterday';
    }

    return 'Requested $days days ago';
  }

  bool get isRemovalOverdue {
    if (removalRequestedAt == null ||
        removalRequestedAt!.trim().isEmpty) {
      return false;
    }

    final parsed =
        DateTime.tryParse(
          removalRequestedAt!,
        );

    if (parsed == null) {
      return false;
    }

    return DateTime.now()
            .difference(parsed.toLocal())
            .inDays >=
        7;
  }

  bool get hasValidSourceUrl {
    final uri = Uri.tryParse(sourceUrl);

    return uri != null &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> openSource() async {
    final uri = Uri.tryParse(sourceUrl);

    if (uri == null ||
        !hasValidSourceUrl) {
      if (!mounted) {
        return;
      }

      setState(() {
        message =
            'This result does not have a valid source link.';
      });

      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        setState(() {
          message =
              'Could not open the source.';
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        message =
            'Could not open the source: $error';
      });
    }
  }

  Future<void> requestRemoval() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Request Removal?',
          ),
          content: Text(
            'TraceLocked will mark this '
            '$sourceName result as a '
            'removal request.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Request Removal',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await updateStatus(
      'removal_requested',
    );
  }

  Future<void> markRemoved() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Mark as Removed?',
          ),
          content: const Text(
            'Use this only after you have '
            'confirmed that the exposed '
            'information is no longer '
            'available at the source.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Mark Removed',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await updateStatus(
      'removed',
    );
  }

  Future<void> updateStatus(
    String newStatus,
  ) async {
    if (resultId.isEmpty) {
      setState(() {
        message =
            'This scan result does not '
            'have a valid ID.';
      });

      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final response =
          await ApiService.updateScanStatus(
        resultId: resultId,
        newStatus: newStatus,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        currentStatus =
            response['status']?.toString() ??
                newStatus;

        createdAt =
            response['created_at']
                    ?.toString() ??
                createdAt;

        removalRequestedAt =
            response['removal_requested_at']
                ?.toString();

        removedAt =
            response['removed_at']
                ?.toString();

        if (currentStatus ==
            'removal_requested') {
          message =
              'Removal request saved '
              'successfully.';
        } else if (
            currentStatus == 'removed') {
          message =
              'This result is now marked '
              'as removed.';
        } else {
          message =
              'Status updated successfully.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget buildStatusCard() {
    final color =
        statusColor(context);

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  color.withValues(
                alpha: 0.12,
              ),
              child: Icon(
                statusIcon(),
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendlyStatus(
                      currentStatus,
                    ),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  if (currentStatus ==
                      'removal_requested') ...[
                    const SizedBox(height: 5),
                    Text(
                      removalAge(),
                      style: TextStyle(
                        color:
                            isRemovalOverdue
                                ? Theme.of(
                                    context,
                                  )
                                    .colorScheme
                                    .error
                                : null,
                        fontWeight:
                            isRemovalOverdue
                                ? FontWeight.bold
                                : FontWeight
                                    .normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Widget buildSourceCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.link),
                SizedBox(width: 16),
                Text(
                  'Source',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              sourceUrl,
            ),
            if (hasValidSourceUrl) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: openSource,
                icon: const Icon(
                  Icons.open_in_new,
                ),
                label: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Text(
                    'Open Source',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildTimeline() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Activity History',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _TimelineItem(
              icon: Icons.search,
              title: 'Exposure Found',
              value:
                  formatDateTime(createdAt),
              complete: true,
            ),
            _TimelineItem(
              icon: Icons.send_outlined,
              title: 'Removal Requested',
              value: formatDateTime(
                removalRequestedAt,
              ),
              complete:
                  removalRequestedAt != null,
            ),
            _TimelineItem(
              icon:
                  Icons.check_circle_outline,
              title: 'Removed',
              value:
                  formatDateTime(removedAt),
              complete: removedAt != null,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRemovalWorkflow() {
    if (currentStatus == 'removed') {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 52,
              ),
              const SizedBox(height: 12),
              const Text(
                'Removal Complete',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$sourceName has been '
                'marked as removed.',
                textAlign:
                    TextAlign.center,
              ),
              if (removedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  formatDateTime(
                    removedAt,
                  ),
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (currentStatus ==
        'removal_requested') {
      final overdue =
          isRemovalOverdue;

      final color = overdue
          ? Theme.of(context)
              .colorScheme
              .error
          : Colors.orange;

      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    overdue
                        ? Icons
                            .priority_high_rounded
                        : Icons.schedule,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      overdue
                          ? 'Removal Still Pending'
                          : 'Removal Requested',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color: overdue
                            ? color
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                removalAge(),
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  color: overdue
                      ? color
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                overdue
                    ? 'This removal request '
                        'has been pending for '
                        'at least 7 days. '
                        'Check the source to '
                        'see whether the '
                        'information has been '
                        'removed.'
                    : 'This match is currently '
                        'marked as waiting for '
                        'removal.',
              ),
              if (hasValidSourceUrl) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: openSource,
                  icon: const Icon(
                    Icons.open_in_new,
                  ),
                  label: const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    child: Text(
                      'Check Source',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : markRemoved,
                icon: const Icon(
                  Icons
                      .check_circle_outline,
                ),
                label: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  child: Text(
                    'Mark as Removed',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        if (hasValidSourceUrl) ...[
          OutlinedButton.icon(
            onPressed: openSource,
            icon: const Icon(
              Icons.open_in_new,
            ),
            label: const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Text(
                'Check Source',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed:
              isLoading
                  ? null
                  : requestRemoval,
          icon: const Icon(
            Icons.delete_outline,
          ),
          label: const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Text(
              'Request Removal',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match Details',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Text(
            sourceName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Potential privacy exposure',
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
          const SizedBox(height: 20),

          buildStatusCard(),

          const SizedBox(height: 12),

          buildTimeline(),

          const SizedBox(height: 12),

          buildDetailCard(
            icon:
                Icons.analytics_outlined,
            label: 'Confidence',
            value: confidence,
          ),

          buildDetailCard(
            icon: Icons.person_outline,
            label: 'Matched Name',
            value: matchedName,
          ),

          buildDetailCard(
            icon: Icons.email_outlined,
            label: 'Matched Email',
            value: matchedEmail,
          ),

          buildDetailCard(
            icon: Icons.phone_outlined,
            label: 'Matched Phone',
            value: matchedPhone,
          ),

          buildDetailCard(
            icon: Icons.home_outlined,
            label: 'Matched Address',
            value: matchedAddress,
          ),

          buildSourceCard(),

          const SizedBox(height: 24),

          buildRemovalWorkflow(),

          if (isLoading) ...[
            const SizedBox(height: 20),
            const Center(
              child:
                  CircularProgressIndicator(),
            ),
          ],

          if (message != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Text(
                  message!,
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.complete,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool complete;
  final bool isLast;

  @override
  Widget build(
    BuildContext context,
  ) {
    final activeColor =
        complete
            ? Colors.green
            : Theme.of(context)
                .colorScheme
                .outline;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 18,
              child: Icon(
                icon,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color:
                    activeColor.withValues(
                  alpha: 0.35,
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 4,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: complete
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: complete
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}