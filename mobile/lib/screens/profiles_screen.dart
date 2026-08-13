import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'create_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_details_screen.dart';
import 'start_scan_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> profiles = [];

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getProfiles();

      if (!mounted) return;

      setState(() {
        profiles = data;
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

  Future<void> openCreateProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateProfileScreen(),
      ),
    );

    if (!mounted) return;

    await loadProfiles();
  }

  Future<void> openProfileDetails(
    Map<String, dynamic> profile,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailsScreen(
          profile: profile,
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await loadProfiles();
    }
  }

  Future<void> openEditProfile(
    Map<String, dynamic> profile,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );
    }
  }

  void openProfileScan(
    Map<String, dynamic> profile,
  ) {
    final profileId =
        profile['profile_id']?.toString();

    if (profileId == null || profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This profile does not have a valid ID.',
          ),
        ),
      );
      return;
    }

    final firstName =
        profile['first_name']?.toString() ?? '';

    final lastName =
        profile['last_name']?.toString() ?? '';

    final profileName =
        '$firstName $lastName'.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartScanScreen(
          profileId: profileId,
          profileName: profileName,
        ),
      ),
    );
  }

  Future<void> confirmDeleteProfile(
    Map<String, dynamic> profile,
  ) async {
    final profileId =
        profile['profile_id']?.toString();

    final firstName =
        profile['first_name']?.toString() ?? '';

    final lastName =
        profile['last_name']?.toString() ?? '';

    final profileName =
        '$firstName $lastName'.trim();

    if (profileId == null || profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This profile does not have a valid ID.',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Profile?'),
          content: Text(
            profileName.isEmpty
                ? 'Are you sure you want to delete this profile?'
                : 'Are you sure you want to delete $profileName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await deleteProfile(
      profileId,
      profileName,
    );
  }

  Future<void> deleteProfile(
    String profileId,
    String profileName,
  ) async {
    try {
      await ApiService.deleteProfile(profileId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileName.isEmpty
                ? 'Profile deleted.'
                : '$profileName deleted.',
          ),
        ),
      );

      await loadProfiles();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete profile: $error',
          ),
        ),
      );
    }
  }

  Widget buildProfileCard(
    Map<String, dynamic> profile,
  ) {
    final firstName =
        profile['first_name']?.toString() ?? '';

    final lastName =
        profile['last_name']?.toString() ?? '';

    final profileName =
        '$firstName $lastName'.trim();

    final emails =
        profile['email_addresses'] as List<dynamic>? ??
            [];

    final phones =
        profile['phone_numbers'] as List<dynamic>? ??
            [];

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            firstName.isNotEmpty
                ? firstName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(
          profileName.isEmpty
              ? 'Privacy Profile'
              : profileName,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emails.isNotEmpty)
              Text(
                emails.first.toString(),
              ),
            if (phones.isNotEmpty)
              Text(
                phones.first.toString(),
              ),
          ],
        ),
        onTap: () {
          openProfileDetails(profile);
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'details') {
              openProfileDetails(profile);
            }

            if (value == 'scan') {
              openProfileScan(profile);
            }

            if (value == 'edit') {
              openEditProfile(profile);
            }

            if (value == 'delete') {
              confirmDeleteProfile(profile);
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem<String>(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 12),
                    Text('Run Scan'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 12),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Delete Profile'),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Profiles',
        ),
        actions: [
          IconButton(
            onPressed: loadProfiles,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadProfiles,
                          child: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : profiles.isEmpty
                  ? const Center(
                      child: Text(
                        'No privacy profiles yet.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadProfiles,
                      child: ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 90,
                        ),
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final profile =
                              profiles[index]
                                  as Map<String, dynamic>;

                          return buildProfileCard(
                            profile,
                          );
                        },
                      ),
                    ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: openCreateProfile,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'New Profile',
        ),
      ),
    );
  }
}