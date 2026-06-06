import 'package:flutter/material.dart';

import '../../app.dart';
import '../../shared/carp_scaffold.dart';

class StartSessionScreen extends StatelessWidget {
  const StartSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Start session',
      children: [
        const SectionCard(
          title: 'Session setup',
          icon: Icons.play_arrow_outlined,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Venue')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Swim')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Pressure count')),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.liveSession),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        ),
      ],
    );
  }
}

class LiveSessionDashboardScreen extends StatelessWidget {
  const LiveSessionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CarpScaffold(
      title: 'Live session',
      children: [
        SectionCard(
          title: 'Live evidence',
          icon: Icons.sensors_outlined,
          children: [
            _SessionInfoLine(
              icon: Icons.info_outline,
              text:
                  'No live session evidence has been saved yet. Log rods, observations, water, catches or blank intervals to build the session record.',
            ),
          ],
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionButton('Rods', Icons.settings_input_component_outlined,
                AppRoutes.rodSetup),
            _ActionButton('Observation', Icons.add_alert_outlined,
                AppRoutes.addObservation),
            _ActionButton(
                'Water', Icons.thermostat_outlined, AppRoutes.addWaterReading),
            _ActionButton('Catch', Icons.add_photo_alternate_outlined,
                AppRoutes.addCatch),
            _ActionButton(
                'Blank', Icons.hourglass_bottom_outlined, AppRoutes.addBlank),
            _ActionButton('Advice', Icons.tips_and_updates_outlined,
                AppRoutes.recommendation),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SessionInfoLine extends StatelessWidget {
  const _SessionInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class RodSetupScreen extends StatelessWidget {
  const RodSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormShell(
      title: 'Rod setup',
      primaryLabel: 'Save rods',
      fields: [
        TextField(decoration: InputDecoration(labelText: 'Rod number')),
        TextField(decoration: InputDecoration(labelText: 'Spot')),
        TextField(decoration: InputDecoration(labelText: 'Presentation layer')),
        TextField(decoration: InputDecoration(labelText: 'Rig type')),
        TextField(decoration: InputDecoration(labelText: 'Hookbait')),
      ],
    );
  }
}

class AddObservationScreen extends StatelessWidget {
  const AddObservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormShell(
      title: 'Observation',
      primaryLabel: 'Log observation',
      fields: [
        TextField(decoration: InputDecoration(labelText: 'Type')),
        TextField(decoration: InputDecoration(labelText: 'Swim or spot')),
        TextField(decoration: InputDecoration(labelText: 'Confidence')),
        TextField(decoration: InputDecoration(labelText: 'Notes'), maxLines: 3),
      ],
    );
  }
}

class AddWaterReadingScreen extends StatelessWidget {
  const AddWaterReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormShell(
      title: 'Water reading',
      primaryLabel: 'Save reading',
      fields: [
        TextField(decoration: InputDecoration(labelText: 'Water temp C')),
        TextField(
            decoration: InputDecoration(labelText: 'Dissolved oxygen mg/L')),
        TextField(decoration: InputDecoration(labelText: 'pH')),
        TextField(decoration: InputDecoration(labelText: 'Depth m')),
      ],
    );
  }
}

class AddCatchScreen extends StatelessWidget {
  const AddCatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormShell(
      title: 'Catch',
      primaryLabel: 'Save catch',
      fields: [
        TextField(decoration: InputDecoration(labelText: 'Rod')),
        TextField(decoration: InputDecoration(labelText: 'Species')),
        TextField(decoration: InputDecoration(labelText: 'Weight lb')),
        TextField(decoration: InputDecoration(labelText: 'Weight oz')),
        TextField(
            decoration: InputDecoration(labelText: 'Fish condition notes'),
            maxLines: 3),
      ],
    );
  }
}

class AddBlankIntervalScreen extends StatelessWidget {
  const AddBlankIntervalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormShell(
      title: 'Blank interval',
      primaryLabel: 'Save blank',
      fields: [
        TextField(decoration: InputDecoration(labelText: 'Started')),
        TextField(decoration: InputDecoration(labelText: 'Ended')),
        TextField(decoration: InputDecoration(labelText: 'Rods active')),
        TextField(decoration: InputDecoration(labelText: 'Notes'), maxLines: 3),
      ],
    );
  }
}

class PostSessionReviewScreen extends StatelessWidget {
  const PostSessionReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Review',
      children: [
        const SectionCard(
          title: 'Outcome summary',
          icon: Icons.assignment_turned_in_outlined,
          children: [
            _SessionInfoLine(
              icon: Icons.info_outline,
              text:
                  'No live session outcome data is loaded yet. Saved catches, blanks, rod-hours and observations will appear here once attached to a session.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionCard(
          title: 'Learning notes',
          icon: Icons.psychology_alt_outlined,
          children: [
            TextField(
              decoration:
                  InputDecoration(labelText: 'What changed the session?'),
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.dashboard),
          icon: const Icon(Icons.check),
          label: const Text('Finish review'),
        ),
      ],
    );
  }
}
