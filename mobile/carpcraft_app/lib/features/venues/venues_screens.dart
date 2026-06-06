import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/app_settings_state.dart';
import '../../core/app_repository.dart';
import '../../core/models.dart';
import '../../shared/carp_scaffold.dart';

class VenueMapArgs {
  const VenueMapArgs({
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final double latitude;
  final double longitude;
}

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final AppRepository _repository = const AppRepository();
  final TextEditingController _catalogueQueryController =
      TextEditingController();
  late Future<List<VenueSummary>> _venues;
  late Future<List<FisheryProfile>> _catalogue;
  bool _catalogueBusy = false;

  @override
  void initState() {
    super.initState();
    _venues = _repository.loadVenues();
    _catalogue = _repository.loadFisheryCatalogue();
  }

  @override
  void dispose() {
    _catalogueQueryController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _venues = _repository.loadVenues();
    });
  }

  Future<void> _researchCatalogue() async {
    final query = _catalogueQueryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a fishery name to research.')));
      return;
    }
    setState(() {
      _catalogueBusy = true;
    });
    try {
      final profiles = await _repository.researchFisheryCatalogue(query);
      if (mounted) {
        setState(() {
          _catalogue = Future.value(profiles);
        });
        final message = profiles.isEmpty
            ? 'No live fishery profile was created from that research.'
            : 'Created ${profiles.length} live fishery profile(s).';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Live fishery research failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _catalogueBusy = false;
        });
      }
    }
  }

  void _searchCatalogue() {
    setState(() {
      _catalogue =
          _repository.searchFisheryCatalogue(_catalogueQueryController.text);
    });
  }

  void _openFisheryMap(FisheryProfile profile) {
    if (!profile.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No reviewed coordinates are attached yet.')));
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.spotMap,
      arguments: VenueMapArgs(
        title: profile.displayName,
        latitude: profile.approximateLatitude!,
        longitude: profile.approximateLongitude!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Venues',
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add venue',
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.editVenue);
          _reload();
        },
        child: const Icon(Icons.add),
      ),
      children: [
        SectionCard(
          title: 'Fishery catalogue',
          icon: Icons.travel_explore_outlined,
          children: [
            TextField(
              controller: _catalogueQueryController,
              decoration: const InputDecoration(
                  labelText: 'Search fisheries with AnglingAI'),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchCatalogue(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _catalogueBusy ? null : _researchCatalogue,
                  icon: _catalogueBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Research fishery'),
                ),
                OutlinedButton.icon(
                  onPressed: _searchCatalogue,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<FisheryProfile>>(
              future: _catalogue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return _CompactInfoLine(
                    icon: Icons.error_outline,
                    text:
                        'Catalogue search failed against the live API: ${snapshot.error}',
                  );
                }
                final profiles = snapshot.data ?? <FisheryProfile>[];
                if (profiles.isEmpty) {
                  return const _CompactInfoLine(
                    icon: Icons.info_outline,
                    text:
                        'No private fishery profiles matched. Research a fishery to create a source-bound profile.',
                  );
                }
                return Column(
                  children: [
                    for (final profile in profiles)
                      _FisheryProfileCard(
                        profile: profile,
                        onMap: () => _openFisheryMap(profile),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<VenueSummary>>(
          future: _venues,
          builder: (context, snapshot) {
            final venues = snapshot.data ?? <VenueSummary>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()));
            }
            if (venues.isEmpty) {
              return const _CompactInfoLine(
                icon: Icons.water_outlined,
                text: 'No private venues saved yet.',
              );
            }
            return Column(
              children: [
                for (final venue in venues) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_outlined),
                      title: Text(venue.name),
                      subtitle: Text(
                          '${venue.locationLabel} | ${venue.sessionCount} sessions | ${venue.privacy}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.venueDetail,
                        arguments: venue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class EditVenueScreen extends StatefulWidget {
  const EditVenueScreen({super.key});

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  final AppRepository _repository = const AppRepository();
  final TextEditingController _lookupController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController =
      TextEditingController(text: 'lake');
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  bool _saving = false;
  bool _lookingUp = false;
  VenueIntelligenceReport? _intelligence;
  double? _approximateLatitude;
  double? _approximateLongitude;
  double? _acreage;

  @override
  void dispose() {
    _lookupController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _locationController.dispose();
    _rulesController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String get _activeLookupQuery {
    final query = _lookupController.text.trim();
    if (query.isNotEmpty) {
      return query;
    }
    return _intelligence?.query.trim() ?? '';
  }

  bool get _hasVenueCoordinates =>
      _approximateLatitude != null && _approximateLongitude != null;

  void _applyIntelligence(VenueIntelligenceReport intelligence) {
    final venue = intelligence.suggestedVenue;
    _lookupController.text =
        intelligence.query.isEmpty ? venue.name : intelligence.query;
    _nameController.text = venue.name;
    _typeController.text = venue.type;
    _locationController.text = venue.locationLabel;
    _rulesController.text = venue.rulesNotes ?? '';
    _stockController.text = venue.stockNotes ?? '';
    _approximateLatitude = venue.approximateLatitude;
    _approximateLongitude = venue.approximateLongitude;
    _acreage = venue.acreage;
    _intelligence = intelligence;
  }

  Future<void> _lookupVenue([String? preset]) async {
    final query = (preset ?? _lookupController.text).trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search for a venue first.')));
      return;
    }
    _lookupController.text = query;
    setState(() {
      _lookingUp = true;
    });
    try {
      final intelligence = await _repository.lookupVenueIntelligence(query);
      if (mounted) {
        setState(() {
          _applyIntelligence(intelligence);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No grounded venue intelligence returned: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _lookingUp = false;
        });
      }
    }
  }

  Future<void> _saveVenue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue name is required.')));
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await _repository.createVenue(
        name: name,
        type: _typeController.text.trim(),
        locationLabel: _locationController.text.trim(),
        rulesNotes: _rulesController.text.trim(),
        stockNotes: _stockController.text.trim(),
        approximateLatitude: _approximateLatitude,
        approximateLongitude: _approximateLongitude,
        acreage: _acreage,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save venue to the API.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _importVenue() async {
    final query = _activeLookupQuery;
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Run a venue lookup before importing.')));
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final intelligence = await _repository.importVenueIntelligence(query);
      if (mounted) {
        setState(() {
          _applyIntelligence(intelligence);
        });
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not import venue intelligence: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _openVenueMap() {
    final latitude = _approximateLatitude;
    final longitude = _approximateLongitude;
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No public location coordinates available.')));
      return;
    }
    final title = _nameController.text.trim().isEmpty
        ? 'Venue location'
        : _nameController.text.trim();
    Navigator.pushNamed(
      context,
      AppRoutes.spotMap,
      arguments:
          VenueMapArgs(title: title, latitude: latitude, longitude: longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intelligence = _intelligence;
    return CarpScaffold(
      title: 'Venue',
      children: [
        SectionCard(
          title: 'Public source lookup',
          icon: Icons.manage_search_outlined,
          children: [
            TextField(
              controller: _lookupController,
              decoration:
                  const InputDecoration(labelText: 'Venue or fishery name'),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _lookupVenue(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _lookingUp ? null : () => _lookupVenue(),
                  icon: _lookingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: const Text('Lookup'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _saving || intelligence == null ? null : _importVenue,
                  icon: const Icon(Icons.download_done_outlined),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Venue',
          icon: Icons.edit_note_outlined,
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type')),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                  labelText: 'Approximate location label'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rulesController,
              decoration: const InputDecoration(labelText: 'Rules notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _saveVenue,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Save venue'),
                ),
                OutlinedButton.icon(
                  onPressed: _hasVenueCoordinates ? _openVenueMap : null,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Map'),
                ),
              ],
            ),
          ],
        ),
        if (intelligence != null)
          ..._intelligenceSections(context, intelligence),
      ],
    );
  }

  List<Widget> _intelligenceSections(
      BuildContext context, VenueIntelligenceReport report) {
    return [
      const SizedBox(height: 12),
      SectionCard(
        title: 'Grounded intelligence',
        icon: Icons.fact_check_outlined,
        children: [
          Text(report.summary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                  icon: Icons.verified_outlined,
                  label: '${report.confidenceScore}% confidence'),
              if (report.weather?.airTempC != null)
                _InfoChip(
                    icon: Icons.thermostat_outlined,
                    label: '${report.weather!.airTempC!.toStringAsFixed(1)} C'),
              if (report.weather?.pressureHpa != null)
                _InfoChip(
                    icon: Icons.speed_outlined,
                    label:
                        '${report.weather!.pressureHpa!.toStringAsFixed(0)} hPa'),
              if (_hasVenueCoordinates)
                const _InfoChip(icon: Icons.map_outlined, label: 'Map ready'),
              if (report.externalPlace != null)
                _InfoChip(
                    icon: Icons.travel_explore_outlined,
                    label:
                        '${report.externalPlace!.sourceName} ${report.externalPlace!.confidence}%'),
            ],
          ),
          if (report.externalPlace?.formattedAddress != null) ...[
            const SizedBox(height: 12),
            _CompactInfoLine(
                icon: Icons.pin_drop_outlined,
                text: report.externalPlace!.formattedAddress!),
          ],
          if (report.weather?.dataGaps.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            ...report.weather!.dataGaps.map((gap) =>
                _CompactInfoLine(icon: Icons.cloud_off_outlined, text: gap)),
          ],
        ],
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: 'Known lakes and swims',
        icon: Icons.place_outlined,
        children: [
          for (final swim in report.swims.take(8)) ...[
            _CompactInfoLine(
              icon: swim.depthMapUrl == null
                  ? Icons.water_outlined
                  : Icons.layers_outlined,
              text: [
                swim.name,
                if (swim.acreage != null)
                  '${swim.acreage!.toStringAsFixed(0)} acres',
                if (swim.swimCount != null) '${swim.swimCount} swims',
                if (swim.depthMapUrl != null) 'depth map',
              ].join(' | '),
            ),
            if (swim.stockNotes != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: Text(swim.stockNotes!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: 'Connectors',
        icon: Icons.hub_outlined,
        children: [
          for (final connector in report.connectorStatuses) ...[
            _SourceTile(
              icon: _connectorIcon(connector.status),
              title: connector.displayName,
              subtitle: connector.summary,
              trailing: connector.status,
            ),
            for (final gap in connector.dataGaps.take(2))
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: _CompactInfoLine(icon: Icons.info_outline, text: gap),
              ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: 'Maps and public updates',
        icon: Icons.public_outlined,
        children: [
          for (final asset in report.mapAssets)
            _SourceTile(
              icon: Icons.map_outlined,
              title: asset.title,
              subtitle: [
                asset.notes ?? asset.url,
                asset.cacheAllowed
                    ? 'Cache allowed'
                    : 'Link only: ${asset.licenseStatus}',
                if (asset.attribution != null)
                  'Attribution: ${asset.attribution}',
              ].join(' | '),
              trailing: asset.assetType,
              url: asset.url,
            ),
          for (final item
              in [...report.newsItems, ...report.catchReports].take(5))
            _SourceTile(
              icon: Icons.feed_outlined,
              title: item.title,
              subtitle: item.summary,
              trailing: item.sourceName,
              url: item.url,
            ),
        ],
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: 'Evidence and gaps',
        icon: Icons.source_outlined,
        children: [
          for (final source in report.sourceEvidence)
            _SourceTile(
              icon: Icons.link_outlined,
              title: '${source.sourceName} (${source.confidence}%)',
              subtitle: [
                source.summary,
                if (source.usageNotes != null) source.usageNotes,
              ].whereType<String>().join(' | '),
              trailing: source.sourceType,
              url: source.url,
            ),
          if (report.licensingNotes.isNotEmpty) const Divider(height: 22),
          for (final note in report.licensingNotes)
            _CompactInfoLine(icon: Icons.policy_outlined, text: note),
          if (report.dataGaps.isNotEmpty) const Divider(height: 22),
          for (final gap in report.dataGaps)
            _CompactInfoLine(icon: Icons.info_outline, text: gap),
          for (final warning in report.ethicalWarnings)
            _CompactInfoLine(
                icon: Icons.health_and_safety_outlined, text: warning),
        ],
      ),
    ];
  }

  IconData _connectorIcon(String status) {
    return switch (status) {
      'active' => Icons.check_circle_outline,
      'request_failed' => Icons.error_outline,
      'blocked_by_policy' => Icons.block_outlined,
      'partner_required' => Icons.handshake_outlined,
      'manual_directory' => Icons.manage_search_outlined,
      _ => Icons.info_outline,
    };
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _CompactInfoLine extends StatelessWidget {
  const _CompactInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.url,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              trailing,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (url != null && url!.isNotEmpty)
            IconButton(
              tooltip: 'Open source',
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => _launchExternalUrl(url!),
            ),
        ],
      ),
    );
    if (url == null || url!.isEmpty) {
      return content;
    }
    return InkWell(
      onTap: () => _launchExternalUrl(url!),
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}

class _FisheryProfileCard extends StatelessWidget {
  const _FisheryProfileCard({
    required this.profile,
    required this.onMap,
  });

  final FisheryProfile profile;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final primarySections = profile.sections.take(4).toList();
    final sourceUrl =
        profile.sources.isEmpty ? null : profile.sources.first.url;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.water_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (profile.locationLabel != null)
                      Text(profile.locationLabel!,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              _InfoChip(
                  icon: Icons.verified_outlined,
                  label: '${profile.confidenceScore}%'),
            ],
          ),
          if (profile.description != null) ...[
            const SizedBox(height: 10),
            Text(profile.description!),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                  icon: Icons.place_outlined,
                  label: '${profile.lakes.length} lakes/swims'),
              _InfoChip(
                  icon: Icons.link_outlined,
                  label: '${profile.sources.length} sources'),
              if (profile.mapAssets.isNotEmpty)
                _InfoChip(
                    icon: Icons.map_outlined,
                    label: '${profile.mapAssets.length} maps'),
            ],
          ),
          if (primarySections.isNotEmpty) ...[
            const Divider(height: 22),
            for (final section in primarySections)
              _CompactInfoLine(
                icon: _sectionIcon(section.category),
                text: [
                  section.title,
                  if (section.items.isNotEmpty) section.items.first,
                ].join(' | '),
              ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: profile.hasCoordinates ? onMap : null,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Map'),
              ),
              if (sourceUrl != null && sourceUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchExternalUrl(sourceUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Source'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _sectionIcon(String category) {
  return switch (category) {
    'location' => Icons.pin_drop_outlined,
    'access' => Icons.lock_open_outlined,
    'parking' => Icons.local_parking_outlined,
    'facilities' => Icons.wc_outlined,
    'rules' => Icons.rule_folder_outlined,
    'lakes' => Icons.water_outlined,
    'booking' => Icons.confirmation_number_outlined,
    _ => Icons.info_outline,
  };
}

Future<void> _launchExternalUrl(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return;
  }
}

class VenueDetailScreen extends StatelessWidget {
  const VenueDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final venue = args is VenueSummary ? args : null;
    return CarpScaffold(
      title: venue?.name ?? 'Venue detail',
      actions: [
        IconButton(
          tooltip: 'Edit venue',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.editVenue),
        ),
      ],
      children: [
        SectionCard(
          title: 'Private venue memory',
          icon: Icons.lock_outline,
          children: [
            if (venue == null)
              const Text('No saved venue was selected.')
            else ...[
              Text(venue.locationLabel),
              const SizedBox(height: 8),
              Text(
                  '${venue.sessionCount} saved session(s). Privacy: ${venue.privacy}.'),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.swims),
              icon: const Icon(Icons.place_outlined),
              label: const Text('Swims'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.spotMap),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Spot map'),
            ),
          ],
        ),
      ],
    );
  }
}

class SwimListScreen extends StatelessWidget {
  const SwimListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Swims',
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add swim',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.editSwim),
        child: const Icon(Icons.add_location_alt_outlined),
      ),
      children: const [
        SectionCard(
          title: 'Private swims',
          icon: Icons.place_outlined,
          children: [
            _CompactInfoLine(
              icon: Icons.info_outline,
              text: 'No live swims are loaded for this venue yet.',
            ),
          ],
        ),
      ],
    );
  }
}

class EditSwimScreen extends StatelessWidget {
  const EditSwimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormShell(
      title: 'Swim',
      primaryLabel: 'Save swim',
      fields: [
        TextField(decoration: InputDecoration(labelText: 'Name')),
        TextField(decoration: InputDecoration(labelText: 'Bank aspect')),
        TextField(
            decoration: InputDecoration(labelText: 'Wind exposure notes'),
            maxLines: 3),
        TextField(
            decoration: InputDecoration(labelText: 'Access notes'),
            maxLines: 2),
      ],
    );
  }
}

class SpotMapScreen extends StatefulWidget {
  const SpotMapScreen({super.key});

  @override
  State<SpotMapScreen> createState() => _SpotMapScreenState();
}

class _SpotMapScreenState extends State<SpotMapScreen> {
  static const String _googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const LatLng _initialTarget = LatLng(52.3555, -1.1743);
  GoogleMapController? _mapController;
  LatLng _mapTarget = _initialTarget;
  String _mapTitle = 'Selected spot';
  String _locationState = 'Location off';
  MapType _mapType = MapType.hybrid;
  double _zoom = 18;
  double _bearing = 0;
  double _tilt = 0;
  CameraPosition? _lastCameraPosition;
  bool _loadedRouteArgs = false;
  bool _currentLocationActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRouteArgs) {
      return;
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VenueMapArgs) {
      _mapTarget = LatLng(args.latitude, args.longitude);
      _mapTitle = args.title;
      _locationState = 'Venue location from public source';
    }
    _loadedRouteArgs = true;
  }

  Future<void> _useCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentLocationActive = false;
        _locationState = 'Location services disabled';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      setState(() {
        _currentLocationActive = false;
        _locationState = 'Location not allowed';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    AppSettingsState.instance.setPreciseLocationEnabled(true);
    final target = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocationActive = true;
      _mapTarget = target;
      _locationState =
          'Current location active, accuracy ${position.accuracy.toStringAsFixed(0)} m';
    });
    await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: target, zoom: _zoom, bearing: _bearing, tilt: _tilt),
    ));
  }

  Future<void> _recenterMap() async {
    await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: _mapTarget, zoom: _zoom, bearing: _bearing, tilt: _tilt),
    ));
  }

  String get _mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=${_mapTarget.latitude},${_mapTarget.longitude}';

  String get _earthUrl =>
      'https://earth.google.com/web/search/${_mapTarget.latitude},${_mapTarget.longitude}';

  Future<void> _openMaps() => _launchExternalUrl(_mapsUrl);

  Future<void> _openEarth() => _launchExternalUrl(_earthUrl);

  String get _mapTypeLabel {
    return switch (_mapType) {
      MapType.normal => 'normal',
      MapType.satellite => 'satellite',
      MapType.terrain => 'terrain',
      MapType.hybrid => 'hybrid',
      _ => 'map',
    };
  }

  void _tagMapCenter() {
    setState(() {
      _mapTitle = 'Tagged spot';
      _locationState =
          'Tagged at ${_mapTarget.latitude.toStringAsFixed(5)}, ${_mapTarget.longitude.toStringAsFixed(5)}';
    });
  }

  void _setPinnedSpot(LatLng target) {
    setState(() {
      _mapTarget = target;
      _mapTitle = 'Pinned spot';
      _locationState =
          'Pinned at ${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
    });
  }

  void _syncMapCamera() {
    final position = _lastCameraPosition;
    if (position != null) {
      _mapTarget = position.target;
      _zoom = position.zoom;
      _bearing = position.bearing;
      _tilt = position.tilt;
    }
    setState(() {
      _locationState =
          'Map centred at ${_mapTarget.latitude.toStringAsFixed(5)}, ${_mapTarget.longitude.toStringAsFixed(5)}';
    });
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
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
    );
  }

  Widget _buildFallbackMap(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _MapGridPainter()),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined,
                    size: 56, color: Color(0xFF176B5B)),
                const SizedBox(height: 12),
                Text(
                  'Google Maps key missing from this build',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rebuild with GOOGLE_MAPS_API_KEY and enable Maps SDK for Android for com.carpcraft.intelligence.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSurface(BuildContext context) {
    final canUseGoogleMap = _googleMapsApiKey.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          child: canUseGoogleMap
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _mapTarget,
                    zoom: _zoom,
                    bearing: _bearing,
                    tilt: _tilt,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  mapType: _mapType,
                  compassEnabled: true,
                  liteModeEnabled: false,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: false,
                  minMaxZoomPreference: const MinMaxZoomPreference(5, 21),
                  myLocationButtonEnabled: false,
                  myLocationEnabled: _currentLocationActive &&
                      AppSettingsState.instance.preciseLocationEnabled,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  padding: const EdgeInsets.fromLTRB(0, 72, 0, 84),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected-spot'),
                      position: _mapTarget,
                      infoWindow: InfoWindow(title: _mapTitle),
                    ),
                  },
                  onLongPress: _setPinnedSpot,
                  onCameraMove: (position) {
                    _lastCameraPosition = position;
                  },
                  onCameraIdle: _syncMapCamera,
                )
              : _buildFallbackMap(context),
        ),
        Positioned(
          left: 12,
          top: 12,
          right: 12,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.layers_outlined, label: _mapTypeLabel),
              _InfoChip(
                  icon: Icons.zoom_in_outlined,
                  label: 'z${_zoom.toStringAsFixed(1)}'),
              _InfoChip(
                  icon: Icons.explore_outlined,
                  label: '${_bearing.toStringAsFixed(0)} deg'),
            ],
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: FilledButton.tonalIcon(
            onPressed: canUseGoogleMap ? _tagMapCenter : null,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Tag centre'),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Recenter',
                onPressed: canUseGoogleMap ? _recenterMap : null,
                icon: const Icon(Icons.center_focus_strong_outlined),
              ),
              const SizedBox(height: 8),
              IconButton.filledTonal(
                tooltip: 'Use current location',
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.gps_fixed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapTools() {
    final keyState = _googleMapsApiKey.isEmpty
        ? 'No Android Maps key in this build'
        : 'Android Maps key present in this build';
    return SectionCard(
      title: 'Map tools',
      icon: Icons.tune_outlined,
      children: [
        _CompactInfoLine(
          icon: _googleMapsApiKey.isEmpty
              ? Icons.key_off_outlined
              : Icons.key_outlined,
          text: keyState,
        ),
        const _CompactInfoLine(
          icon: Icons.android_outlined,
          text:
              'Google Cloud restriction must allow package com.carpcraft.intelligence and the release SHA-1 used to sign this APK.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<MapType>(
            segments: const [
              ButtonSegment(
                  value: MapType.hybrid,
                  icon: Icon(Icons.satellite_alt_outlined),
                  label: Text('Hybrid')),
              ButtonSegment(
                  value: MapType.satellite,
                  icon: Icon(Icons.public_outlined),
                  label: Text('Satellite')),
              ButtonSegment(
                  value: MapType.terrain,
                  icon: Icon(Icons.terrain_outlined),
                  label: Text('Terrain')),
              ButtonSegment(
                  value: MapType.normal,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Map')),
            ],
            selected: {_mapType},
            onSelectionChanged: (selection) {
              setState(() {
                _mapType = selection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _googleMapsApiKey.isEmpty ? null : _recenterMap,
              icon: const Icon(Icons.center_focus_strong_outlined),
              label: const Text('Recenter'),
            ),
            OutlinedButton.icon(
              onPressed: _googleMapsApiKey.isEmpty ? null : _tagMapCenter,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Tag centre'),
            ),
            OutlinedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Google Maps'),
            ),
            OutlinedButton.icon(
              onPressed: _openEarth,
              icon: const Icon(Icons.public_outlined),
              label: const Text('Google Earth'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationPanel() {
    return SectionCard(
      title: 'Location',
      icon: Icons.my_location_outlined,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: AppSettingsState.instance.preciseLocationEnabled,
          onChanged: (value) {
            if (value) {
              _useCurrentLocation();
            } else {
              AppSettingsState.instance.setPreciseLocationEnabled(false);
              setState(() {
                _currentLocationActive = false;
                _locationState = 'Location off';
              });
            }
          },
          title: const Text('Precise GPS for this session'),
          subtitle: const Text(
              'Enabled only when you choose to use current location.'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(_mapTitle),
          subtitle: Text(
              '$_locationState. Precise location is only used when you choose it.'),
          trailing: IconButton(
            tooltip: 'Use current location',
            icon: const Icon(Icons.gps_fixed),
            onPressed: _useCurrentLocation,
          ),
        ),
      ],
    );
  }

  Widget _buildMappedEvidencePanel() {
    return const SectionCard(
      title: 'Mapped evidence',
      icon: Icons.layers_outlined,
      children: [
        _CompactInfoLine(
          icon: Icons.info_outline,
          text:
              'No live map evidence is saved yet. Tag the centre point or attach capture evidence to build this layer.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot map')),
      drawer: _buildNavigationDrawer(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 6, child: _buildMapSurface(context)),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMapTools(),
                    const SizedBox(height: 12),
                    _buildLocationPanel(),
                    const SizedBox(height: 12),
                    _buildMappedEvidencePanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9FB9A6).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
