import 'package:flutter/material.dart';

import '../../core/auth_service.dart';
import '../../core/auth_state.dart';
import '../../shared/carp_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CarpCraftAuthService _authService = CarpCraftAuthService();
  bool _signingIn = false;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthState.instance.isSignedIn;
    return CarpScaffold(
      title: 'Settings',
      children: [
        SectionCard(
          title: 'Account',
          icon: Icons.person_outline,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(signedIn ? Icons.verified_user_outlined : Icons.login),
              title: Text(signedIn ? 'DIIAC Entra connected' : 'DIIAC Entra sign-in'),
              subtitle: Text(signedIn ? 'API requests include a bearer token.' : 'Production auth uses Microsoft Entra ID.'),
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
                      onPressed: _signingIn || !_authService.isConfigured ? null : _signIn,
                      icon: _signingIn
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: const Text('Sign in'),
                    ),
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
              value: false,
              onChanged: (_) {},
              title: const Text('Precise location'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: false,
              onChanged: (_) {},
              title: const Text('AI explanations'),
            ),
          ],
        ),
      ],
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
            Text('Venues, swims, spots, catch locations, photos and target fish notes stay private by default.'),
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
