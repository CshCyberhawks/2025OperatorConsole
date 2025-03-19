import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateChecker {
  // Current app version - update this when releasing a new version
  static const String currentVersion = '0.1.3';

  // GitHub repository information
  static const String owner = 'CshCyberhawks';
  static const String repo = '2025OperatorConsole';
  static const String githubReleaseUrl =
      'https://github.com/$owner/$repo/releases/latest';

  // API endpoint to check for latest release
  static const String apiUrl =
      'https://api.github.com/repos/$owner/$repo/releases/latest';

  // Key for storing the "don't show again" preference
  static const String _prefKeyDontShowAgain = 'dontShowUpdateForVersion';

  // Check for updates and show a dialog if a new version is available
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final latestVersion = await _getLatestVersion();

      if (latestVersion != null && latestVersion != currentVersion) {
        // Check if user chose not to be notified about this version
        final prefs = await SharedPreferences.getInstance();
        final dontShowVersion = prefs.getString(_prefKeyDontShowAgain);

        if (dontShowVersion != latestVersion) {
          // Show update dialog
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  // Get the latest version from GitHub API
  static Future<String?> _getLatestVersion() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String;

        // Remove 'v' prefix if present (e.g., 'v1.0.0' -> '1.0.0')
        return tagName.startsWith('v') ? tagName.substring(1) : tagName;
      }
    } catch (e) {
      debugPrint('Error fetching latest version: $e');
    }

    return null;
  }

  // Show update dialog
  static void _showUpdateDialog(BuildContext context, String newVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'A new version ($newVersion) is available. You are currently using version $currentVersion.\n\n'
          'Would you like to update now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dontShowAgainForVersion(newVersion);
            },
            child: const Text('Don\'t Show Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl(githubReleaseUrl);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  // Launch URL to GitHub releases page
  static Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  // Save preference to not show update dialog for this version
  static Future<void> _dontShowAgainForVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDontShowAgain, version);
  }
}
