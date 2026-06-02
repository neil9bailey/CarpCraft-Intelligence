import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app.dart';
import '../../core/auth_service.dart';
import '../../core/auth_state.dart';
import '../../shared/carp_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _buildSha = String.fromEnvironment(
    'CARPCRAFT_BUILD_SHA',
    defaultValue: 'local',
  );
  static const String _buildChannel = String.fromEnvironment(
    'CARPCRAFT_BUILD_CHANNEL',
    defaultValue: 'dev',
  );

  final CarpCraftAuthService _authService = CarpCraftAuthService();
  late final Future<PackageInfo> _packageInfo;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    AuthState.instance.addListener(_authChanged);
  }

  @override
  void dispose() {
    AuthState.instance.removeListener(_authChanged);
    super.dispose();
  }

  void _authChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
    });
    try {
      await _authService.signIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DIIAC Entra sign-in complete.')),
        );
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

  @override
  Widget build(BuildContext context) {
    final authState = AuthState.instance;
    return CarpScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          tooltip: 'Privacy controls',
          icon: const Icon(Icons.lock_outline),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.privacy),
        ),
      ],
      children: [
        Text(
          'CarpCraft Intelligence',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Evidence-ranked watercraft for private venue memory.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Account and build',
          icon: Icons.verified_user_outlined,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                authState.isSignedIn ? Icons.check_circle_outline : Icons.login,
              ),
              title: Text(authState.isSignedIn
                  ? 'DIIAC Entra connected'
                  : 'DIIAC Entra sign-in required'),
              subtitle: Text(authState.isSignedIn
                  ? 'Production API requests include a bearer token.'
                  : 'Live venues, AI intelligence and provider status need sign-in.'),
              trailing: authState.isSignedIn
                  ? IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout),
                      onPressed: () => _authService.signOut(),
                    )
                  : FilledButton.icon(
                      onPressed: _signingIn ||
                              authState.signInInProgress ||
                              !_authService.isConfigured
                          ? null
                          : _signIn,
                      icon: _signingIn || authState.signInInProgress
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Sign in'),
                    ),
            ),
            if (authState.apiAuthRequired)
              _DashboardLine(
                icon: Icons.error_outline,
                text: authState.lastApiAuthMessage ??
                    'Production API sign-in is required.',
              ),
            _DashboardLine(
              icon: authState.isSignedIn
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              text: authState.authStatusMessage,
            ),
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                final version = info == null
                    ? 'loading'
                    : '${info.version}+${info.buildNumber}';
                return _DashboardLine(
                  icon: Icons.tag_outlined,
                  text: 'Build $_buildChannel $_buildSha | App $version',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 166,
              child: MetricTile(
                  label: 'Rod-hours', value: '18.5', icon: Icons.schedule),
            ),
            SizedBox(
              width: 166,
              child: MetricTile(
                  label: 'Blanks logged',
                  value: '3',
                  icon: Icons.hourglass_empty),
            ),
            SizedBox(
              width: 166,
              child: MetricTile(
                  label: 'Confidence',
                  value: '50%',
                  icon: Icons.verified_outlined),
            ),
            SizedBox(
              width: 166,
              child: MetricTile(
                  label: 'Data gaps', value: '2', icon: Icons.error_outline),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Tonight',
          icon: Icons.nights_stay_outlined,
          children: [
            const Text(
                'Log water temperature before trusting pattern confidence.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.startSession),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start session'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Latest recommendation',
          icon: Icons.tips_and_updates_outlined,
          children: [
            const Text(
                'Windward reedline, light to moderate baiting, one mobile rod.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.recommendation),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open card'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardLine extends StatelessWidget {
  const _DashboardLine({required this.icon, required this.text});

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
