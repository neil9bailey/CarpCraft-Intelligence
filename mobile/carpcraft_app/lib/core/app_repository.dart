import 'api_client.dart';
import 'mock_data.dart';

class AppRepository {
  const AppRepository({this.api = const CarpCraftApiClient()});

  final CarpCraftApiClient api;

  Future<List<MockVenue>> loadVenues() async {
    try {
      final items = await api.getList('/api/v1/venues');
      final venues = items
          .whereType<Map<String, dynamic>>()
          .map(MockVenue.fromJson)
          .toList();
      return venues.isEmpty ? mockVenues : venues;
    } on CarpCraftApiException {
      return mockVenues;
    }
  }

  Future<MockVenue> createVenue({
    required String name,
    required String type,
    required String locationLabel,
    String? rulesNotes,
    String? stockNotes,
    double? approximateLatitude,
    double? approximateLongitude,
    double? acreage,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': type.isEmpty ? 'unknown' : type,
      'location_label':
          locationLabel.isEmpty ? 'Approximate location only' : locationLabel,
      'rules_notes': rulesNotes,
      'stock_notes': stockNotes,
      'privacy_level': 'private',
    };
    if (approximateLatitude != null && approximateLongitude != null) {
      body['approximate_latitude'] = approximateLatitude;
      body['approximate_longitude'] = approximateLongitude;
    }
    if (acreage != null) {
      body['acreage'] = acreage;
    }

    final response = await api.postMap('/api/v1/venues', body);
    return MockVenue.fromJson(response);
  }

