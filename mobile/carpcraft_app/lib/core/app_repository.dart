import 'api_client.dart';
import 'models.dart';

class AppRepository {
  const AppRepository({this.api = const CarpCraftApiClient()});

  final CarpCraftApiClient api;

  Future<List<VenueSummary>> loadVenues() async {
    try {
      final items = await api.getList('/api/v1/venues');
      final venues = items
          .whereType<Map<String, dynamic>>()
          .map(VenueSummary.fromJson)
          .toList();
      return venues;
    } on CarpCraftApiException {
      return [];
    }
  }

  Future<VenueSummary> createVenue({
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
    return VenueSummary.fromJson(response);
  }

  Future<VenueIntelligenceReport> lookupVenueIntelligence(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await api
          .getMap('/api/v1/venues/intelligence/lookup?query=$encodedQuery');
      return VenueIntelligenceReport.fromJson(response);
    } on CarpCraftApiException {
      rethrow;
    }
  }

  Future<VenueIntelligenceReport> importVenueIntelligence(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await api.postMap(
          '/api/v1/venues/intelligence/import?query=$encodedQuery', {});
      return VenueIntelligenceReport.fromJson(response);
    } on CarpCraftApiException {
      rethrow;
    }
  }

  Future<List<FisheryProfile>> loadFisheryCatalogue() async {
    return searchFisheryCatalogue('');
  }

  Future<void> clearStaticFisheryCatalogueSeeds() async {
    try {
      await api.deleteMap('/api/v1/fishery-profiles/catalogue/static-seeds');
    } on CarpCraftApiException {
      return;
    }
  }

  Future<List<FisheryProfile>> seedFisheryCatalogue({String? query}) async {
    final normalized = query?.trim();
    if (normalized == null || normalized.isEmpty) {
      return [];
    }
    final path =
        '/api/v1/fishery-profiles/catalogue/seed?query=${Uri.encodeQueryComponent(normalized)}';
    final response = await api.postList(path, {});
    final profiles = response
        .whereType<Map<String, dynamic>>()
        .map(FisheryProfile.fromJson)
        .toList();
    return profiles;
  }

  Future<List<FisheryProfile>> researchFisheryCatalogue(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return loadFisheryCatalogue();
    }
    return seedFisheryCatalogue(query: normalized);
  }

  Future<List<FisheryProfile>> searchFisheryCatalogue(String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await api.getList(
        '/api/v1/fishery-profiles/catalogue/search?query=$encodedQuery');
    final profiles = response
        .whereType<Map<String, dynamic>>()
        .map(FisheryProfile.fromJson)
        .toList();
    return profiles;
  }

  Future<WeatherConditionSnapshot> loadLiveWeatherConditions({
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    final parameters = <String, String>{};
    if (latitude != null) {
      parameters['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      parameters['longitude'] = longitude.toString();
    }
    if (locationLabel != null && locationLabel.trim().isNotEmpty) {
      parameters['location_label'] = locationLabel.trim();
    }
    final query = Uri(queryParameters: parameters).query;
    final response =
        await api.getMap('/api/v1/weather-snapshots/live/conditions?$query');
    return WeatherConditionSnapshot.fromJson(response);
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
          'weed_condition':
              weedConditions.isEmpty ? 'unknown' : weedConditions.first,
        }
      ],
    };
    return api.postMap('/api/v1/capture-assets', body);
  }

  Future<IntelligenceBrief> loadExampleIntelligenceBrief() async {
    final response =
        await api.getMap('/api/v1/ai-intelligence/example-live-session');
    return IntelligenceBrief.fromJson(response);
  }

  Future<ProviderStatus> loadAnglingAIStatus() async {
    try {
      final response = await api.getMap('/api/v1/anglingai/status');
      return ProviderStatus.fromJson(response);
    } on CarpCraftApiException catch (error) {
      if (error.isUnauthorized) {
        return const ProviderStatus(
          providerName: 'AnglingAI',
          configured: false,
          summary:
              'Sign in with DIIAC Entra ID to check live AnglingAI provider status.',
          dataGaps: [
            'The production API rejected the request before provider status could be checked.',
          ],
        );
      }
      rethrow;
    }
  }

  Future<RecommendationSummary> generateRecommendation() async {
    final response = await api.postMap('/api/v1/recommendations/generate', {
      'venue_history_sessions': 0,
      'water_temp_c': null,
      'dissolved_oxygen_mg_l': null,
      'air_temp_c': null,
      'wind_speed_mps': null,
      'wind_has_pushed_hours': null,
      'weed_density': null,
      'angling_pressure_count': null,
      'observations': [],
      'liners_without_takes': false,
      'spawning_indicators': false,
    });
    return RecommendationSummary.fromJson(response);
  }

  /// Generates a recommendation from a live session's logged evidence
  /// (water readings, weather snapshot, observations, venue history and
  /// recent catches), persisting it for later outcome review.
  Future<RecommendationSummary> generateSessionPlan(String sessionId) async {
    final encoded = Uri.encodeComponent(sessionId);
    final response =
        await api.postMap('/api/v1/recommendations/session/$encoded/plan', {});
    return RecommendationSummary.fromJson(response);
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
