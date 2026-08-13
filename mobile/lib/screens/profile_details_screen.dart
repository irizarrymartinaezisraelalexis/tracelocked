import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'start_scan_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({
    super.key,
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  State<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState
    extends State<ProfileDetailsScreen> {
  late Map<String, dynamic> profile;

  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    profile = Map<String, dynamic>.from(
      widget.profile,
    );
  }

  String get profileId {
    return profile['profile_id']?.toString() ?? '';
  }

  String get firstName {
    return profile['first_name']?.toString() ?? '';
  }

  String get lastName {
    return profile['last_name']?.toString() ?? '';
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();

    if (name.isEmpty) {
      return 'Privacy Profile';
    }

    return name;
  }

  String get email {
    final emails =
        profile['email_addresses'] as List<dynamic>? ??
            [];

    if (emails.isEmpty) {
      return 'Not provided';
    }

    return emails.first.toString();
  }

  String get phone {
    final phones =
        profile['phone_numbers'] as List<dynamic>? ??
            [];

    if (phones.isEmpty) {
      return 'Not provided';
    }

    return phones.first.toString();
  }

  Map<String, dynamic> get address {
    return profile['current_address']
            as Map<String, dynamic>? ??
        {};
  }

  String get street {
    return address['street']?.toString() ??
        'Not provided';
  }

  String get city {
    return address['city']?.toString() ??
        'Not provided';
  }

  String get state {
    return address['state']?.toString() ??
        'Not provided';
  }

  String get postalCode {
    return address['postal_code']
            ?.toString() ??
        'Not provided';
  }

  String get dateOfBirth {
    final raw =
        profile['date_of_birth']?.toString();

    if (raw == null || raw.isEmpty) {
      return 'Not provided';
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    final month =
        parsed.month.toString().padLeft(2, '0');

    final day =
        parsed.day.toString().padLeft(2, '0');

    final year =
        parsed.year.toString().padLeft(4, '0');

    return '$month/$day/$year';
  }

  Future<void> editProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
        ),
      ),
    );

    if (changed != true || !mounted) {
      return;
    }

    try {
      final profiles =
          await ApiService.getProfiles();

      final updatedProfile =
          profiles
              .map(
                (item) => item
                    as Map<String, dynamic>,
              )
              .where(
                (item) =>
                    item['profile_id']
                        ?.toString() ==
                    profileId,
              )
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (item) => item != null,
                orElse: () => null,
              );

      if (!mounted) {
        return;
      }

      if (updatedProfile != null) {
        setState(() {
          profile =
              Map<String, dynamic>.from(
            updatedProfile,
          );
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    }
  }

  void runScan() {
    if (profileId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This profile does not have a valid ID.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartScanScreen(
          profileId: profileId,
          profileName: fullName,
        ),
      ),
    );
  }

  Future<void> confirmDelete() async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Profile?',
          ),
          content: Text(
            'Are you sure you want to delete $fullName?',
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
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .error,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await deleteProfile();
  }

  Future<void> deleteProfile() async {
    if (profileId.isEmpty) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      await ApiService.deleteProfile(
        profileId,
      );

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
            'Could not delete profile: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  Widget detailCard({
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Details',
        ),
        actions: [
          IconButton(
            onPressed:
                isDeleting
                    ? null
                    : editProfile,
            tooltip: 'Edit Profile',
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          CircleAvatar(
            radius: 46,
            child: Text(
              firstName.isNotEmpty
                  ? firstName[0]
                      .toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 34,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            fullName,
            textAlign: TextAlign.center,
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
            email,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          detailCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),

          detailCard(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: phone,
          ),

          detailCard(
            icon: Icons.home_outlined,
            label: 'Street Address',
            value: street,
          ),

          detailCard(
            icon: Icons.location_city,
            label: 'City',
            value: city,
          ),

          detailCard(
            icon: Icons.map_outlined,
            label: 'State',
            value: state,
          ),

          detailCard(
            icon:
                Icons.local_post_office_outlined,
            label: 'Postal Code',
            value: postalCode,
          ),

          detailCard(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: dateOfBirth,
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed:
                isDeleting
                    ? null
                    : runScan,
            icon: const Icon(
              Icons.manage_search,
            ),
            label: const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                'Run Privacy Scan',
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed:
                isDeleting
                    ? null
                    : editProfile,
            icon: const Icon(
              Icons.edit_outlined,
            ),
            label: const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                'Edit Profile',
              ),
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed:
                isDeleting
                    ? null
                    : confirmDelete,
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .error,
            ),
            icon: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline,
                  ),
            label: Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                isDeleting
                    ? 'Deleting...'
                    : 'Delete Profile',
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}