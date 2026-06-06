import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_settings_state.dart';
import '../../core/auth_service.dart';
import '../../core/auth_state.dart';
import '../../core/runtime_config.dart';
import '../../shared/carp_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CarpCraftAuthService _authService = CarpCraftAuthService();
  final TextEditingController _apiBaseUrlController = TextEditingController();
  bool _signingIn = false;
  bool _requestingLocation = false;
  bool _testingConnection = false;
  bool _savingApiBaseUrl = false;
  String? _connectionResult;
  bool _connectionOk = false;

  @override
  void initState() {
    super.initState();
    _apiBaseUrlController.text = RuntimeConfig.instance.effectiveBaseUrl;
  }

  @override
  void dispose() {
    _apiBaseUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveApiBaseUrl() async {
    setState(() {
      _savingApiBaseUrl = true;
    });
    final value = _apiBaseUrlController.text.trim();
    await RuntimeConfig.instance.setApiBaseUrl(value.isEmpty ? null : value);
    if (!mounted) {
      return;
    }
    _apiBaseUrlController.text = RuntimeConfig.instance.effectiveBaseUrl;
    setState(() {
      _savingApiBaseUrl = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Backend set to ${RuntimeConfig.instance.effectiveBaseUrl}')),
    );
  }

  Future<void> _testConnection() async {
    final url = _apiBaseUrlController.text.trim().isEmpty
        ? RuntimeConfig.instance.effectiveBaseUrl
        : _apiBaseUrlController.text.trim();
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });
    var ok = false;
    String message;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final request = await client
          .getUrl(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(const Duration(seconds: 8));
      await response.drain<void>();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ok = true;
        message = 'Connected to $base (HTTP ${response.statusCode}).';
      } else {
        message = 'Reachable but returned HTTP ${response.statusCode} from $base.';
      }
    } on TimeoutException {
      message = 'Timed out reaching $url. Check the URL and that the backend is running.';
    } on SocketException catch (error) {
      message = 'Could not connect to $url: ${error.message}.';
    } catch (error) {
      message = 'Connection test failed: $error';
    } finally {
      client.close(force: true);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _testingConnection = false;
      _connectionOk = ok;
      _connectionResult = message;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
    });
    try {
      await _authService.signIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microsoft sign-in opened.')),
        );
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
        });
      }
    }
  }

  Future<void> _setPreciseLocation(bool enabled) async {
    if (!enabled) {
      AppSettingsState.instance.setPreciseLocationEnabled(false);
      setState(() {});
      return;
    }
    setState(() {
      _requestingLocation = true;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      final allowed = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      AppSettingsState.instance.setPreciseLocationEnabled(allowed);
      if (!allowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permission was not granted.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _requestingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthState.instance.isSignedIn;
    final settings = AppSettingsState.instance;
    return CarpScaffold(
      title: 'Settings',
      children: [
        SectionCard(
          title: 'Backend connection',
          icon: Icons.cloud_outlined,
          children: [
            const Text(
                'Point the app at your CarpCraft backend. Weather, venues and '
                'recommendations need a reachable API.'),
            const SizedBox(height: 12),
            TextField(
              controller: _apiBaseUrlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'API base URL',
                hintText: 'https://your-backend.example.com',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _savingApiBaseUrl ? null : _saveApiBaseUrl,
                  icon: _savingApiBaseUrl
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
                OutlinedButton.icon(
                  onPressed: _testingConnection ? null : _testConnection,
                  icon: _testingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering_outlined),
                  label: const Text('Test connection'),
                ),
              ],
            ),
            _SettingsLine(
              icon: Icons.dns_outlined,
              text: 'Active: ${RuntimeConfig.instance.effectiveBaseUrl}',
            ),
            if (_connectionResult != null)
              _SettingsLine(
                icon: _connectionOk
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                text: _connectionResult!,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Account',
          icon: Icons.person_outline,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(signedIn ? Icons.verified_user_outlined : Icons.login),
              title: Text(
                  signedIn ? 'DIIAC Entra connected' : 'DIIAC Entra sign-in'),
              subtitle: Text(signedIn
                  ? 'API requests include a bearer token.'
                  : 'Production auth uses Microsoft Entra ID.'),
              trailing: signedIn
                  ? IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        _authService.signOut();
                        setState(() {});
                      },
                    )
                  : FilledButton.icon(
                      onPressed: _signingIn || !_authService.isConfigured
                          ? null
                          : _signIn,
                      icon: _signingIn
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: const Text('Sign in'),
                    ),
            ),
            _SettingsLine(
              icon: signedIn ? Icons.check_circle_outline : Icons.info_outline,
              text: AuthState.instance.authStatusMessage,
            ),
            _SettingsLine(
              icon: Icons.vpn_key_outlined,
              text:
                  'Auth ${CarpCraftAuthService.clientIdSummary} | ${CarpCraftAuthService.scopeSummary} | oauthredirect',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Defaults',
          icon: Icons.tune_outlined,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: true,
              onChanged: (_) {},
              title: const Text('Private venues and spots'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.preciseLocationEnabled,
              onChanged: _requestingLocation ? null : _setPreciseLocation,
              title: const Text('Precise location'),
              subtitle: const Text(
                  'Only used when you choose current location or map a spot.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.aiExplanationsEnabled,
              onChanged: (value) {
                AppSettingsState.instance.setAiExplanationsEnabled(value);
                setState(() {});
              },
              title: const Text('AI explanations'),
              subtitle: const Text(
                  'Shows grounded evidence, confidence and data gaps.'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsLine extends StatelessWidget {
  const _SettingsLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class PrivacyControlsScreen extends StatelessWidget {
  const PrivacyControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Privacy controls',
      children: [
        const SectionCard(
          title: 'Sensitive data',
          icon: Icons.lock_outline,
          children: [
            Text(
                'Venues, swims, spots, catch locations, photos and target fish notes stay private by default.'),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Future controls',
          icon: Icons.admin_panel_settings_outlined,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: false,
              onChanged: (_) {},
              title: const Text('Export data'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: false,
              onChanged: (_) {},
              title: const Text('Delete account data'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: false,
              onChanged: (_) {},
              title: const Text('Share anonymised product analytics'),
            ),
          ],
        ),
      ],
    );
  }
}
