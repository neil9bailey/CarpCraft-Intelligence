import 'package:flutter/material.dart';

import '../app.dart';
import '../core/connectivity.dart';
import '../core/runtime_config.dart';

/// Inline banner that surfaces backend reachability on any screen.
///
/// Hidden when the backend is online; shows a "checking" state while probing and
/// a clear "not reachable" card (with Open Settings / Retry) when offline. Drop
/// it at the top of a screen's content.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, this.checkOnInit = true});

  /// Probe the backend when first shown, but only if status is still unknown
  /// (avoids re-checking every navigation).
  final bool checkOnInit;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  @override
  void initState() {
    super.initState();
    BackendConnectivity.instance.addListener(_onChanged);
    if (widget.checkOnInit &&
        BackendConnectivity.instance.status == BackendStatus.unknown) {
      BackendConnectivity.instance.check();
    }
  }

  @override
  void dispose() {
    BackendConnectivity.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = BackendConnectivity.instance;
    if (conn.status == BackendStatus.online) {
      return const SizedBox.shrink();
    }
    final checking = conn.status == BackendStatus.checking;
    final color = checking ? const Color(0xFF155E63) : const Color(0xFFB3261E);
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
}
