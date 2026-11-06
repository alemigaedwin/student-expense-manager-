import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String currentVersion = '1.0.0';
  static const String githubOwner = 'alemigaedwin';
  static const String githubRepo = 'student-expense-manager-';

  static const String defaultApkUrl =
      'https://github.com/$githubOwner/$githubRepo/releases/latest/download/app-release.apk';

  static bool _hasPromptedThisSession = false;

  /// Compares semantic versioning (e.g. 1.0.1 vs 1.0.0)
  static bool isRemoteNewer(String remoteTag, String localVer) {
    String cleanRemote = remoteTag.trim().toLowerCase();
    if (cleanRemote.startsWith('v')) cleanRemote = cleanRemote.substring(1);

    String cleanLocal = localVer.trim().toLowerCase();
    if (cleanLocal.startsWith('v')) cleanLocal = cleanLocal.substring(1);

    // Remove build numbers e.g. +1
    cleanRemote = cleanRemote.split('+').first;
    cleanLocal = cleanLocal.split('+').first;

    final remoteParts = cleanRemote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final localParts = cleanLocal.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final l = i < localParts.length ? localParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  /// Checks GitHub Releases API for the latest release
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name']?.toString() ?? '';
        final name = data['name']?.toString() ?? 'New Release';
        final body = data['body']?.toString() ?? 'Bug fixes and performance improvements.';

        // Look for APK in assets
        String apkUrl = defaultApkUrl;
        final assets = data['assets'] as List?;
        if (assets != null) {
          for (final asset in assets) {
            final downloadUrl = asset['browser_download_url']?.toString() ?? '';
            if (downloadUrl.toLowerCase().endsWith('.apk')) {
              apkUrl = downloadUrl;
              break;
            }
          }
        }

        final hasUpdate = isRemoteNewer(tagName, currentVersion);
        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: tagName.isNotEmpty ? tagName : currentVersion,
          releaseName: name,
          releaseNotes: body,
          downloadUrl: apkUrl,
        );
      }
    } catch (_) {
      // Network error or offline
    }

    return UpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      releaseName: '',
      releaseNotes: '',
      downloadUrl: defaultApkUrl,
    );
  }

  /// Automatically check when the app launches (quietly)
  static Future<void> checkOnStartup(BuildContext context) async {
    if (_hasPromptedThisSession) return;
    _hasPromptedThisSession = true;

    final info = await checkForUpdate();
    if (info.hasUpdate && context.mounted) {
      showUpdateDialog(context, info);
    }
  }

  /// Manually check from Settings screen
  static Future<void> manualCheck(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Checking GitHub for updates...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final info = await checkForUpdate();
    if (!context.mounted) return;

    if (info.hasUpdate) {
      showUpdateDialog(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are on the latest version (v$currentVersion)!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  /// Displays the interactive update dialog
  static void showUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_alt, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Available!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.new_releases_outlined, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    '${info.latestVersion} available (Installed: v${info.currentVersion})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "What's New in this GitHub Release:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info.releaseNotes.isNotEmpty
                        ? info.releaseNotes
                        : 'New improvements, bug fixes, and offline performance updates.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tapping "Update Now" downloads the APK directly from GitHub and prompts your phone to install it.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(info.downloadUrl);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open download: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
