import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

const _consentKey = 'nightnest_consent_v1';
const _usernameKey = 'nightnest_username_v1';
// Local file paths (from attachments). On desktop these will open directly; on web they may fail.
const _eulaLocalPath =
    r'd:\Night_Nest\night_nest_new\Night Nest docs\PDF\EULA 2025.pdf';
const _termsLocalPath =
    r'd:\Night_Nest\night_nest_new\Night Nest docs\PDF\Terms Of Service 2025.pdf';
const _privacyLocalPath =
    r'd:\Night_Nest\night_nest_new\Night Nest docs\PDF\Privacy Policy 2025.pdf';

// asset paths (embedded into app). If you put the real PDFs into assets/docs/ with
// these exact names they will be opened in-app or in a new browser tab on web.
const _eulaAsset = 'assets/docs/EULA 2025.pdf';
const _termsAsset = 'assets/docs/Terms Of Service 2025.pdf';
const _privacyAsset = 'assets/docs/Privacy Policy 2025.pdf';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _acceptedEula = false;
  bool _acceptedPrivacy = false;
  bool _acknowledgedDisclaimer = false;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_acceptedEula && _acceptedPrivacy && _acknowledgedDisclaimer) {
      _saveConsentAndContinue();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept all items to continue')),
      );
    }
  }

  Future<void> _saveConsentAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      await prefs.setString(_usernameKey, username);
    } else {
      // If user didn't provide a username, ensure none is stored
      await prefs.remove(_usernameKey);
    }
    await prefs.setBool(_consentKey, true);
    // Navigate directly to main screen
    if (mounted) Navigator.pushReplacementNamed(context, '/main');
  }

  Future<void> _continueAnonymously() async {
    // Mark consent as given and continue
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    // Remove any stored username when continuing anonymously
    await prefs.remove(_usernameKey);
    // Navigate directly to main screen
    if (mounted) Navigator.pushReplacementNamed(context, '/main');
  }

  Future<void> _openLocalDocument(BuildContext context, String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {
      // fallthrough to fallback
    }

    // If the state is no longer mounted, abort showing UI
    if (!mounted) return;

    // Fallback: show a dialog on the next frame with the path and allow copying it to clipboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Open document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could not open the file automatically.'),
              const SizedBox(height: 8),
              SelectableText(path),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: path));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard')),
                );
              },
              child: const Text('Copy path'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openAssetOrLocal(
    BuildContext context,
    String assetPath,
    String localPath,
  ) async {
    try {
      // Resolve the asset URL relative to the app base (works on web and mobile/desktop served via http)
      final assetUri = Uri.base.resolve(assetPath);
      if (await canLaunchUrl(assetUri)) {
        await launchUrl(assetUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // fallthrough to local/open fallback
    }

    // If embedded asset couldn't be opened, try the original local file path (desktop case)
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    await _openLocalDocument(context, localPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consent & Terms')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disclaimer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Night Nest is an emotional support tool designed to help you reflect and track feelings. It is not a medical device and does not provide medical diagnoses, treatment, or professional therapy. If you are in crisis or need medical or psychiatric assistance, please seek immediate help from a qualified professional or emergency services.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Please review and accept the following to continue:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _acceptedEula,
              onChanged: (v) => setState(() => _acceptedEula = v ?? false),
              title: const Text(
                'I agree to the End User License Agreement (EULA)',
              ),
            ),
            CheckboxListTile(
              value: _acceptedPrivacy,
              onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
              title: const Text('I have read and accept the Privacy Policy'),
            ),
            CheckboxListTile(
              value: _acknowledgedDisclaimer,
              onChanged: (v) =>
                  setState(() => _acknowledgedDisclaimer = v ?? false),
              title: const Text(
                'I acknowledge Night Nest is not a diagnostic tool',
              ),
            ),
            const SizedBox(height: 12),
            // Optional username input for sign-in/display
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Choose a username (optional)',
                hintText: 'This name will be shown to others',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _continueAnonymously,
                    child: const Text('Continue anonymously'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  // Show EULA / Privacy details with direct-open buttons for attached PDFs
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('EULA & Terms of Service'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'You can open the local copies of the EULA and Terms supplied with the app.',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                await _openAssetOrLocal(
                                  context,
                                  _eulaAsset,
                                  _eulaLocalPath,
                                );
                              },
                              child: const Text('Open embedded EULA'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await _openAssetOrLocal(
                                  context,
                                  _termsAsset,
                                  _termsLocalPath,
                                );
                              },
                              child: const Text(
                                'Open embedded Terms of Service',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await _openAssetOrLocal(
                                  context,
                                  _privacyAsset,
                                  _privacyLocalPath,
                                );
                              },
                              child: const Text('Open embedded Privacy Policy'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'If opening fails (for example on web), copy the file path below and open it manually on your machine:',
                            ),
                            const SizedBox(height: 8),
                            SelectableText('asset: $_eulaAsset'),
                            const SizedBox(height: 6),
                            SelectableText('asset: $_termsAsset'),
                            const SizedBox(height: 6),
                            SelectableText('asset: $_privacyAsset'),
                            const SizedBox(height: 12),
                            const Text('Local source paths (if available):'),
                            const SizedBox(height: 8),
                            SelectableText(_eulaLocalPath),
                            const SizedBox(height: 6),
                            SelectableText(_termsLocalPath),
                            const SizedBox(height: 6),
                            SelectableText(_privacyLocalPath),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('View EULA / Privacy Policy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
