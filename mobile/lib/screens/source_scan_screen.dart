import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'scan_task_screen.dart';

class SourceScanScreen extends StatefulWidget {
  const SourceScanScreen({
    super.key,
    required this.sourceName,
    required this.profile,
    required this.tasks,
  });

  final String sourceName;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> tasks;

  @override
  State<SourceScanScreen> createState() =>
      _SourceScanScreenState();
}

class _SourceScanScreenState extends State<SourceScanScreen> {
  bool isUpdating = false;

  List<Map<String, dynamic>> get unfinishedTasks {
    return widget.tasks.where(
      (task) {
        final status =
            task['status']?.toString() ?? 'pending';

        return status != 'no_match' &&
            status != 'completed' &&
            status != 'failed';
      },
    ).toList();
  }

  int get totalTasks => widget.tasks.length;

  int get finishedTasks {
    return widget.tasks.where(
      (task) {
        final status =
            task['status']?.toString() ?? 'pending';

        return status == 'no_match' ||
            status == 'completed' ||
            status == 'failed';
      },
    ).length;
  }

  Map<String, dynamic>? get nextTask {
    final unfinished = unfinishedTasks;

    if (unfinished.isEmpty) {
      return null;
    }

    return unfinished.first;
  }

  String readableKind(
    Map<String, dynamic> task,
  ) {
    final kind =
        task['query_kind']?.toString() ?? '';

    return kind
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  IconData taskIcon(
    Map<String, dynamic> task,
  ) {
    switch (
        task['query_kind']?.toString()) {
      case 'phone':
        return Icons.phone_outlined;

      case 'email':
        return Icons.email_outlined;

      case 'address':
      case 'previous_address':
        return Icons.home_outlined;

      default:
        return Icons.person_search_outlined;
    }
  }

  Color statusColor(
    String status,
  ) {
    switch (status) {
      case 'no_match':
      case 'completed':
        return Colors.green;

      case 'possible_match':
      case 'removal_ready':
      case 'removal_requested':
        return Colors.orange;

      case 'failed':
        return Colors.red;

      case 'opened':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  String readableStatus(
    String status,
  ) {
    return status
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  Future<void> openNextTask() async {
    final task = nextTask;

    if (task == null) {
      return;
    }

    final changed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanTaskScreen(
          task: task,
          profile: widget.profile,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  Future<void> openTask(
    Map<String, dynamic> task,
  ) async {
    final changed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanTaskScreen(
          task: task,
          profile: widget.profile,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  Future<void> markRemainingNoMatch()
      async {
    if (isUpdating) {
      return;
    }

    final pendingTasks =
        widget.tasks.where(
      (task) {
        final status =
            task['status']?.toString() ??
                'pending';

        return status == 'pending' ||
            status == 'opened';
      },
    ).toList();

    if (pendingTasks.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Mark remaining checks?',
          ),
          content: Text(
            'This will mark ${pendingTasks.length} '
            'remaining ${widget.sourceName} '
            'checks as No Match.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
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
                  context,
                  true,
                );
              },
              child: const Text(
                'Mark No Match',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      for (final task in pendingTasks) {
        final taskId =
            task['id']?.toString();

        if (taskId == null ||
            taskId.isEmpty) {
          continue;
        }

        await ApiService.updateScanTask(
          taskId: taskId,
          status: 'no_match',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final remaining =
        totalTasks - finishedTasks;

    final progress =
        totalTasks == 0
            ? 0.0
            : finishedTasks / totalTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sourceName,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.sourceName} Session',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    '$finishedTasks of '
                    '$totalTasks checks finished',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    '$remaining remaining',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          if (nextTask != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    isUpdating
                        ? null
                        : openNextTask,
                icon: const Icon(
                  Icons.play_arrow,
                ),
                label: const Text(
                  'Continue This Source',
                ),
              ),
            ),

          const SizedBox(
            height: 18,
          ),

          Text(
            'Checks',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(
            height: 10,
          ),

          ...widget.tasks.map(
            (task) {
              final status =
                  task['status']
                          ?.toString() ??
                      'pending';

              final value =
                  task['query_value']
                          ?.toString() ??
                      '';

              return Card(
                child: ListTile(
                  onTap: () {
                    openTask(
                      task,
                    );
                  },
                  leading: Icon(
                    taskIcon(
                      task,
                    ),
                  ),
                  title: Text(
                    readableKind(
                      task,
                    ),
                  ),
                  subtitle: Text(
                    value,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                  trailing: Chip(
                    label: Text(
                      readableStatus(
                        status,
                      ),
                    ),
                    backgroundColor:
                        statusColor(
                      status,
                    ).withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 18,
          ),

          if (remaining > 0)
            OutlinedButton.icon(
              onPressed:
                  isUpdating
                      ? null
                      : markRemainingNoMatch,
              icon: const Icon(
                Icons.search_off,
              ),
              label: const Text(
                'Mark Remaining Checks No Match',
              ),
            ),
        ],
      ),
    );
  }
}
