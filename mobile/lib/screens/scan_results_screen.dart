import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'match_details_screen.dart';

class ScanResultsScreen extends StatefulWidget {
  const ScanResultsScreen({
    super.key,
    required this.profileId,
  });

  final String profileId;

  @override
  State<ScanResultsScreen> createState() =>
      _ScanResultsScreenState();
}

class _ScanResultsScreenState
    extends State<ScanResultsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> results = [];

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getScanResults(
        widget.profileId,
      );

      if (!mounted) return;

      setState(() {
        results = data['results'] ?? [];
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get foundResults {
    return results
        .where((item) {
          final result =
              item as Map<String, dynamic>;

          final status =
              result['status']?.toString() ?? '';

          return status != 'removal_requested' &&
              status != 'removed';
        })
        .map(
          (item) =>
              item as Map<String, dynamic>,
        )
        .toList();
  }

  List<Map<String, dynamic>>
      get removalRequestedResults {
    return results
        .where((item) {
          final result =
              item as Map<String, dynamic>;

          return result['status']?.toString() ==
              'removal_requested';
        })
        .map(
          (item) =>
              item as Map<String, dynamic>,
        )
        .toList();
  }

  List<Map<String, dynamic>> get removedResults {
    return results
        .where((item) {
          final result =
              item as Map<String, dynamic>;

          return result['status']?.toString() ==
              'removed';
        })
        .map(
          (item) =>
              item as Map<String, dynamic>,
        )
        .toList();
  }

  Color statusColor(
    BuildContext context,
    String status,
  ) {
    if (status == 'removed') {
      return Colors.green;
    }

    if (status == 'removal_requested') {
      return Colors.orange;
    }

    return Theme.of(context).colorScheme.error;
  }

  IconData statusIcon(String status) {
    if (status == 'removed') {
      return Icons.check_circle_outline;
    }

    if (status == 'removal_requested') {
      return Icons.hourglass_top;
    }

    return Icons.warning_amber_rounded;
  }

  String friendlyStatus(String status) {
    if (status == 'removed') {
      return 'Removed';
    }

    if (status == 'removal_requested') {
      return 'Removal Requested';
    }

    if (status == 'possible_match') {
      return 'Possible Match';
    }

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';

          return '${word[0].toUpperCase()}'
              '${word.substring(1)}';
        })
        .join(' ');
  }

  Future<void> openResult(
    Map<String, dynamic> result,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchDetailsScreen(
          result: result,
        ),
      ),
    );

    if (!mounted) return;

    await loadResults();
  }

  Widget buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${results.length}',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Text(
              'Total Results',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon:
                        Icons.warning_amber_rounded,
                    label: 'Found',
                    value: foundResults.length,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon:
                        Icons.hourglass_top,
                    label: 'Pending',
                    value:
                        removalRequestedResults.length,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon:
                        Icons.check_circle_outline,
                    label: 'Removed',
                    value: removedResults.length,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>>
        sectionResults,
  }) {
    if (sectionResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
        ),

        const SizedBox(height: 12),

        ...sectionResults.map(
          (result) => buildResultCard(result),
        ),
      ],
    );
  }

  Widget buildResultCard(
    Map<String, dynamic> result,
  ) {
    final status =
        result['status']?.toString() ??
            'unknown';

    final confidence =
        result['confidence_score'];

    final sourceName =
        result['source_name']?.toString() ??
            'Unknown source';

    final matchedName =
        result['matched_name']?.toString();

    final matchedEmail =
        result['matched_email']?.toString();

    final matchedPhone =
        result['matched_phone']?.toString();

    final matchedAddress =
        result['matched_address']?.toString();

    final matchedItems = <String>[];

    if (matchedName != null &&
        matchedName.isNotEmpty) {
      matchedItems.add('Name');
    }

    if (matchedEmail != null &&
        matchedEmail.isNotEmpty) {
      matchedItems.add('Email');
    }

    if (matchedPhone != null &&
        matchedPhone.isNotEmpty) {
      matchedItems.add('Phone');
    }

    if (matchedAddress != null &&
        matchedAddress.isNotEmpty) {
      matchedItems.add('Address');
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          openResult(result);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      statusIcon(status),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          sourceName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          friendlyStatus(status),
                          style: TextStyle(
                            color: statusColor(
                              context,
                              status,
                            ),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (confidence != null)
                Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Confidence: $confidence%',
                    ),
                  ],
                ),

              if (matchedItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Matched: '
                        '${matchedItems.join(', ')}',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildResultsBody() {
    if (results.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadResults,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.shield_outlined,
              size: 72,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No scan results found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadResults,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          buildSummaryCard(),

          buildSection(
            title: 'Found',
            subtitle:
                'Information that may be exposed online.',
            sectionResults: foundResults,
          ),

          buildSection(
            title: 'Removal Requested',
            subtitle:
                'Matches currently waiting for removal.',
            sectionResults:
                removalRequestedResults,
          ),

          buildSection(
            title: 'Removed',
            subtitle:
                'Matches marked as successfully removed.',
            sectionResults: removedResults,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Results',
        ),
        actions: [
          IconButton(
            onPressed:
                isLoading ? null : loadResults,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        FilledButton(
                          onPressed:
                              loadResults,
                          child: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : buildResultsBody(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}