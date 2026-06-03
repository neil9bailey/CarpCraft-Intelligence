import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_settings_state.dart';
import '../../core/auth_service.dart';
import '../../core/auth_state.dart';
import '../../shared/carp_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final CarpCraftAuthService _authService = CarpCraftAuthService();
  bool _signingIn = false;
  bool _requestingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markUncapturedAuthReturnIfNeeded();
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
    });
    try {
      await _authService.signIn();
      if (mounted) {
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

  Future<void> _markUncapturedAuthReturnIfNeeded() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) {
      return;
    }
    final authState = AuthState.instance;
    if (authState.signInInProgress && !authState.isSignedIn) {
      authState.markSignInReturnedWithoutToken();
      setState(() {
        _signingIn = false;
      });
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
    final signingIn = AuthState.instance.signInInProgress;
    final settings = AppSettingsState.instance;
    return CarpScaffold(
      title: 'Settings',
      children: [
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
                      onPressed:
                          _signingIn || signingIn || !_authService.isConfigured
                              ? null
                              : _signIn,
                      icon: _signingIn || signingIn
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
