import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app.dart';
import '../../core/app_repository.dart';
import '../../core/mock_data.dart';
import '../../shared/carp_scaffold.dart';

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
              return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
            }
            return Column(
              children: [
                for (final venue in venues) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_outlined),
                      title: Text(venue.name),
                      subtitle: Text('${venue.locationLabel} | ${venue.sessionCount} sessions | ${venue.privacy}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.venueDetail),
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController(text: 'lake');
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _locationController.dispose();
    _rulesController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveVenue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue name is required.')));
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
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save venue to the API.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Venue',
      children: [
        SectionCard(
          title: 'Venue',
          icon: Icons.edit_note_outlined,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _typeController, decoration: const InputDecoration(labelText: 'Type')),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Approximate location label'),
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
            FilledButton.icon(
              onPressed: _saving ? null : _saveVenue,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Save venue'),
            ),
          ],
        ),
      ],
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
        TextField(decoration: InputDecoration(labelText: 'Wind exposure notes'), maxLines: 3),
        TextField(decoration: InputDecoration(labelText: 'Access notes'), maxLines: 2),
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
  static const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const LatLng _initialTarget = LatLng(52.3555, -1.1743);
  LatLng _mapTarget = _initialTarget;
  String _locationState = 'Location off';

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
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() {
        _locationState = 'Location not allowed';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
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
                        child: _SpotPin(label: 'Reedline', icon: Icons.grass_outlined),
                      ),
                      const Positioned(
                        right: 42,
                        bottom: 70,
                        child: _SpotPin(label: 'Gravel bar', icon: Icons.terrain_outlined),
                      ),
                      const Center(
                        child: Icon(Icons.map_outlined, size: 56, color: Color(0xFF176B5B)),
                      ),
                    ],
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: _mapTarget, zoom: 18),
                    mapType: MapType.hybrid,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: _locationState == 'Current location active',
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected-spot'),
                        position: _mapTarget,
                        infoWindow: const InfoWindow(title: 'Selected spot'),
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
              title: Text(_locationState),
              subtitle: const Text('Precise location is only used when you choose it.'),
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
            Text('Depth, substrate, feature type and privacy level will attach to each spot.'),
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
