class MockVenue {
  const MockVenue({
    required this.id,
    required this.name,
    required this.locationLabel,
    required this.sessionCount,
    required this.privacy,
    this.type = 'unknown',
  });

  final String id;
  final String name;
  final String locationLabel;
  final int sessionCount;
  final String privacy;
  final String type;

  factory MockVenue.fromJson(Map<String, dynamic> json) {
    return MockVenue(
      id: json['id'] as String? ?? 'unknown-venue',
      name: json['name'] as String? ?? 'Unnamed venue',
      locationLabel: json['location_label'] as String? ?? 'Approximate location only',
      sessionCount: json['session_count'] as int? ?? 0,
      privacy: _titleCase(json['privacy_level'] as String? ?? 'private'),
      type: json['type'] as String? ?? 'unknown',
    );
  }
}

class MockRecommendation {
  const MockRecommendation({
    required this.biteOpportunity,
    required this.confidence,
    required this.zone,
    required this.layer,
    required this.tactic,
    required this.baiting,
    required this.why,
    required this.dataGaps,
    required this.alternativePlan,
    this.fishWelfareWarning,
  });

  final int biteOpportunity;
  final int confidence;
  final String zone;
  final String layer;
  final String tactic;
  final String baiting;
  final List<String> why;
  final List<String> dataGaps;
  final String alternativePlan;
  final String? fishWelfareWarning;

  factory MockRecommendation.fromJson(Map<String, dynamic> json) {
    final locationScore = _intValue(json['location_score']);
    final feedingScore = _intValue(json['feeding_window_score']);
    final presentationScore = _intValue(json['presentation_fit_score']);
    final biteOpportunity = ((locationScore + feedingScore + presentationScore) / 3).round();
    return MockRecommendation(
      biteOpportunity: biteOpportunity,
      confidence: _intValue(json['confidence_score']),
      zone: json['recommended_zone'] as String? ?? 'Best evidenced water available',
      layer: json['recommended_depth_or_layer'] as String? ?? 'Unknown layer',
      tactic: json['recommended_tactic'] as String? ?? 'Gather more evidence before committing.',
      baiting: json['recommended_baiting_level'] as String? ?? 'moderate',
      why: _stringList(json['evidence_summary']),
      dataGaps: _stringList(json['data_gaps']),
      alternativePlan: json['alternative_plan'] as String? ?? 'Keep one option mobile and review outcomes.',
      fishWelfareWarning: json['fish_welfare_warning'] as String?,
    );
  }
}

const mockVenues = [
  MockVenue(
    id: 'venue-willow-mere',
    name: 'Willow Mere',
    locationLabel: 'Approximate location only',
    sessionCount: 7,
    privacy: 'Private',
    type: 'lake',
  ),
  MockVenue(
    id: 'venue-north-pit',
    name: 'North Pit',
    locationLabel: 'Syndicate water',
    sessionCount: 18,
    privacy: 'Private',
    type: 'pit',
  ),
];

const mockRecommendation = MockRecommendation(
  biteOpportunity: 62,
  confidence: 50,
  zone: 'Windward reedline',
  layer: 'Upper third near inflow water',
  tactic: 'Keep one rod mobile and work from fresh shows before committing bait.',
  baiting: 'Light to moderate',
  why: [
    'Sustained wind has pushed into the bank for several hours.',
    'Two shows were logged away from current rods.',
    'Venue history is still below the confidence threshold.',
  ],
  dataGaps: [
    'Water temperature is missing.',
    'Dissolved oxygen has not been measured.',
  ],
  alternativePlan: 'If the move produces only liners, adjust depth or presentation before adding bait.',
);

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return 0;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
}