  Future<MockVenueIntelligence> lookupVenueIntelligence(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await api
          .getMap('/api/v1/venues/intelligence/lookup?query=$encodedQuery');
      return MockVenueIntelligence.fromJson(response);
    } on CarpCraftApiException {
      return fallbackVenueIntelligence(query);
    }
  }

  Future<MockVenueIntelligence> importVenueIntelligence(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await api.postMap(
          '/api/v1/venues/intelligence/import?query=$encodedQuery', {});
      return MockVenueIntelligence.fromJson(response);
    } on CarpCraftApiException {
      final intelligence = fallbackVenueIntelligence(query);
      final venue = intelligence.suggestedVenue;
      await createVenue(
        name: venue.name,
        type: venue.type,
        locationLabel: venue.locationLabel,
        rulesNotes: venue.rulesNotes,
        stockNotes: venue.stockNotes,
        approximateLatitude: venue.approximateLatitude,
        approximateLongitude: venue.approximateLongitude,
        acreage: venue.acreage,
      );
      return intelligence;
    }
  }

  Future<List<MockFisheryProfile>> seedFisheryCatalogue() async {
    try {
      final response =
          await api.postList('/api/v1/fishery-profiles/catalogue/seed', {});
      final profiles = response
          .whereType<Map<String, dynamic>>()
          .map(MockFisheryProfile.fromJson)
          .toList();
      return profiles.isEmpty ? mockFisheryProfiles : profiles;
    } on CarpCraftApiException {
      return mockFisheryProfiles;
    }
  }

  Future<List<MockFisheryProfile>> searchFisheryCatalogue(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await api
          .getList('/api/v1/fishery-profiles/catalogue/search?query=$encodedQuery');
      final profiles = response
          .whereType<Map<String, dynamic>>()
          .map(MockFisheryProfile.fromJson)
          .toList();
      return profiles;
    } on CarpCraftApiException {
      final normalized = query.trim().toLowerCase();
      if (normalized.isEmpty) {
        return mockFisheryProfiles;
      }
      return mockFisheryProfiles.where((profile) {
        final haystack = [
          profile.displayName,
          profile.slug,
          profile.locationLabel ?? '',
          profile.description ?? '',
          ...profile.lakes.map((lake) => lake.name),
          ...profile.sections.map((section) => section.title),
          ...profile.sections.expand((section) => section.items),
        ].join(' ').toLowerCase();
        return haystack.contains(normalized);
      }).toList();
    }
  }

  Future<MockWeatherCondition> loadLiveWeatherConditions({
    double latitude = 51.74778,
    double longitude = -1.44076,
    String locationLabel = 'Linear Fisheries Oxford',
  }) async {
    try {
      final query = Uri(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'location_label': locationLabel,
      }).query;
      final response =
          await api.getMap('/api/v1/weather-snapshots/live/conditions?$query');
      return MockWeatherCondition.fromJson(response);
    } on CarpCraftApiException {
      return mockWeatherCondition;
    }
  }

  Future<Map<String, dynamic>> createCaptureAsset({
    required String category,
    required String fileUri,
    required String fileName,
    required String markerLabel,
    required double markerX,
    required double markerY,
    String? caption,
    double? distanceYards,
    double? distanceWraps,
    double? depthM,
    String bottomCondition = 'unknown',
    List<String> weedConditions = const ['unknown'],
    String algaeCondition = 'unknown',
    String? waterClarityNotes,
    String? rigNotes,
    String? baitNotes,
    bool publicContribution = false,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'file_uri': fileUri,
      'file_name': fileName,
      'caption': _blankToNull(caption),
      'privacy_level': 'private',
      'sharing_scope': publicContribution ? 'public' : 'private',
      'public_sharing_consent': publicContribution,
      'bottom_condition': bottomCondition,
      'weed_conditions': weedConditions,
      'algae_condition': algaeCondition,
      'water_clarity_notes': _blankToNull(waterClarityNotes),
      'depth_m': depthM,
      'distance_yards': distanceYards,
      'distance_wraps': distanceWraps,
      'rig_notes': _blankToNull(rigNotes),
      'bait_notes': _blankToNull(baitNotes),
      'source_device': 'android',
      'annotations': [
        {
          'annotation_type': 'marker',
          'label': markerLabel.isEmpty ? 'Spot marker' : markerLabel,
          'x1': markerX,
          'y1': markerY,
          'distance_yards': distanceYards,
          'distance_wraps': distanceWraps,
          'depth_m': depthM,
          'bottom_condition': bottomCondition,
          'weed_condition': weedConditions.isEmpty ? 'unknown' : weedConditions.first,
        }
      ],
    };
    try {
      return await api.postMap('/api/v1/capture-assets', body);
    } on CarpCraftApiException {
      return body;
    }
  }

  Future<MockIntelligenceBrief> loadExampleIntelligenceBrief() async {
    try {
      final response =
          await api.getMap('/api/v1/ai-intelligence/example-live-session');
      return MockIntelligenceBrief.fromJson(response);
    } on CarpCraftApiException {
      return mockIntelligenceBrief;
    }
  }

  Future<MockProviderStatus> loadAnglingAIStatus() async {
    try {
      final response = await api.getMap('/api/v1/anglingai/status');
      return MockProviderStatus.fromJson(response);
    } on CarpCraftApiException catch (error) {
      if (error.isUnauthorized) {
        return authRequiredAnglingAIStatus;
      }
      return mockAnglingAIStatus;
    }
  }

  Future<MockRecommendation> generateRecommendation() async {
    try {
      final response = await api.postMap('/api/v1/recommendations/generate', {
        'venue_history_sessions': 7,
        'water_temp_c': null,
        'dissolved_oxygen_mg_l': null,
        'air_temp_c': 24.0,
        'wind_speed_mps': 4.5,
        'wind_has_pushed_hours': 4,
        'weed_density': 6,
        'angling_pressure_count': 4,
        'observations': [
          {
            'observation_type': 'show',
            'count': 2,
            'away_from_current_rods': true,
          },
        ],
        'liners_without_takes': true,
        'spawning_indicators': false,
      });
      return MockRecommendation.fromJson(response);
    } on CarpCraftApiException {
      return mockRecommendation;
    }
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
