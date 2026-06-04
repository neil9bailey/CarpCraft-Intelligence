import 'package:flutter/material.dart';

import '../../core/app_settings_state.dart';
import '../../core/app_repository.dart';
import '../../core/mock_data.dart';
import '../../shared/carp_scaffold.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final AppRepository _repository = const AppRepository();
  late Future<MockRecommendation> _recommendation;
  late Future<MockIntelligenceBrief> _brief;

  @override
  void initState() {
    super.initState();
    _recommendation = _repository.generateRecommendation();
    _brief = _repository.loadExampleIntelligenceBrief();
  }

  void _reload() {
    setState(() {
      _recommendation = _repository.generateRecommendation();
      _brief = _repository.loadExampleIntelligenceBrief();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Recommendation',
      actions: [
        IconButton(
          tooltip: 'Regenerate',
          icon: const Icon(Icons.refresh),
          onPressed: _reload,
        ),
      ],
      children: [
        FutureBuilder<MockRecommendation>(
          future: _recommendation,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
            }
            return RecommendationCard(recommendation: snapshot.data ?? mockRecommendation);
          },
        ),
        const SizedBox(height: 12),
        if (AppSettingsState.instance.aiExplanationsEnabled)
          FutureBuilder<MockIntelligenceBrief>(
            future: _brief,
            builder: (context, snapshot) {
              final brief = snapshot.data ?? mockIntelligenceBrief;
              return SectionCard(
                title: 'AI explanation',
                icon: Icons.psychology_outlined,
                children: [
                  Text(brief.headline),
                  const SizedBox(height: 8),
                  _ExplanationLine(
                    icon: Icons.verified_outlined,
                    text: '${brief.confidenceScore}% confidence',
                  ),
                  for (final evidence in brief.evidence)
                    _ExplanationLine(
                        icon: Icons.source_outlined, text: evidence),
                  for (final gap in brief.dataGaps)
                    _ExplanationLine(icon: Icons.info_outline, text: gap),
                  for (final warning in brief.safetyWarnings)
                    _ExplanationLine(
                        icon: Icons.health_and_safety_outlined,
                        text: warning),
                  _ExplanationLine(
                      icon: Icons.rule_outlined,
                      text: brief.noGuaranteeNotice),
                ],
              );
            },
          )
        else
          SectionCard(
            title: 'AI explanation',
            icon: Icons.psychology_outlined,
            children: [
              const Text('AI explanations are disabled in Settings.'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  AppSettingsState.instance.setAiExplanationsEnabled(true);
                  setState(() {});
                },
                icon: const Icon(Icons.toggle_on_outlined),
                label: const Text('Enable explanations'),
              ),
            ],
          ),
      ],
    );
  }
}

class _ExplanationLine extends StatelessWidget {
  const _ExplanationLine({required this.icon, required this.text});

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

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({required this.recommendation, super.key});

  final MockRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bite opportunity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _ScorePill(
                  value: '${recommendation.biteOpportunity}%',
                  color: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: recommendation.biteOpportunity / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.secondary,
              backgroundColor: const Color(0xFFE4E8DF),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(icon: Icons.verified_outlined, label: 'Confidence ${recommendation.confidence}%'),
                _InfoChip(icon: Icons.place_outlined, label: recommendation.zone),
                _InfoChip(icon: Icons.layers_outlined, label: recommendation.layer),
                _InfoChip(icon: Icons.restaurant_outlined, label: recommendation.baiting),
              ],
            ),
            const SizedBox(height: 18),
            if (recommendation.priorityActions.isNotEmpty)
              _ActionPlanBlock(actions: recommendation.priorityActions),
            if (recommendation.primeFeedingWindows.isNotEmpty)
              _PrimeWindowsBlock(windows: recommendation.primeFeedingWindows),
            _Block(title: 'Tactic', text: recommendation.tactic),
            if (recommendation.seasonalContext != null)
              _Block(title: 'Seasonal context', text: recommendation.seasonalContext!),
            if (recommendation.barometricNote != null)
              _Block(title: 'Pressure read', text: recommendation.barometricNote!),
            _ListBlock(title: 'Why', items: recommendation.why),
            _ListBlock(title: 'Data gaps', items: recommendation.dataGaps),
            _Block(title: 'Alternative plan', text: recommendation.alternativePlan),
            if (recommendation.fishWelfareWarning != null)
              _WarningBlock(text: recommendation.fishWelfareWarning!),
            const SizedBox(height: 8),
            Text(
              'No catch guarantee. Review outcomes after the session.',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF61420B)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionPlanBlock extends StatelessWidget {
  const _ActionPlanBlock({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Priority action plan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (var i = 0; i < actions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text('${i + 1}',
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(actions[i])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimeWindowsBlock extends StatelessWidget {
  const _PrimeWindowsBlock({required this.windows});

  final List<String> windows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prime feeding windows',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final window in windows)
                Chip(
                  avatar: const Icon(Icons.schedule_outlined, size: 18),
                  label: Text(window),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningBlock extends StatelessWidget {
  const _WarningBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5B44D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
