import 'api_client.dart';
import 'mock_data.dart';

class AppRepository {
  const AppRepository({this.api = const CarpCraftApiClient()});

  final CarpCraftApiClient api;

  Future<List<MockVenue>> loadVenues() async {
    try {
      final items = await api.getList('/api/v1/venues');
      final venues = items.whereType<Map<String, dynamic>>().map(MockVenue.fromJson).toList();
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
  }) async {
    final response = await api.postMap('/api/v1/venues', {
      'name': name,
      'type': type.isEmpty ? 'unknown' : type,
      'location_label': locationLabel.isEmpty ? 'Approximate location only' : locationLabel,
      'rules_notes': rulesNotes,
      'stock_notes': stockNotes,
      'privacy_level': 'private',
    });
    return MockVenue.fromJson(response);
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
