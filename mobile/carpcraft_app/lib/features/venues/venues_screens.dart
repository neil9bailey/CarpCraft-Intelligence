import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/app_settings_state.dart';
import '../../core/app_repository.dart';
import '../../core/mock_data.dart';
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
  late Future<List<MockVenue>> _venues;
  late Future<List<MockFisheryProfile>> _catalogue;
  bool _catalogueBusy = false;

  @override
  void initState() {
    super.initState();
    _venues = _repository.loadVenues();
    _catalogue = _repository.searchFisheryCatalogue('');
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

  Future<void> _seedCatalogue() async {
    setState(() {
      _catalogueBusy = true;
    });
    try {
      final profiles = await _repository.seedFisheryCatalogue();
      if (mounted) {
        setState(() {
          _catalogue = Future.value(profiles);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Seeded ${profiles.length} fishery profiles.')));
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

  void _openFisheryMap(MockFisheryProfile profile) {
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
                  labelText: 'Search catalogued fisheries'),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchCatalogue(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _catalogueBusy ? null : _seedCatalogue,
                  icon: _catalogueBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Seed catalogue'),
                ),
                OutlinedButton.icon(
                  onPressed: _searchCatalogue,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<MockFisheryProfile>>(
              future: _catalogue,
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? mockFisheryProfiles;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  );
                }
                if (profiles.isEmpty) {
                  return const _CompactInfoLine(
                    icon: Icons.info_outline,
                    text: 'No private fishery profiles match this search.',
                  );
                }
                return Column(
                  children: [
                    for (final profile in profiles.take(5))
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
        FutureBuilder<List<MockVenue>>(
          future: _venues,
          builder: (context, snapshot) {
            final venues = snapshot.data ?? mockVenues;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()));
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
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.venueDetail),
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
  MockVenueIntelligence? _intelligence;
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

  void _applyIntelligence(MockVenueIntelligence intelligence) {
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No grounded venue intelligence found.')));
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not import venue intelligence.')));
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
                ActionChip(
                  avatar: const Icon(Icons.water_outlined, size: 18),
                  label: const Text('Linear'),
                  onPressed: _lookingUp
                      ? null
                      : () => _lookupVenue('Linear Fisheries'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.water_outlined, size: 18),
                  label: const Text('Norton Disney'),
                  onPressed: _lookingUp
                      ? null
                      : () => _lookupVenue('Embryo Norton Disney'),
                ),
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
      BuildContext context, MockVenueIntelligence report) {
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

  final MockFisheryProfile profile;
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
    return CarpScaffold(
      title: 'Willow Mere',
      actions: [
        IconButton(
          tooltip: 'Edit venue',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.editVenue),
        ),
      ],
      children: [
        const SectionCard(
          title: 'Private venue memory',
          icon: Icons.lock_outline,
          children: [
            Text('7 sessions, 1 catch, 3 blank intervals, 4 mapped spots.'),
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
    const swims = ['Reed Corner', 'Dam Wall', 'North Point'];
    return CarpScaffold(
      title: 'Swims',
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add swim',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.editSwim),
        child: const Icon(Icons.add_location_alt_outlined),
      ),
      children: [
        for (final swim in swims) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(swim),
              subtitle: const Text('Pressure and wind exposure private'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.spotMap),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
      _mapTarget = target;
      _locationState =
          'Current location active, accuracy ${position.accuracy.toStringAsFixed(0)} m';
    });
    await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: _zoom, bearing: _bearing, tilt: _tilt),
    ));
  }

  Future<void> _recenterMap() async {
    await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _mapTarget, zoom: _zoom, bearing: _bearing, tilt: _tilt),
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

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Spot map',
      children: [
        Container(
          height: 360,
          decoration: BoxDecoration(
            color: const Color(0xFFE6EFE8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8D9CE)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _googleMapsApiKey.isEmpty
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _MapGridPainter()),
                      ),
                      const Positioned(
                        left: 36,
                        top: 54,
                        child: _SpotPin(
                            label: 'Reedline', icon: Icons.grass_outlined),
                      ),
                      const Positioned(
                        right: 42,
                        bottom: 70,
                        child: _SpotPin(
                            label: 'Gravel bar', icon: Icons.terrain_outlined),
                      ),
                      const Center(
                        child: Icon(Icons.map_outlined,
                            size: 56, color: Color(0xFF176B5B)),
                      ),
                    ],
                  )
                : GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _mapTarget, zoom: _zoom),
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
                    mapToolbarEnabled: true,
                    zoomControlsEnabled: true,
                    minMaxZoomPreference: const MinMaxZoomPreference(5, 21),
                    myLocationButtonEnabled: false,
                    myLocationEnabled:
                        _locationState == 'Current location active',
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected-spot'),
                        position: _mapTarget,
                        infoWindow: InfoWindow(title: _mapTitle),
                      ),
                    },
                    onCameraMove: (position) {
                      _lastCameraPosition = position;
                    },
                    onCameraIdle: () {
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
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Map tools',
          icon: Icons.tune_outlined,
          children: [
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
            const SizedBox(height: 12),
            Wrap(
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
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
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
        ),
        const SizedBox(height: 12),
        const SectionCard(
          title: 'Mapped evidence',
          icon: Icons.layers_outlined,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SpotPin(label: 'Lake name', icon: Icons.label_outlined),
                _SpotPin(label: 'Swim tag', icon: Icons.place_outlined),
                _SpotPin(label: 'Depth map', icon: Icons.layers_outlined),
                _SpotPin(label: '22 wraps', icon: Icons.straighten_outlined),
                _SpotPin(label: '88 yards', icon: Icons.route_outlined),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SpotPin extends StatelessWidget {
  const _SpotPin({required this.label, required this.icon});

  final String label;
  final IconData icon;

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
