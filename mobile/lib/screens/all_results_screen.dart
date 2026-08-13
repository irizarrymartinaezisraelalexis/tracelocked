import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'match_details_screen.dart';

class AllResultsScreen extends StatefulWidget {
  const AllResultsScreen({
    super.key,
    this.initialFilter = 'all',
  });

  final String initialFilter;

  @override
  State<AllResultsScreen> createState() =>
      _AllResultsScreenState();
}

class _AllResultsScreenState extends State<AllResultsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> allResults = [];

  late String selectedFilter;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    loadAllResults();
  }

  Future<void> loadAllResults() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final profiles = await ApiService.getProfiles();

      final combinedResults =
          <Map<String, dynamic>>[];

      for (final item in profiles) {
        final profile =
            item as Map<String, dynamic>;

        final profileId =
            profile['profile_id']?.toString();

        if (profileId == null ||
            profileId.isEmpty) {
          continue;
        }

        final data =
            await ApiService.getScanResults(
          profileId,
        );

        final results =
            data['results'] as List<dynamic>? ?? [];

        final firstName =
            profile['first_name']?.toString() ?? '';

        final lastName =
            profile['last_name']?.toString() ?? '';

        final profileName =
            '$firstName $lastName'.trim();

        for (final resultItem in results) {
          final result =
              Map<String, dynamic>.from(
            resultItem as Map<String, dynamic>,
          );

          result['profile_name'] =
              profileName.isEmpty
                  ? 'Privacy Profile'
                  : profileName;

          combinedResults.add(result);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        allResults = combinedResults;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  int countForStatus(String filter) {
    if (filter == 'all') {
      return allResults.length;
    }

    return allResults.where((result) {
      final status =
          result['status']?.toString() ?? '';

      if (filter == 'found') {
        return status == 'possible_match';
      }

      if (filter == 'removal_requested') {
        return status == 'removal_requested';
      }

      if (filter == 'removed') {
        return status == 'removed';
      }

      return false;
    }).length;
  }

  List<Map<String, dynamic>>
      get filteredResults {
    return allResults.where((result) {
      final status =
          result['status']?.toString() ?? '';

      bool matchesStatus = true;

      if (selectedFilter == 'found') {
        matchesStatus =
            status == 'possible_match';
      } else if (
          selectedFilter == 'removal_requested') {
        matchesStatus =
            status == 'removal_requested';
      } else if (selectedFilter == 'removed') {
        matchesStatus =
            status == 'removed';
      }

      if (!matchesStatus) {
        return false;
      }

      final query =
          searchQuery.trim().toLowerCase();

      if (query.isEmpty) {
        return true;
      }

      final sourceName =
          result['source_name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final profileName =
          result['profile_name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final matchedName =
          result['matched_name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final matchedEmail =
          result['matched_email']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final matchedPhone =
          result['matched_phone']
                  ?.toString()
                  .toLowerCase() ??
              '';

      return sourceName.contains(query) ||
          profileName.contains(query) ||
          matchedName.contains(query) ||
          matchedEmail.contains(query) ||
          matchedPhone.contains(query);
    }).toList();
  }

  String friendlyStatus(String status) {
    if (status == 'possible_match') {
      return 'Found';
    }

    if (status == 'removal_requested') {
      return 'Removal Requested';
    }

    if (status == 'removed') {
      return 'Removed';
    }

    return status;
  }

  IconData statusIcon(String status) {
    if (status == 'removed') {
      return Icons.check_circle_outline;
    }

    if (status == 'removal_requested') {
      return Icons.schedule;
    }

    return Icons.warning_amber_rounded;
  }

  Color statusColor(String status) {
    if (status == 'removed') {
      return Colors.green;
    }

    if (status == 'removal_requested') {
      return Colors.orange;
    }

    return Theme.of(context).colorScheme.error;
  }

  String formatDate(String? rawValue) {
    if (rawValue == null ||
        rawValue.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(rawValue);

    if (parsed == null) {
      return rawValue;
    }

    final local = parsed.toLocal();

    final month =
        local.month.toString().padLeft(2, '0');

    final day =
        local.day.toString().padLeft(2, '0');

    return '$month/$day/${local.year}';
  }

  String removalAge(String? rawValue) {
    if (rawValue == null ||
        rawValue.trim().isEmpty) {
      return 'Removal requested';
    }

    final parsed = DateTime.tryParse(rawValue);

    if (parsed == null) {
      return 'Removal requested';
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

  bool isRemovalOverdue(String? rawValue) {
    if (rawValue == null ||
        rawValue.trim().isEmpty) {
      return false;
    }

    final parsed = DateTime.tryParse(rawValue);

    if (parsed == null) {
      return false;
    }

    return DateTime.now()
            .difference(parsed.toLocal())
            .inDays >=
        7;
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

    if (!mounted) {
      return;
    }

    await loadAllResults();
  }

  Widget buildFilterChip({
    required String value,
    required String label,
  }) {
    return ChoiceChip(
      label: Text(
        '$label (${countForStatus(value)})',
      ),
      selected: selectedFilter == value,
      onSelected: (_) {
        setState(() {
          selectedFilter = value;
        });
      },
    );
  }

  Widget buildResultCard(
    Map<String, dynamic> result,
  ) {
    final sourceName =
        result['source_name']?.toString() ??
            'Unknown source';

    final profileName =
        result['profile_name']?.toString() ??
            'Privacy Profile';

    final status =
        result['status']?.toString() ??
            'possible_match';

    final confidence =
        result['confidence_score'];

    final createdAt =
        result['created_at']?.toString();

    final removalRequestedAt =
        result['removal_requested_at']
            ?.toString();

    final removedAt =
        result['removed_at']?.toString();

    final overdue =
        status == 'removal_requested' &&
            isRemovalOverdue(
              removalRequestedAt,
            );

    final color = statusColor(status);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        onTap: () {
          openResult(result);
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(
            alpha: 0.12,
          ),
          child: Icon(
            statusIcon(status),
            color: color,
          ),
        ),
        title: Text(
          sourceName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            Text(profileName),

            const SizedBox(height: 4),

            Text(
              friendlyStatus(status),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (status ==
                'removal_requested') ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    overdue
                        ? Icons
                            .priority_high_rounded
                        : Icons
                            .schedule_outlined,
                    size: 16,
                    color: overdue
                        ? Theme.of(context)
                            .colorScheme
                            .error
                        : Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      removalAge(
                        removalRequestedAt,
                      ),
                      style: TextStyle(
                        color: overdue
                            ? Theme.of(context)
                                .colorScheme
                                .error
                            : null,
                        fontWeight: overdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (status == 'removed' &&
                removedAt != null) ...[
              const SizedBox(height: 3),
              Text(
                'Removed: '
                '${formatDate(removedAt)}',
              ),
            ],

            if (confidence != null)
              Text(
                'Confidence: $confidence%',
              ),

            if (createdAt != null)
              Text(
                'Found: '
                '${formatDate(createdAt)}',
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleResults =
        filteredResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Results',
        ),
        actions: [
          IconButton(
            onPressed:
                isLoading ? null : loadAllResults,
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
                              loadAllResults,
                          child: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      loadAllResults,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(16),
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Search Results',
                          hintText:
                              'Name, source, email, phone...',
                          prefixIcon:
                              Icon(Icons.search),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child: Row(
                          children: [
                            buildFilterChip(
                              value: 'all',
                              label: 'All',
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            buildFilterChip(
                              value: 'found',
                              label: 'Found',
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            buildFilterChip(
                              value:
                                  'removal_requested',
                              label:
                                  'Removal Requested',
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            buildFilterChip(
                              value: 'removed',
                              label: 'Removed',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      if (visibleResults.isEmpty)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            top: 70,
                          ),
                          child: Center(
                            child: Text(
                              'No results in this category.',
                            ),
                          ),
                        )
                      else
                        ...visibleResults.map(
                          buildResultCard,
                        ),
                    ],
                  ),
                ),
    );
  }
}