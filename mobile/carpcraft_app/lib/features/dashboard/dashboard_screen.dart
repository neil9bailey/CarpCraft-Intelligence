import 'package:flutter/material.dart';

import '../../app.dart';
import '../../shared/carp_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 166,
              child: MetricTile(label: 'Rod-hours', value: '18.5', icon: Icons.schedule),
            ),
            SizedBox(
              width: 166,
              child: MetricTile(label: 'Blanks logged', value: '3', icon: Icons.hourglass_empty),
            ),
            SizedBox(
              width: 166,
              child: MetricTile(label: 'Confidence', value: '50%', icon: Icons.verified_outlined),
            ),
            SizedBox(
              width: 166,
              child: MetricTile(label: 'Data gaps', value: '2', icon: Icons.error_outline),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Tonight',
          icon: Icons.nights_stay_outlined,
          children: [
            const Text('Log water temperature before trusting pattern confidence.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.startSession),
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
            const Text('Windward reedline, light to moderate baiting, one mobile rod.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.recommendation),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open card'),
            ),
          ],
        ),
      ],
    );
  }
}
