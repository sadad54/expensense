import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exp_ocr/viewmodels/theme_viewmodel.dart'; // optional, for dark mode
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exp_ocr/views/edit_profile_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
  }

  Future<void> _fetchAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/'); // update as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileCard(),

          const SizedBox(height: 24),
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: themeProvider?.isDarkMode ?? false,
            onChanged: (val) => themeProvider?.toggleTheme(),
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
          ),

          const SizedBox(height: 24),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() => notificationsEnabled = val);
              // Save preference (e.g. shared_preferences)
            },
            title: const Text('Enable Notifications'),
            secondary: const Icon(Icons.notifications_active),
          ),

          const SizedBox(height: 24),
          const Text(
            'Data & Storage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTile(
            Icons.backup,
            'Backup to Cloud',
            onTap: () {
              // Trigger backup function
            },
          ),
          _buildTile(
            Icons.restore,
            'Restore from Backup',
            onTap: () {
              // Trigger restore function
            },
          ),
          _buildTile(
            Icons.delete_forever,
            'Clear App Cache',
            onTap: () {
              // Clear local data
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTile(Icons.info, 'App Version: $_appVersion'),
          _buildTile(
            Icons.help_outline,
            'Help & Support',
            onTap: () {
              // open support link or contact screen
            },
          ),
          _buildTile(
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            onTap: () {
              // open privacy policy URL
            },
          ),
          _buildTile(
            Icons.gavel,
            'Terms of Use',
            onTap: () {
              // open terms URL
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildTile(
            Icons.logout,
            'Log Out',
            color: Colors.redAccent,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox(); // Or prompt to log in
    }

    final displayName = user.displayName ?? "User";
    final email = user.email ?? "No email";
    final avatarText =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              child: Text(
                avatarText,
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // Navigate to edit profile page or open modal
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
