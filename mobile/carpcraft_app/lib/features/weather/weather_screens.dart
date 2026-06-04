import 'package:flutter/material.dart';

import '../../core/app_repository.dart';
import '../../core/models.dart';
import '../../shared/carp_scaffold.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final AppRepository _repository = const AppRepository();
  late Future<WeatherConditionSnapshot> _conditions;
  late Future<IntelligenceBrief> _brief;
  late Future<ProviderStatus> _anglingAIStatus;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _conditions = _repository.loadLiveWeatherConditions();
    _brief = _repository.loadExampleIntelligenceBrief();
    _anglingAIStatus = _repository.loadAnglingAIStatus();
  }

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Weather',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(_reload),
        ),
      ],
      children: [
        FutureBuilder<WeatherConditionSnapshot>(
          future: _conditions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SectionCard(
                title: 'Live conditions',
                icon: Icons.cloud_outlined,
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  ),
                ],
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _LiveErrorCard(
                title: 'Live conditions',
                icon: Icons.cloud_off_outlined,
                message:
                    'Live weather did not return from the CarpCraft API. Refresh after sign-in and provider configuration are confirmed.',
                error: snapshot.error,
              );
            }
            final condition = snapshot.data!;
            return Column(
              children: [
                SectionCard(
                  title: 'Live conditions',
                  icon: Icons.cloud_outlined,
                  children: [
                    MetricTile(
                      label: 'Condition',
                      value: _label(condition.condition),
                      icon: Icons.wb_cloudy_outlined,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'Air temp',
                      value: _number(condition.airTempC, 'C'),
                      icon: Icons.thermostat_outlined,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'Surface approx',
                      value: condition.approxSurfaceTempC == null
                          ? 'Gap'
                          : '${condition.approxSurfaceTempC!.toStringAsFixed(1)} C (${condition.approxSurfaceTempConfidence}%)',
                      icon: Icons.water_drop_outlined,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'Pressure',
                      value: _number(condition.pressureHpa, 'hPa'),
                      icon: Icons.speed_outlined,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'Wind',
                      value: condition.windSpeedMps == null
                          ? 'Gap'
                          : '${condition.windSpeedMps!.toStringAsFixed(1)} m/s ${condition.windDirectionLabel ?? ''}',
                      icon: Icons.air_outlined,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'Rain',
                      value:
                          '${_label(condition.precipitationIntensity ?? 'unknown')} | ${_number(condition.rainfallMm, 'mm')}',
                      icon: Icons.umbrella_outlined,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'Humidity/cloud',
                      value:
                          '${condition.humidityPercent ?? 0}% RH | ${condition.cloudCoverPercent ?? 0}% cloud',
                      icon: Icons.filter_drama_outlined,
                    ),
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: Icons.hub_outlined,
                      text:
                          '${condition.providerCount} weather sources attached',
                    ),
                    for (final note in condition.approximationNotes)
                      _InfoLine(icon: Icons.science_outlined, text: note),
                    for (final gap in condition.dataGaps)
                      _InfoLine(icon: Icons.info_outline, text: gap),
                  ],
                ),
                const SizedBox(height: 12),
                const SectionCard(
                  title: 'Live session inputs',
                  icon: Icons.assignment_outlined,
                  children: [
                    _InputPill(
                        icon: Icons.water_outlined, label: 'Venue and lake'),
                    _InputPill(
                        icon: Icons.place_outlined, label: 'Swim and spot'),
                    _InputPill(
                        icon: Icons.cloud_outlined, label: 'Weather snapshot'),
                    _InputPill(
                        icon: Icons.visibility_outlined,
                        label: 'Shows and liners'),
                    _InputPill(
                        icon: Icons.add_a_photo_outlined,
                        label: 'Annotated captures'),
                    _InputPill(
                        icon: Icons.thermostat_outlined,
                        label: 'Water readings'),
                    _InputPill(
                        icon: Icons.construction_outlined,
                        label: 'Rig and bait'),
                    _InputPill(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Fish welfare'),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<IntelligenceBrief>(
          future: _brief,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SectionCard(
                title: 'AI intelligence',
                icon: Icons.psychology_outlined,
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  ),
                ],
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _LiveErrorCard(
                title: 'AI intelligence',
                icon: Icons.psychology_outlined,
                message:
                    'No live AI brief is available. Create or load a session with weather, observations and capture evidence before relying on explanations.',
                error: snapshot.error,
              );
            }
            final brief = snapshot.data!;
            return SectionCard(
              title: 'AI intelligence',
              icon: Icons.psychology_outlined,
              children: [
                Text(brief.headline,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _InfoLine(
                    icon: Icons.verified_outlined,
                    text: '${brief.confidenceScore}% confidence'),
                const Divider(height: 22),
                for (final recommendation in brief.recommendations)
                  _InfoLine(
                      icon: Icons.tips_and_updates_outlined,
                      text: recommendation),
                if (brief.evidence.isNotEmpty) const Divider(height: 22),
                for (final evidence in brief.evidence)
                  _InfoLine(icon: Icons.source_outlined, text: evidence),
                if (brief.dataGaps.isNotEmpty) const Divider(height: 22),
                for (final gap in brief.dataGaps)
                  _InfoLine(icon: Icons.info_outline, text: gap),
                const Divider(height: 22),
                for (final warning in brief.safetyWarnings)
                  _InfoLine(
                      icon: Icons.health_and_safety_outlined, text: warning),
                _InfoLine(
                    icon: Icons.rule_outlined, text: brief.noGuaranteeNotice),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<ProviderStatus>(
          future: _anglingAIStatus,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SectionCard(
                title: 'External agents',
                icon: Icons.hub_outlined,
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  ),
                ],
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _LiveErrorCard(
                title: 'External agents',
                icon: Icons.hub_outlined,
                message:
                    'Provider status did not return from the production API. Check Entra sign-in and backend configuration.',
                error: snapshot.error,
              );
            }
            final status = snapshot.data!;
            return SectionCard(
              title: 'External agents',
              icon: Icons.hub_outlined,
              children: [
                _InfoLine(
                  icon: status.configured
                      ? Icons.check_circle_outline
                      : Icons.key_off_outlined,
                  text: '${status.providerName}: ${status.summary}',
                ),
                for (final gap in status.dataGaps)
                  _InfoLine(icon: Icons.info_outline, text: gap),
                const Divider(height: 22),
                const _InfoLine(
                  icon: Icons.psychology_alt_outlined,
                  text:
                      'AnglingAI output is treated as external advisory evidence until reviewed against CarpCraft logs and fishery rules.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _number(double? value, String unit) {
    if (value == null) {
      return 'Gap';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  String _label(String value) {
    return value.replaceAll('_', ' ');
  }
}

class _LiveErrorCard extends StatelessWidget {
  const _LiveErrorCard({
    required this.title,
    required this.icon,
    required this.message,
    this.error,
  });

  final String title;
  final IconData icon;
  final String message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      children: [
        _InfoLine(icon: Icons.info_outline, text: message),
        if (error != null)
          _InfoLine(icon: Icons.error_outline, text: error.toString()),
      ],
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
