import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_repository.dart';
import '../../shared/carp_scaffold.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final AppRepository _repository = const AppRepository();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _markerController =
      TextEditingController(text: 'Spot marker');
  final TextEditingController _distanceYardsController =
      TextEditingController(text: '88');
  final TextEditingController _wrapsController =
      TextEditingController(text: '22');
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _rigController = TextEditingController();
  final TextEditingController _baitController = TextEditingController();
  final TextEditingController _waterClarityController = TextEditingController();

  XFile? _selectedImage;
  Offset _marker = const Offset(0.5, 0.5);
  String _category = 'swim';
  String _bottomCondition = 'unknown';
  String _algaeCondition = 'unknown';
  final Set<String> _weedConditions = {'unknown'};
  bool _publicContribution = false;
  bool _saving = false;

  static const _categories = {
    'location': 'Location',
    'swim': 'Swim',
    'lake_feature': 'Feature',
    'catch': 'Catch',
    'rig': 'Rig',
    'bait': 'Bait',
    'depth': 'Depth',
    'map': 'Map',
  };

  static const _bottomOptions = {
    'silt': 'Silt',
    'gravel': 'Gravel',
    'smooth_clay': 'Clay',
    'sand': 'Sand',
    'chod': 'Chod',
    'clear_hard': 'Hard',
    'unknown': 'Unknown',
  };

  static const _weedOptions = {
    'none': 'None',
    'silk_weed': 'Silk weed',
    'canadian_pond_weed': 'Canadian',
    'blanket_weed': 'Blanket',
    'milfoil': 'Milfoil',
    'hornwort': 'Hornwort',
    'lilies': 'Lilies',
    'reeds': 'Reeds',
    'mixed': 'Mixed',
    'unknown': 'Unknown',
  };

  static const _algaeOptions = {
    'none': 'None',
    'light_bloom': 'Light',
    'moderate_bloom': 'Moderate',
    'heavy_bloom': 'Heavy',
    'blue_green_suspected': 'Blue-green suspected',
    'unknown': 'Unknown',
  };

  @override
  void dispose() {
    _captionController.dispose();
    _markerController.dispose();
    _distanceYardsController.dispose();
    _wrapsController.dispose();
    _depthController.dispose();
    _rigController.dispose();
    _baitController.dispose();
    _waterClarityController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (image != null && mounted) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveCapture() async {
    final image = _selectedImage;
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a camera or gallery image.')));
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await _repository.createCaptureAsset(
        category: _category,
        fileUri: image.path,
        fileName: image.name,
        caption: _captionController.text.trim(),
        markerLabel: _markerController.text.trim(),
        markerX: _marker.dx,
        markerY: _marker.dy,
        distanceYards: _doubleFrom(_distanceYardsController),
        distanceWraps: _doubleFrom(_wrapsController),
        depthM: _doubleFrom(_depthController),
        bottomCondition: _bottomCondition,
        weedConditions: _weedConditions.toList(),
        algaeCondition: _algaeCondition,
        waterClarityNotes: _waterClarityController.text.trim(),
        rigNotes: _rigController.text.trim(),
        baitNotes: _baitController.text.trim(),
        publicContribution: _publicContribution,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_publicContribution
              ? 'Capture saved for review before sharing.'
              : 'Capture saved private.'),
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  double? _doubleFrom(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    return CarpScaffold(
      title: 'Capture',
      children: [
        SectionCard(
          title: 'Image evidence',
          icon: Icons.add_a_photo_outlined,
          children: [
            _imagePreview(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Files'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Capture details',
          icon: Icons.fact_check_outlined,
          children: [
            _chipGroup(_categories, _category,
                (value) => setState(() => _category = value)),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _markerController,
              decoration: const InputDecoration(labelText: 'Marker label'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _distanceYardsController,
                    decoration: const InputDecoration(labelText: 'Yards'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _wrapsController,
                    decoration: const InputDecoration(labelText: 'Wraps'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _depthController,
                    decoration: const InputDecoration(labelText: 'Depth m'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Watercraft',
          icon: Icons.grass_outlined,
          children: [
            Text('Bottom', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _chipGroup(_bottomOptions, _bottomCondition,
                (value) => setState(() => _bottomCondition = value)),
            const SizedBox(height: 12),
            Text('Weed', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _weedOptions.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _weedConditions.contains(entry.key),
                    onSelected: (selected) {
                      setState(() {
                        if (entry.key == 'unknown' || entry.key == 'none') {
                          _weedConditions
                            ..clear()
                            ..add(entry.key);
                        } else {
                          _weedConditions.remove('unknown');
                          _weedConditions.remove('none');
                          selected
                              ? _weedConditions.add(entry.key)
                              : _weedConditions.remove(entry.key);
                          if (_weedConditions.isEmpty) {
                            _weedConditions.add('unknown');
                          }
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Algae', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _chipGroup(_algaeOptions, _algaeCondition,
                (value) => setState(() => _algaeCondition = value)),
            const SizedBox(height: 12),
            TextField(
              controller: _waterClarityController,
              decoration:
                  const InputDecoration(labelText: 'Water clarity notes'),
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Rig and bait',
          icon: Icons.construction_outlined,
          children: [
            TextField(
              controller: _rigController,
              decoration: const InputDecoration(labelText: 'Rig notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baitController,
              decoration: const InputDecoration(labelText: 'Bait notes'),
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Sharing',
          icon: Icons.lock_outline,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Public profile contribution'),
              subtitle: const Text('Off keeps this capture private.'),
              value: _publicContribution,
              onChanged: (value) => setState(() {
                _publicContribution = value;
              }),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _saveCapture,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save capture'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _imagePreview() {
    final image = _selectedImage;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 260.0;
        return GestureDetector(
          onTapDown: image == null
              ? null
              : (details) {
                  setState(() {
                    _marker = Offset(
                      (details.localPosition.dx / width).clamp(0.0, 1.0),
                      (details.localPosition.dy / height).clamp(0.0, 1.0),
                    );
                  });
                },
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFE8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC8D9CE)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: image == null
                      ? const Center(
                          child: Icon(Icons.image_outlined,
                              size: 54, color: Color(0xFF176B5B)),
                        )
                      : Image.file(File(image.path), fit: BoxFit.cover),
                ),
                if (image != null)
                  Positioned(
                    left: (_marker.dx * width) - 14,
                    top: (_marker.dy * height) - 28,
                    child: const Icon(Icons.location_on,
                        size: 34, color: Color(0xFFC58B2B)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chipGroup(
    Map<String, String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in options.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => onSelected(entry.key),
          ),
      ],
    );
  }
}
