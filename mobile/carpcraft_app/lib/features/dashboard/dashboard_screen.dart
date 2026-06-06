import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app.dart';
import '../../core/auth_service.dart';
import '../../core/auth_state.dart';
import '../../core/connectivity.dart';
import '../../core/runtime_config.dart';
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
    BackendConnectivity.instance.addListener(_authChanged);
    // Probe the backend on load so the banner reflects real reachability.
    BackendConnectivity.instance.check();
  }

  @override
  void dispose() {
    AuthState.instance.removeListener(_authChanged);
    BackendConnectivity.instance.removeListener(_authChanged);
    super.dispose();
  }

  void _authChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildConnectivityBanner(BuildContext context) {
    final conn = BackendConnectivity.instance;
    if (conn.status == BackendStatus.online) {
      return const SizedBox.shrink();
    }
    final checking = conn.status == BackendStatus.checking;
    final color =
        checking ? const Color(0xFF155E63) : const Color(0xFFB3261E);
    final background =
        checking ? const Color(0xFFE3F0EF) : const Color(0xFFFCE8E6);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(checking ? Icons.sync : Icons.cloud_off_outlined,
                  color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  checking
                      ? 'Checking backend connection…'
                      : 'Backend not reachable',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            conn.message ??
                (checking
                    ? 'Contacting ${RuntimeConfig.instance.effectiveBaseUrl}.'
                    : 'Weather, venues and recommendations need a reachable backend. Set the API URL in Settings.'),
          ),
          if (!checking) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open Settings'),
                ),
                OutlinedButton.icon(
                  onPressed: () => BackendConnectivity.instance.check(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
        _buildConnectivityBanner(context),
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
                      onPressed: _signingIn || !_authService.isConfigured
                          ? null
                          : _signIn,
                      icon: _signingIn
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
            _DashboardLine(
              icon: Icons.vpn_key_outlined,
              text:
                  'Auth ${CarpCraftAuthService.clientIdSummary} | ${CarpCraftAuthService.scopeSummary} | oauthredirect',
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
        SectionCard(
          title: 'Live tools',
          icon: Icons.sensors_outlined,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.venues),
                  icon: const Icon(Icons.travel_explore_outlined),
                  label: const Text('Find fishery'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.weather),
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('Weather'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.startSession),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start session'),
                ),
              ],
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
