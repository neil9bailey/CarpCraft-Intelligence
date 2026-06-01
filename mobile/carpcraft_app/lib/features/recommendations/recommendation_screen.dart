import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _recommendation = _repository.generateRecommendation();
  }

  void _reload() {
    setState(() {
      _recommendation = _repository.generateRecommendation();
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
      ],
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
            _Block(title: 'Tactic', text: recommendation.tactic),
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
