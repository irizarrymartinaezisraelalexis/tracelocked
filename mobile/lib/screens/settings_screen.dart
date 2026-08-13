import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.darkModeEnabled,
    required this.onDarkModeChanged,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onDarkModeChanged;

  Future<void> logout(BuildContext context) async {
    AuthService.clearToken();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),

          const CircleAvatar(
            radius: 42,
            child: Icon(
              Icons.person,
              size: 42,
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'TraceLocked User',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          const SizedBox(height: 28),

          Card(
            child: SwitchListTile(
              secondary: Icon(
                darkModeEnabled
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: const Text(
                'Dark Mode',
              ),
              subtitle: Text(
                darkModeEnabled
                    ? 'Dark appearance enabled'
                    : 'Light appearance enabled',
              ),
              value: darkModeEnabled,
              onChanged: onDarkModeChanged,
            ),
          ),

          const SizedBox(height: 12),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.verified_user_outlined,
              ),
              title: Text(
                'Privacy Protection',
              ),
              subtitle: Text(
                'Enabled',
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.security,
              ),
              title: Text(
                'Account Security',
              ),
              subtitle: Text(
                'JWT authenticated',
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
              ),
              title: Text(
                'Version',
              ),
              subtitle: Text(
                '1.0.0',
              ),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(
              Icons.logout,
            ),
            label: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                'Logout',
              ),
            ),
          ),
        ],
      ),
    );
  }
}