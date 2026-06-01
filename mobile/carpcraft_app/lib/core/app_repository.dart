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
