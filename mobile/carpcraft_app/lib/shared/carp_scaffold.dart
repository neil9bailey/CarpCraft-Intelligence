import 'package:flutter/material.dart';

import '../app.dart';

class NavDestination {
  const NavDestination(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

const mainDestinations = [
  NavDestination('Dashboard', AppRoutes.dashboard, Icons.dashboard_outlined),
  NavDestination('Venues', AppRoutes.venues, Icons.water_outlined),
  NavDestination('Start session', AppRoutes.startSession, Icons.play_arrow_outlined),
  NavDestination('Live session', AppRoutes.liveSession, Icons.timeline_outlined),
  NavDestination('Recommendation', AppRoutes.recommendation, Icons.tips_and_updates_outlined),
  NavDestination('Capture', AppRoutes.capture, Icons.add_a_photo_outlined),
  NavDestination('Weather', AppRoutes.weather, Icons.cloud_outlined),
  NavDestination('Review', AppRoutes.review, Icons.assignment_turned_in_outlined),
  NavDestination('Settings', AppRoutes.settings, Icons.settings_outlined),
  NavDestination('Privacy', AppRoutes.privacy, Icons.lock_outline),
];

class CarpScaffold extends StatelessWidget {
  const CarpScaffold({
    required this.title,
    required this.children,
    super.key,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const ListTile(
                leading: Icon(Icons.insights),
                title: Text('CarpCraft Intelligence'),
                subtitle: Text('Private by default'),
              ),
              const Divider(),
              for (final destination in mainDestinations)
                ListTile(
                  leading: Icon(destination.icon),
                  title: Text(destination.label),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, destination.route);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.children,
    super.key,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5DD)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FormShell extends StatelessWidget {
  const FormShell({
    required this.title,
    required this.fields,
    required this.primaryLabel,
    super.key,
  });

  final String title;
  final List<Widget> fields;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: title,
      children: [
        SectionCard(
          title: title,
          icon: Icons.edit_note_outlined,
          children: [
            ...fields.expand((field) => [field, const SizedBox(height: 12)]),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: Text(primaryLabel),
            ),
          ],
        ),
      ],
    );
  }
}
