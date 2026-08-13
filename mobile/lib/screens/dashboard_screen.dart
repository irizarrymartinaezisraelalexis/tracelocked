import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'all_results_screen.dart';
import 'match_details_screen.dart';
import 'profiles_screen.dart';
import 'source_scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  bool queueLoading = false;

  String? errorMessage;

  int profiles = 0;
  int scanResults = 0;
  int possibleMatches = 0;
  int removalRequested = 0;
  int removed = 0;
  int riskScore = 0;

  String? latestScan;

  List<Map<String, dynamic>> recentActivity = [];

  String? activeProfileId;
  String? activeProfileName;

  Map<String, dynamic>? activeProfile;

  Map<String, dynamic>? queueSummary;
  List<Map<String, dynamic>> scanTasks = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dashboardData =
          await ApiService.getDashboard();

      final profileData =
          await ApiService.getProfiles();

      final rawActivity =
          dashboardData['recent_activity']
                  as List<dynamic>? ??
              [];

      String? profileId;
      String? profileName;
      Map<String, dynamic>? selectedProfile;

      if (profileData.isNotEmpty) {
        selectedProfile =
            Map<String, dynamic>.from(
          profileData.first,
        );

        profileId =
            selectedProfile['id']?.toString();

        final firstName =
            selectedProfile['first_name']
                    ?.toString() ??
                '';

        final lastName =
            selectedProfile['last_name']
                    ?.toString() ??
                '';

        profileName =
            '$firstName $lastName'.trim();

        if (profileName.isEmpty) {
          profileName =
              'Privacy Profile';
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        profiles =
            _toInt(dashboardData['profiles']);

        scanResults =
            _toInt(
          dashboardData['scan_results'],
        );

        possibleMatches =
            _toInt(
          dashboardData['possible_matches'],
        );

        removalRequested =
            _toInt(
          dashboardData['removal_requested'],
        );

        removed =
            _toInt(
          dashboardData['removed'],
        );

        riskScore =
            _toInt(
          dashboardData['risk_score'],
        );

        latestScan =
            dashboardData['latest_scan']
                ?.toString();

        recentActivity = rawActivity
            .map(
              (item) =>
                  Map<String, dynamic>.from(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        activeProfileId = profileId;
        activeProfileName = profileName;
        activeProfile = selectedProfile;

        isLoading = false;
      });

      if (profileId != null) {
        await loadQueue(profileId);
      }
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

  Future<void> loadQueue(
    String profileId,
  ) async {
    setState(() {
      queueLoading = true;
    });

    try {
      var queue =
          await ApiService.getSavedScanQueue(
        profileId,
      );

      final tasks =
          queue['tasks'] as List<dynamic>? ??
              [];

      if (tasks.isEmpty) {
        queue =
            await ApiService.initializeScanQueue(
          profileId,
        );
      }

      final rawTasks =
          queue['tasks'] as List<dynamic>? ??
              [];

      if (!mounted) {
        return;
      }

      setState(() {
        queueSummary =
            Map<String, dynamic>.from(
          queue['summary'] as Map? ?? {},
        );

        scanTasks = rawTasks
            .map(
              (item) =>
                  Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();

        queueLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        queueLoading = false;
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int get queueTotal =>
      _toInt(queueSummary?['total']);

  int get queuePending =>
      _toInt(queueSummary?['pending']);

  int get queueOpened =>
      _toInt(queueSummary?['opened']);

  int get queueNoMatch =>
      _toInt(queueSummary?['no_match']);

  int get queuePossibleMatches =>
      _toInt(
        queueSummary?['possible_match'],
      );

  int get queueCompleted =>
      _toInt(queueSummary?['completed']);

  int get queueFailed =>
      _toInt(queueSummary?['failed']);

  int get queueFinished =>
      queueNoMatch +
      queueCompleted +
      queueFailed;

  double get queueProgress {
    if (queueTotal == 0) {
      return 0;
    }

    return queueFinished / queueTotal;
  }

  bool isTaskUnfinished(
    Map<String, dynamic> task,
  ) {
    final status =
        task['status']?.toString() ??
            'pending';

    return status == 'pending' ||
        status == 'opened';
  }

  Map<String, dynamic>? get nextTask {
    for (final task in scanTasks) {
      if (isTaskUnfinished(task)) {
        return task;
      }
    }

    return null;
  }

  List<Map<String, dynamic>>
      tasksForSource(
    String sourceKey,
  ) {
    return scanTasks.where(
      (task) {
        return task['source_key']
                ?.toString() ==
            sourceKey;
      },
    ).toList();
  }

  String get riskLabel {
    if (riskScore >= 75) {
      return 'High Risk';
    }

    if (riskScore >= 40) {
      return 'Moderate Risk';
    }

    return 'Low Risk';
  }

  Color get riskColor {
    if (riskScore >= 75) {
      return Colors.red;
    }

    if (riskScore >= 40) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String formatDateTime(
    String? rawValue,
  ) {
    if (rawValue == null ||
        rawValue.trim().isEmpty) {
      return 'Not available';
    }

    final parsed =
        DateTime.tryParse(rawValue);

    if (parsed == null) {
      return rawValue;
    }

    final local = parsed.toLocal();

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    final year =
        local.year.toString();

    var hour = local.hour;

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

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

  Future<void> openProfiles() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ProfilesScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadDashboard();
  }

  Future<void> openResults(
    String filter,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AllResultsScreen(
          initialFilter: filter,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadDashboard();
  }

  Future<void> openActivity(
    Map<String, dynamic> activity,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MatchDetailsScreen(
          result: activity,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadDashboard();
  }

  Future<void> continueScan() async {
    final task = nextTask;
    final profile = activeProfile;

    if (task == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'All scan tasks are complete.',
          ),
        ),
      );

      return;
    }

    if (profile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No active privacy profile is available.',
          ),
        ),
      );

      return;
    }

    final sourceKey =
        task['source_key']?.toString();

    final sourceName =
        task['source_name']?.toString() ??
            'Source';

    if (sourceKey == null ||
        sourceKey.isEmpty) {
      return;
    }

    final sourceTasks =
        tasksForSource(
      sourceKey,
    );

    final changed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SourceScanScreen(
          sourceName: sourceName,
          profile: profile,
          tasks: sourceTasks,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (activeProfileId != null) {
      await loadQueue(
        activeProfileId!,
      );
    }

    if (changed == true) {
      await loadDashboard();
    }
  }

  String activityTitle(
    Map<String, dynamic> activity,
  ) {
    final type =
        activity['activity_type']
                ?.toString() ??
            'found';

    if (type == 'removed') {
      return 'Removed';
    }

    if (type ==
        'removal_requested') {
      return 'Removal Requested';
    }

    return 'Exposure Found';
  }

  IconData activityIcon(
    Map<String, dynamic> activity,
  ) {
    final type =
        activity['activity_type']
                ?.toString() ??
            'found';

    if (type == 'removed') {
      return Icons.check_circle_outline;
    }

    if (type ==
        'removal_requested') {
      return Icons.schedule;
    }

    return Icons.warning_amber_rounded;
  }

  Color activityColor(
    Map<String, dynamic> activity,
  ) {
    final type =
        activity['activity_type']
                ?.toString() ??
            'found';

    if (type == 'removed') {
      return Colors.green;
    }

    if (type ==
        'removal_requested') {
      return Colors.orange;
    }

    return Theme.of(context)
        .colorScheme
        .error;
  }

  Widget buildScanProgressCard() {
    if (activeProfileId == null) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Scan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a privacy profile before starting a scan.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: openProfiles,
                icon: const Icon(
                  Icons.person_add,
                ),
                label: const Text(
                  'Create Profile',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (queueLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      );
    }

    final task = nextTask;

    final sourceName =
        task?['source_name']
                ?.toString() ??
            'Scan complete';

    final queryKind =
        task?['query_kind']
                ?.toString() ??
            '';

    final progressPercent =
        (queueProgress * 100)
            .clamp(0, 100)
            .round();

    int sourceRemaining = 0;

    if (task != null) {
      final sourceKey =
          task['source_key']
              ?.toString();

      if (sourceKey != null) {
        sourceRemaining =
            tasksForSource(
          sourceKey,
        ).where(
          isTaskUnfinished,
        ).length;
      }
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Privacy Scan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        activeProfileName ??
                            'Privacy Profile',
                      ),
                    ],
                  ),
                ),
                Text(
                  '$progressPercent%',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            LinearProgressIndicator(
              value: queueProgress,
              minHeight: 10,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              '$queueFinished of '
              '$queueTotal checks finished',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '$queuePending pending • '
              '$queueOpened opened • '
              '$queuePossibleMatches possible matches',
            ),

            const SizedBox(height: 18),

            if (task != null) ...[
              const Divider(),
              const SizedBox(height: 10),

              const Text(
                'Next Source',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                sourceName,
                style:
                    Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
              ),

              const SizedBox(height: 4),

              Text(
                '$sourceRemaining checks remaining for this source',
              ),

              const SizedBox(height: 4),

              Text(
                'Next: ${queryKind.replaceAll('_', ' ').toUpperCase()}',
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child:
                    FilledButton.icon(
                  onPressed:
                      continueScan,
                  icon: const Icon(
                    Icons.play_arrow,
                  ),
                  label: const Text(
                    'Continue Source',
                  ),
                ),
              ),
            ] else ...[
              const Divider(),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All saved scan tasks are complete.',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildRiskCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 34,
                  color: riskColor,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Privacy Risk',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment:
                    Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child:
                        CircularProgressIndicator(
                      value:
                          riskScore.clamp(
                                    0,
                                    100,
                                  ) /
                              100,
                      strokeWidth: 14,
                      strokeCap:
                          StrokeCap.round,
                      backgroundColor:
                          Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        riskColor,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        '$riskScore',
                        style:
                            Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontSize: 46,
                                  height: 1,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        'out of 100',
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color:
                    riskColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  50,
                ),
              ),
              child: Text(
                riskLabel,
                style: TextStyle(
                  color: riskColor,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard({
    required String label,
    required int value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 30,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$value',
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRecentActivity() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          8,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history,
                ),
                const SizedBox(width: 10),
                Text(
                  'Recent Activity',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (recentActivity.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 22,
                ),
                child: Center(
                  child: Text(
                    'No recent activity yet.',
                  ),
                ),
              )
            else
              ...recentActivity.map(
                (activity) {
                  final sourceName =
                      activity['source_name']
                              ?.toString() ??
                          'Unknown source';

                  final date =
                      activity['activity_date']
                          ?.toString();

                  final color =
                      activityColor(
                    activity,
                  );

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    onTap: () {
                      openActivity(
                        activity,
                      );
                    },
                    leading:
                        CircleAvatar(
                      backgroundColor:
                          color.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        activityIcon(
                          activity,
                        ),
                        color: color,
                      ),
                    ),
                    title: Text(
                      activityTitle(
                        activity,
                      ),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$sourceName\n'
                      '${formatDateTime(date)}',
                    ),
                    isThreeLine: true,
                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboard() {
    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          Text(
            'Privacy Dashboard',
            style:
                Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your current TraceLock privacy status.',
          ),
          const SizedBox(height: 24),

          buildScanProgressCard(),

          const SizedBox(height: 16),

          buildRiskCard(),

          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              buildStatCard(
                label: 'Profiles',
                value: profiles,
                icon:
                    Icons.people_outline,
                onTap: openProfiles,
              ),
              buildStatCard(
                label: 'Scan Results',
                value: scanResults,
                icon:
                    Icons.manage_search,
                onTap: () {
                  openResults('all');
                },
              ),
              buildStatCard(
                label: 'Possible Matches',
                value:
                    possibleMatches,
                icon:
                    Icons
                        .warning_amber_rounded,
                onTap: () {
                  openResults('found');
                },
              ),
              buildStatCard(
                label:
                    'Removal Requested',
                value:
                    removalRequested,
                icon: Icons.schedule,
                onTap: () {
                  openResults(
                    'removal_requested',
                  );
                },
              ),
              buildStatCard(
                label: 'Removed',
                value: removed,
                icon:
                    Icons
                        .check_circle_outline,
                onTap: () {
                  openResults(
                    'removed',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          Card(
            clipBehavior:
                Clip.antiAlias,
            child: ListTile(
              onTap: () {
                openResults('all');
              },
              leading:
                  const CircleAvatar(
                child: Icon(
                  Icons.schedule,
                ),
              ),
              title: const Text(
                'Latest Scan',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: Text(
                latestScan == null
                    ? 'No scans yet'
                    : formatDateTime(
                        latestScan,
                      ),
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
            ),
          ),

          const SizedBox(height: 16),

          buildRecentActivity(),

          const SizedBox(height: 16),

          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'TraceLock Protection',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your privacy monitoring system is active.',
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color:
                        Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TraceLock',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : loadDashboard,
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
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .cloud_off_outlined,
                          size: 56,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        const Text(
                          'Could not load dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        FilledButton.icon(
                          onPressed:
                              loadDashboard,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : buildDashboard(),
    );
  }
}
