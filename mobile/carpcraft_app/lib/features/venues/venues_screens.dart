import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app.dart';
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
  late Future<List<MockVenue>> _venues;

  @override
  void initState() {
    super.initState();
    _venues = _repository.loadVenues();
  }

  void _reload() {
    setState(() {
      _venues = _repository.loadVenues();
    });
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
            ],
          ),
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
        title: 'Maps and public updates',
        icon: Icons.public_outlined,
        children: [
          for (final asset in report.mapAssets)
            _SourceTile(
              icon: Icons.map_outlined,
              title: asset.title,
              subtitle: asset.notes ?? asset.url,
              trailing: asset.assetType,
            ),
          for (final item
              in [...report.newsItems, ...report.catchReports].take(5))
            _SourceTile(
              icon: Icons.feed_outlined,
              title: item.title,
              subtitle: item.summary,
              trailing: item.sourceName,
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
              subtitle: source.summary,
              trailing: source.sourceType,
            ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        ],
      ),
    );
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
  LatLng _mapTarget = _initialTarget;
  String _mapTitle = 'Selected spot';
  String _locationState = 'Location off';
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
      setState(() {
        _locationState = 'Location not allowed';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    setState(() {
      _mapTarget = LatLng(position.latitude, position.longitude);
      _locationState = 'Current location active';
    });
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
                        CameraPosition(target: _mapTarget, zoom: 18),
                    mapType: MapType.hybrid,
                    myLocationButtonEnabled: false,
                    myLocationEnabled:
                        _locationState == 'Current location active',
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected-spot'),
                        position: _mapTarget,
                        infoWindow: InfoWindow(title: _mapTitle),
                      ),
                    },
                    onCameraMove: (position) {
                      _mapTarget = position.target;
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Location',
          icon: Icons.my_location_outlined,
          children: [
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
            Text(
                'Depth, substrate, feature type and privacy level will attach to each spot.'),
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
