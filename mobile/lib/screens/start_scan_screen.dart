import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'scan_results_screen.dart';

class StartScanScreen extends StatefulWidget {
  const StartScanScreen({
    super.key,
    this.profileId,
    this.profileName,
  });

  final String? profileId;
  final String? profileName;

  @override
  State<StartScanScreen> createState() => _StartScanScreenState();
}

class _StartScanScreenState extends State<StartScanScreen> {
  bool isLoading = false;
  String? message;

  double progress = 0.0;
  String progressLabel = 'Ready to scan';

  Future<void> runScan() async {
    final profileId = widget.profileId;

    if (profileId == null || profileId.isEmpty) {
      setState(() {
        message = 'No privacy profile selected.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
      progress = 0.1;
      progressLabel = 'Preparing privacy profile...';
    });

    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      setState(() {
        progress = 0.3;
        progressLabel = 'Connecting to scan sources...';
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      setState(() {
        progress = 0.5;
        progressLabel = 'Searching for exposed information...';
      });

      final result = await ApiService.startScan(
        profileId,
      );

      if (!mounted) return;

      setState(() {
        progress = 0.85;
        progressLabel = 'Processing matches...';
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      final matchesFound =
          result['matches_found'] ?? 0;

      final sitesScanned =
          result['sites_scanned'] ?? 0;

      setState(() {
        progress = 1.0;
        progressLabel = 'Scan complete';
        message =
            'Sites scanned: $sitesScanned\nMatches found: $matchesFound';
      });

      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultsScreen(
            profileId: profileId,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        progress = 0.0;
        progressLabel = 'Scan failed';
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

  Widget buildScanStatus() {
    if (!isLoading && progress == 0.0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 16),
            Text(
              progressLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile =
        widget.profileId != null &&
        widget.profileId!.isNotEmpty;

    final profileName =
        widget.profileName?.trim().isNotEmpty == true
            ? widget.profileName!
            : 'Privacy Profile';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Scan',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 72,
          ),

          const SizedBox(height: 24),

          Text(
            hasProfile
                ? 'Scan $profileName'
                : 'No Profile Selected',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          Text(
            hasProfile
                ? 'TraceLocked will search enabled sources for information connected to this profile.'
                : 'Go to Profiles and select the person you want to scan.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          if (hasProfile)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_search_outlined,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profileName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ready for privacy scan',
                    ),
                  ],
                ),
              ),
            ),

          if (!hasProfile)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 44,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No profile selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Open Profiles and tap a profile first.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          buildScanStatus(),

          if (message != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (hasProfile)
            FilledButton.icon(
              onPressed:
                  isLoading ? null : runScan,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.manage_search,
                    ),
              label: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  isLoading
                      ? 'Scanning...'
                      : 'Start Privacy Scan',
                ),
              ),
            ),
        ],
      ),
    );
  }
}