import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import 'scan_webview_screen.dart';
import 'scan_windows_webview_screen.dart';

class ScanTaskScreen extends StatefulWidget {
  const ScanTaskScreen({super.key, required this.task, required this.profile});

  final Map<String, dynamic> task;
  final Map<String, dynamic> profile;

  @override
  State<ScanTaskScreen> createState() => _ScanTaskScreenState();
}

class _ScanTaskScreenState extends State<ScanTaskScreen> {
  bool isUpdating = false;

  String get taskId => widget.task['id']?.toString() ?? '';

  String get sourceKey => widget.task['source_key']?.toString() ?? '';

  String get sourceName =>
      widget.task['source_name']?.toString() ?? 'Unknown Source';

  String get sourceUrl => widget.task['source_url']?.toString() ?? '';

  String get queryKind => widget.task['query_kind']?.toString() ?? '';

  String get queryValue => widget.task['query_value']?.toString() ?? '';

  String get executionMode =>
      widget.task['mode']?.toString() ?? 'external_browser';

  String get taskStatus => widget.task['status']?.toString() ?? 'unknown';

  String get firstName => widget.profile['first_name']?.toString() ?? '';

  String get lastName => widget.profile['last_name']?.toString() ?? '';

  String get fullName => '$firstName $lastName'.trim();

  List<dynamic> get emails =>
      widget.profile['email_addresses'] as List<dynamic>? ?? [];

  List<dynamic> get phones =>
      widget.profile['phone_numbers'] as List<dynamic>? ?? [];

  Map<String, dynamic> get address {
    final raw = widget.profile['current_address'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  String get email {
    if (emails.isEmpty) {
      return '';
    }

    return emails.first.toString();
  }

  String get phone {
    if (phones.isEmpty) {
      return '';
    }

    return phones.first.toString();
  }

  String get street => address['street']?.toString() ?? '';

  String get city => address['city']?.toString() ?? '';

  String get state => address['state']?.toString() ?? '';

  String get postalCode => address['postal_code']?.toString() ?? '';

  String get fullAddress {
    return [
      street,
      city,
      state,
      postalCode,
    ].where((value) => value.trim().isNotEmpty).join(', ');
  }

  bool get isAndroid {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android;
  }

  bool get isWindows {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get shouldUseEmbeddedWebView {
    return (isAndroid || isWindows) && executionMode == 'embedded_webview';
  }

  bool get shouldUseExternalBrowser {
    return !shouldUseEmbeddedWebView;
  }

  String get currentSearchValue {
    switch (queryKind) {
      case 'phone':
        return phone.isNotEmpty ? phone : queryValue;

      case 'email':
        return email.isNotEmpty ? email : queryValue;

      case 'address':
      case 'previous_address':
        return fullAddress.isNotEmpty ? fullAddress : queryValue;

      case 'name_city':
      case 'name_location':
      case 'name_address':
        return [
          fullName,
          city,
          state,
          postalCode,
        ].where((value) => value.trim().isNotEmpty).join(', ');

      case 'name':
        return fullName.isNotEmpty ? fullName : queryValue;

      default:
        return queryValue;
    }
  }

  String get currentSearchLabel {
    switch (queryKind) {
      case 'phone':
        return 'Phone';

      case 'email':
        return 'Email';

      case 'address':
      case 'previous_address':
        return 'Address';

      case 'name':
      case 'name_city':
      case 'name_location':
      case 'name_address':
        return 'Name / Location';

      default:
        return 'Search value';
    }
  }

  Future<void> copyValue(String label, String value) async {
    if (value.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> openSource() async {
    if (sourceUrl.isEmpty) {
      return;
    }

    if (taskId.isNotEmpty) {
      try {
        await ApiService.updateScanTask(taskId: taskId, status: 'opened');
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    if (shouldUseEmbeddedWebView) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            if (isWindows) {
              return ScanWindowsWebViewScreen(
                sourceName: sourceName,
                sourceUrl: sourceUrl,
                queryKind: queryKind,
                profile: widget.profile,
              );
            }

            return ScanWebViewScreen(
              sourceName: sourceName,
              sourceUrl: sourceUrl,
              queryKind: queryKind,
              profile: widget.profile,
            );
          },
        ),
      );

      return;
    }

    final value = currentSearchValue;

    if (value.trim().isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: value));
    }

    if (!mounted) {
      return;
    }

    final uri = Uri.tryParse(sourceUrl);

    if (uri == null) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) {
      return;
    }

    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$currentSearchLabel copied. '
            'Paste it into $sourceName.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the source.')),
      );
    }
  }

  Future<void> markNoMatch() async {
    if (taskId.isEmpty || isUpdating) {
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      await ApiService.updateScanTask(taskId: taskId, status: 'no_match');

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> markPossibleMatch() async {
    if (taskId.isEmpty || isUpdating) {
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      await ApiService.updateScanTask(taskId: taskId, status: 'possible_match');

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Widget buildField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: SelectableText(value),
        trailing: IconButton(
          tooltip: 'Copy $label',
          onPressed: () {
            copyValue(label, value);
          },
          icon: const Icon(Icons.copy),
        ),
      ),
    );
  }

  List<Widget> buildRelevantFields() {
    switch (queryKind) {
      case 'phone':
        return [
          buildField(
            label: 'Phone',
            value: currentSearchValue,
            icon: Icons.phone_outlined,
          ),
        ];

      case 'email':
        return [
          buildField(
            label: 'Email',
            value: currentSearchValue,
            icon: Icons.email_outlined,
          ),
        ];

      case 'address':
      case 'previous_address':
        return [
          buildField(
            label: 'Address',
            value: currentSearchValue,
            icon: Icons.home_outlined,
          ),
        ];

      default:
        return [
          buildField(
            label: currentSearchLabel,
            value: currentSearchValue,
            icon: Icons.person_search_outlined,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final readableQuery = queryKind.replaceAll('_', ' ').toUpperCase();

    final browserButtonLabel = shouldUseEmbeddedWebView
        ? 'Open $sourceName in TraceLock'
        : 'Copy & Open $sourceName';

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Check')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sourceName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search type: '
                    '$readableQuery',
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Execution mode: '
                          '$executionMode',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Platform: '
                          '${kIsWeb ? 'web' : defaultTargetPlatform.name}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source key: '
                          '$sourceKey',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Task status: '
                          '$taskStatus',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    shouldUseEmbeddedWebView
                        ? 'TraceLock will attempt to fill this search inside the app.'
                        : 'TraceLock will copy the required value before opening the browser.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Current Search',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...buildRelevantFields(),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: openSource,
              icon: Icon(shouldUseEmbeddedWebView ? Icons.web : Icons.copy_all),
              label: Text(browserButtonLabel),
            ),
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 12),

          Text(
            'After searching',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: isUpdating ? null : markPossibleMatch,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Possible Match Found'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUpdating ? null : markNoMatch,
              icon: const Icon(Icons.search_off),
              label: const Text('No Match Found'),
            ),
          ),
        ],
      ),
    );
  }
}
