class MockVenue {
  const MockVenue({
    required this.id,
    required this.name,
    required this.locationLabel,
    required this.sessionCount,
    required this.privacy,
    this.type = 'unknown',
    this.approximateLatitude,
    this.approximateLongitude,
    this.acreage,
    this.rulesNotes,
    this.stockNotes,
  });

  final String id;
  final String name;
  final String locationLabel;
  final int sessionCount;
  final String privacy;
  final String type;
  final double? approximateLatitude;
  final double? approximateLongitude;
  final double? acreage;
  final String? rulesNotes;
  final String? stockNotes;

  factory MockVenue.fromJson(Map<String, dynamic> json) {
    return MockVenue(
      id: json['id'] as String? ?? 'unknown-venue',
      name: json['name'] as String? ?? 'Unnamed venue',
      locationLabel:
          json['location_label'] as String? ?? 'Approximate location only',
      sessionCount: _intValue(json['session_count']),
      privacy: _titleCase(json['privacy_level'] as String? ?? 'private'),
      type: json['type'] as String? ?? 'unknown',
      approximateLatitude: _doubleValue(json['approximate_latitude']),
      approximateLongitude: _doubleValue(json['approximate_longitude']),
      acreage: _doubleValue(json['acreage']),
      rulesNotes: json['rules_notes'] as String?,
      stockNotes: json['stock_notes'] as String?,
    );
  }
}

class MockVenueIntelligence {
  const MockVenueIntelligence({
    required this.query,
    required this.matchedKey,
    required this.confidenceScore,
    required this.suggestedVenue,
    required this.summary,
    required this.connectorStatuses,
    required this.swims,
    required this.mapAssets,
    required this.newsItems,
    required this.catchReports,
    required this.sourceEvidence,
    required this.licensingNotes,
    required this.dataGaps,
    required this.ethicalWarnings,
    this.externalPlace,
    this.weather,
  });

  final String query;
  final String matchedKey;
  final int confidenceScore;
  final MockVenue suggestedVenue;
  final String summary;
  final MockVenueExternalPlace? externalPlace;
  final List<MockVenueConnectorStatus> connectorStatuses;
  final List<MockVenueSwimIntelligence> swims;
  final List<MockVenueMapAsset> mapAssets;
  final List<MockVenueNewsItem> newsItems;
  final List<MockVenueNewsItem> catchReports;
  final List<MockVenueSourceEvidence> sourceEvidence;
  final List<String> licensingNotes;
  final List<String> dataGaps;
  final List<String> ethicalWarnings;
  final MockVenueWeather? weather;

  factory MockVenueIntelligence.fromJson(Map<String, dynamic> json) {
    final suggestedVenue = json['suggested_venue'];
    return MockVenueIntelligence(
      query: json['query'] as String? ?? '',
      matchedKey: json['matched_key'] as String? ?? 'unknown',
      confidenceScore: _intValue(json['confidence_score']),
      suggestedVenue: suggestedVenue is Map<String, dynamic>
          ? MockVenue.fromJson(suggestedVenue)
          : const MockVenue(
              id: 'unknown-venue',
              name: 'Unnamed venue',
              locationLabel: 'Approximate location only',
              sessionCount: 0,
              privacy: 'Private',
            ),
      summary: json['summary'] as String? ?? 'No grounded summary returned.',
      externalPlace: json['external_place'] is Map<String, dynamic>
          ? MockVenueExternalPlace.fromJson(
              json['external_place'] as Map<String, dynamic>)
          : null,
      connectorStatuses: _modelList(
          json['connector_statuses'], MockVenueConnectorStatus.fromJson),
      swims: _modelList(json['swims'], MockVenueSwimIntelligence.fromJson),
      mapAssets: _modelList(json['map_assets'], MockVenueMapAsset.fromJson),
      newsItems: _modelList(json['news_items'], MockVenueNewsItem.fromJson),
      catchReports:
          _modelList(json['catch_reports'], MockVenueNewsItem.fromJson),
      sourceEvidence:
          _modelList(json['source_evidence'], MockVenueSourceEvidence.fromJson),
      licensingNotes: _stringList(json['licensing_notes']),
      dataGaps: _stringList(json['data_gaps']),
      ethicalWarnings: _stringList(json['ethical_warnings']),
      weather: json['weather'] is Map<String, dynamic>
          ? MockVenueWeather.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MockFisheryProfileSection {
  const MockFisheryProfileSection({
    required this.category,
    required this.title,
    required this.items,
    required this.sourceUrls,
    this.summary,
    this.confidence = 0,
  });

  final String category;
  final String title;
  final String? summary;
  final List<String> items;
  final List<String> sourceUrls;
  final int confidence;

  factory MockFisheryProfileSection.fromJson(Map<String, dynamic> json) {
    return MockFisheryProfileSection(
      category: json['category'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Section',
      summary: json['summary'] as String?,
      items: _stringList(json['items']),
      sourceUrls: _stringList(json['source_urls']),
      confidence: _intValue(json['confidence']),
    );
  }
}

class MockFisheryProfile {
  const MockFisheryProfile({
    required this.id,
    required this.displayName,
    required this.slug,
    required this.privacyLevel,
    required this.confidenceScore,
    required this.sections,
    required this.lakes,
    required this.sources,
    required this.mapAssets,
    this.locationLabel,
    this.approximateLatitude,
    this.approximateLongitude,
    this.description,
    this.costsNotes,
    this.howToBookNotes,
  });

  final String id;
  final String displayName;
  final String slug;
  final String? locationLabel;
  final double? approximateLatitude;
  final double? approximateLongitude;
  final String? description;
  final String? costsNotes;
  final String? howToBookNotes;
  final String privacyLevel;
  final int confidenceScore;
  final List<MockFisheryProfileSection> sections;
  final List<MockVenueSwimIntelligence> lakes;
  final List<MockVenueSourceEvidence> sources;
  final List<MockVenueMapAsset> mapAssets;

  factory MockFisheryProfile.fromJson(Map<String, dynamic> json) {
    return MockFisheryProfile(
      id: json['id'] as String? ?? 'fishery-profile',
      displayName: json['display_name'] as String? ?? 'Fishery profile',
      slug: json['slug'] as String? ?? 'fishery',
      locationLabel: json['location_label'] as String?,
      approximateLatitude: _doubleValue(json['approximate_latitude']),
      approximateLongitude: _doubleValue(json['approximate_longitude']),
      description: json['description'] as String?,
      costsNotes: json['costs_notes'] as String?,
      howToBookNotes: json['how_to_book_notes'] as String?,
      privacyLevel: _titleCase(json['privacy_level'] as String? ?? 'private'),
      confidenceScore: _intValue(json['confidence_score']),
      sections:
          _modelList(json['sections'], MockFisheryProfileSection.fromJson),
      lakes: _modelList(json['lakes'], MockVenueSwimIntelligence.fromJson),
      sources: _modelList(json['sources'], (source) {
        return MockVenueSourceEvidence(
          sourceName: source['source_name'] as String? ?? 'Source',
          sourceType: source['source_kind'] as String? ?? 'source',
          url: source['url'] as String? ?? '',
          title: source['title'] as String? ?? 'Source',
          summary: source['summary'] as String? ?? '',
          confidence: _intValue(source['confidence']),
          attributionRequired:
              source['attribution_required'] as bool? ?? true,
          usageNotes: source['data_rights_notes'] as String?,
        );
      }),
      mapAssets: _modelList(json['map_assets'], MockVenueMapAsset.fromJson),
    );
  }

  bool get hasCoordinates =>
      approximateLatitude != null && approximateLongitude != null;
}

class MockVenueExternalPlace {
  const MockVenueExternalPlace({
    required this.sourceName,
    required this.confidence,
    this.placeId,
    this.displayName,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.googleMapsUri,
    this.websiteUri,
  });

  final String sourceName;
  final String? placeId;
  final String? displayName;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUri;
  final String? websiteUri;
  final int confidence;

  factory MockVenueExternalPlace.fromJson(Map<String, dynamic> json) {
    return MockVenueExternalPlace(
      sourceName: json['source_name'] as String? ?? 'External place',
      placeId: json['place_id'] as String?,
      displayName: json['display_name'] as String?,
      formattedAddress: json['formatted_address'] as String?,
      latitude: _doubleValue(json['latitude']),
      longitude: _doubleValue(json['longitude']),
      googleMapsUri: json['google_maps_uri'] as String?,
      websiteUri: json['website_uri'] as String?,
      confidence: _intValue(json['confidence']),
    );
  }
}

class MockVenueConnectorStatus {
  const MockVenueConnectorStatus({
    required this.connectorName,
    required this.displayName,
    required this.status,
    required this.summary,
    required this.evidenceCount,
    required this.dataGaps,
  });

  final String connectorName;
  final String displayName;
  final String status;
  final String summary;
  final int evidenceCount;
  final List<String> dataGaps;

  factory MockVenueConnectorStatus.fromJson(Map<String, dynamic> json) {
    return MockVenueConnectorStatus(
      connectorName: json['connector_name'] as String? ?? 'connector',
      displayName: json['display_name'] as String? ?? 'Connector',
      status: json['status'] as String? ?? 'unknown',
      summary: json['summary'] as String? ?? '',
      evidenceCount: _intValue(json['evidence_count']),
      dataGaps: _stringList(json['data_gaps']),
    );
  }
}

class MockVenueWeather {
  const MockVenueWeather({
    required this.source,
    this.airTempC,
    this.pressureHpa,
    this.windSpeedMps,
    this.windDirectionDegrees,
    this.rainfallMm,
    this.humidityPercent,
    this.dataGaps = const [],
  });

  final String source;
  final double? airTempC;
  final double? pressureHpa;
  final double? windSpeedMps;
  final double? windDirectionDegrees;
  final double? rainfallMm;
  final double? humidityPercent;
  final List<String> dataGaps;

  factory MockVenueWeather.fromJson(Map<String, dynamic> json) {
    return MockVenueWeather(
      source: json['source'] as String? ?? 'unknown',
      airTempC: _doubleValue(json['air_temp_c']),
      pressureHpa: _doubleValue(json['pressure_hpa']),
      windSpeedMps: _doubleValue(json['wind_speed_mps']),
      windDirectionDegrees: _doubleValue(json['wind_direction_degrees']),
      rainfallMm: _doubleValue(json['rainfall_mm']),
      humidityPercent: _doubleValue(json['humidity_percent']),
      dataGaps: _stringList(json['data_gaps']),
    );
  }
}

class MockWeatherCondition {
  const MockWeatherCondition({
    required this.source,
    required this.providerCount,
    required this.condition,
    required this.dataGaps,
    required this.approximationNotes,
    this.airTempC,
    this.approxSurfaceTempC,
    this.approxSurfaceTempConfidence = 0,
    this.pressureHpa,
    this.windSpeedMps,
    this.windDirectionDegrees,
    this.windDirectionLabel,
    this.rainfallMm,
    this.rainfallRateMmH,
    this.precipitationIntensity,
    this.cloudCoverPercent,
    this.humidityPercent,
  });

  final String source;
  final int providerCount;
  final String condition;
  final double? airTempC;
  final double? approxSurfaceTempC;
  final int approxSurfaceTempConfidence;
  final double? pressureHpa;
  final double? windSpeedMps;
  final double? windDirectionDegrees;
  final String? windDirectionLabel;
  final double? rainfallMm;
  final double? rainfallRateMmH;
  final String? precipitationIntensity;
  final int? cloudCoverPercent;
  final int? humidityPercent;
  final List<String> dataGaps;
  final List<String> approximationNotes;

  factory MockWeatherCondition.fromJson(Map<String, dynamic> json) {
    return MockWeatherCondition(
      source: json['source'] as String? ?? 'multi_provider',
      providerCount: _intValue(json['provider_count']),
      condition: json['condition'] as String? ?? 'unknown',
      airTempC: _doubleValue(json['air_temp_c']),
      approxSurfaceTempC: _doubleValue(json['approx_surface_temp_c']),
      approxSurfaceTempConfidence:
          _intValue(json['approx_surface_temp_confidence']),
      pressureHpa: _doubleValue(json['pressure_hpa']),
      windSpeedMps: _doubleValue(json['wind_speed_mps']),
      windDirectionDegrees: _doubleValue(json['wind_direction_degrees']),
      windDirectionLabel: json['wind_direction_label'] as String?,
      rainfallMm: _doubleValue(json['rainfall_mm']),
      rainfallRateMmH: _doubleValue(json['rainfall_rate_mm_h']),
      precipitationIntensity: json['precipitation_intensity'] as String?,
      cloudCoverPercent: json['cloud_cover_percent'] == null
          ? null
          : _intValue(json['cloud_cover_percent']),
      humidityPercent: json['humidity_percent'] == null
          ? null
          : _intValue(json['humidity_percent']),
      dataGaps: _stringList(json['data_gaps']),
      approximationNotes: _stringList(json['approximation_notes']),
    );
  }
}

class MockVenueSourceEvidence {
  const MockVenueSourceEvidence({
    required this.sourceName,
    required this.sourceType,
    required this.url,
    required this.title,
    required this.summary,
    required this.confidence,
    this.attributionRequired = false,
    this.usageNotes,
  });

  final String sourceName;
  final String sourceType;
  final String url;
  final String title;
  final String summary;
  final int confidence;
  final bool attributionRequired;
  final String? usageNotes;

  factory MockVenueSourceEvidence.fromJson(Map<String, dynamic> json) {
    return MockVenueSourceEvidence(
      sourceName: json['source_name'] as String? ?? 'Unknown source',
      sourceType: json['source_type'] as String? ?? 'unknown',
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled source',
      summary: json['summary'] as String? ?? '',
      confidence: _intValue(json['confidence']),
      attributionRequired: json['attribution_required'] as bool? ?? false,
      usageNotes: json['usage_notes'] as String?,
    );
  }
}

class MockVenueMapAsset {
  const MockVenueMapAsset({
    required this.title,
    required this.url,
    required this.assetType,
    this.licenseStatus = 'link_only',
    this.cacheAllowed = false,
    this.attribution,
    this.notes,
  });

  final String title;
  final String url;
  final String assetType;
  final String licenseStatus;
  final bool cacheAllowed;
  final String? attribution;
  final String? notes;

  factory MockVenueMapAsset.fromJson(Map<String, dynamic> json) {
    return MockVenueMapAsset(
      title: json['title'] as String? ?? 'Map asset',
      url: json['url'] as String? ?? '',
      assetType: json['asset_type'] as String? ?? 'map',
      licenseStatus: json['license_status'] as String? ?? 'link_only',
      cacheAllowed: json['cache_allowed'] as bool? ?? false,
      attribution: json['attribution'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class MockVenueNewsItem {
  const MockVenueNewsItem({
    required this.title,
    required this.summary,
    required this.url,
    required this.sourceName,
    this.publishedOn,
  });

  final String title;
  final String summary;
  final String url;
  final String sourceName;
  final String? publishedOn;

  factory MockVenueNewsItem.fromJson(Map<String, dynamic> json) {
    return MockVenueNewsItem(
      title: json['title'] as String? ?? 'Public update',
      summary: json['summary'] as String? ?? '',
      url: json['url'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? 'Unknown source',
      publishedOn: json['published_on'] as String?,
    );
  }
}

class MockVenueSwimIntelligence {
  const MockVenueSwimIntelligence({
    required this.name,
    required this.sourceUrl,
    this.acreage,
    this.swimCount,
    this.stockNotes,
    this.featureNotes,
    this.depthMapUrl,
  });

  final String name;
  final String sourceUrl;
  final double? acreage;
  final int? swimCount;
  final String? stockNotes;
  final String? featureNotes;
  final String? depthMapUrl;

  factory MockVenueSwimIntelligence.fromJson(Map<String, dynamic> json) {
    return MockVenueSwimIntelligence(
      name: json['name'] as String? ?? 'Unnamed lake or swim',
      sourceUrl: json['source_url'] as String? ?? '',
      acreage: _doubleValue(json['acreage']),
      swimCount:
          json['swim_count'] == null ? null : _intValue(json['swim_count']),
      stockNotes: json['stock_notes'] as String?,
      featureNotes: json['feature_notes'] as String?,
      depthMapUrl: json['depth_map_url'] as String?,
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
    final biteOpportunity =
        ((locationScore + feedingScore + presentationScore) / 3).round();
    return MockRecommendation(
      biteOpportunity: biteOpportunity,
      confidence: _intValue(json['confidence_score']),
      zone: json['recommended_zone'] as String? ??
          'Best evidenced water available',
      layer: json['recommended_depth_or_layer'] as String? ?? 'Unknown layer',
      tactic: json['recommended_tactic'] as String? ??
          'Gather more evidence before committing.',
      baiting: json['recommended_baiting_level'] as String? ?? 'moderate',
      why: _stringList(json['evidence_summary']),
      dataGaps: _stringList(json['data_gaps']),
      alternativePlan: json['alternative_plan'] as String? ??
          'Keep one option mobile and review outcomes.',
      fishWelfareWarning: json['fish_welfare_warning'] as String?,
    );
  }
}

class MockIntelligenceBrief {
  const MockIntelligenceBrief({
    required this.headline,
    required this.confidenceScore,
    required this.recommendations,
    required this.evidence,
    required this.dataGaps,
    required this.safetyWarnings,
    required this.noGuaranteeNotice,
  });

  final String headline;
  final int confidenceScore;
  final List<String> recommendations;
  final List<String> evidence;
  final List<String> dataGaps;
  final List<String> safetyWarnings;
  final String noGuaranteeNotice;

  factory MockIntelligenceBrief.fromJson(Map<String, dynamic> json) {
    final evidenceItems = json['evidence'];
    return MockIntelligenceBrief(
      headline: json['headline'] as String? ?? 'Grounded brief',
      confidenceScore: _intValue(json['confidence_score']),
      recommendations: _stringList(json['recommendations']),
      evidence: evidenceItems is List
          ? evidenceItems
              .whereType<Map>()
              .map((item) => item['summary'])
              .whereType<String>()
              .toList()
          : const [],
      dataGaps: _stringList(json['data_gaps']),
      safetyWarnings: _stringList(json['safety_warnings']),
      noGuaranteeNotice: json['no_guarantee_notice'] as String? ??
          'This is a source-grounded watercraft brief, not a catch prediction or guarantee.',
    );
  }
}

class MockProviderStatus {
  const MockProviderStatus({
    required this.providerName,
    required this.configured,
    required this.summary,
    required this.dataGaps,
  });

  final String providerName;
  final bool configured;
  final String summary;
  final List<String> dataGaps;

  factory MockProviderStatus.fromJson(Map<String, dynamic> json) {
    return MockProviderStatus(
      providerName: json['provider_name'] as String? ?? 'Provider',
      configured: json['configured'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      dataGaps: _stringList(json['data_gaps']),
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

final mockFisheryProfiles = [
  MockFisheryProfile(
    id: 'fishery-linear-demo',
    displayName: 'Linear Fisheries Oxford',
    slug: 'linear-fisheries',
    locationLabel: 'B4449 near Stanton Harcourt, OX29 7QF',
    approximateLatitude: 51.74778,
    approximateLongitude: -1.44076,
    description:
        'Offline demo profile. Seed the catalogue after signing in for live source-bound data.',
    costsNotes:
        'General day-ticket and selected online-booked waters. Verify current official prices.',
    howToBookNotes: 'Selected waters use Catch/GoCatch; verify before travel.',
    privacyLevel: 'Private',
    confidenceScore: 88,
    sections: [
      const MockFisheryProfileSection(
        category: 'access',
        title: 'Access, opening times and gates',
        items: [
          '24-hour fishing with locked overnight gates.',
          'Use the early-arrival car park during lock-up.',
        ],
        sourceUrls: ['https://www.linear-fisheries.co.uk/'],
        confidence: 80,
      ),
      const MockFisheryProfileSection(
        category: 'facilities',
        title: 'Facilities',
        items: ['Showers and toilets', 'Drinking water', 'Porta loos'],
        sourceUrls: ['https://www.linear-fisheries.co.uk/'],
        confidence: 75,
      ),
    ],
    lakes: mockVenueIntelligenceLinear.swims,
    sources: mockVenueIntelligenceLinear.sourceEvidence,
    mapAssets: mockVenueIntelligenceLinear.mapAssets,
  ),
  MockFisheryProfile(
    id: 'fishery-embryo-demo',
    displayName: 'Embryo Norton Disney',
    slug: 'embryo-norton-disney',
    locationLabel: 'Swinderby Road / Butt Lane, Norton Disney, LN6 9QH',
    approximateLatitude: 53.123845,
    approximateLongitude: -0.675704,
    description:
        'Offline demo profile. Seed the catalogue after signing in for live source-bound data.',
    costsNotes: 'Day and 24-hour tickets; verify current official prices.',
    howToBookNotes: 'Report to the lodge on arrival.',
    privacyLevel: 'Private',
    confidenceScore: 92,
    sections: [
      const MockFisheryProfileSection(
        category: 'access',
        title: 'Access, opening times and gates',
        items: [
          'Report to the lodge on arrival.',
          'Cashless card payment site.',
        ],
        sourceUrls: ['https://www.embryoangling.org/norton-disney/'],
        confidence: 85,
      ),
      const MockFisheryProfileSection(
        category: 'rules',
        title: 'Rules and fish care',
        items: ['Take litter home', 'Fishery-provided nets, mats and slings'],
        sourceUrls: ['https://www.embryoangling.org/norton-disney/'],
        confidence: 85,
      ),
    ],
    lakes: mockVenueIntelligenceEmbryo.swims,
    sources: mockVenueIntelligenceEmbryo.sourceEvidence,
    mapAssets: mockVenueIntelligenceEmbryo.mapAssets,
  ),
];

const mockVenueIntelligenceLinear = MockVenueIntelligence(
  query: 'Linear Fisheries',
  matchedKey: 'linear-fisheries',
  confidenceScore: 88,
  suggestedVenue: MockVenue(
    id: 'linear-fisheries-oxford',
    name: 'Linear Fisheries Oxford',
    locationLabel: 'B4449 near Stanton Harcourt, OX29 7QF',
    sessionCount: 0,
    privacy: 'Private',
    type: 'day_ticket',
    approximateLatitude: 51.74778,
    approximateLongitude: -1.44076,
    stockNotes:
        'Official source describes multiple day-ticket and syndicate carp waters.',
    rulesNotes:
        'Check official Linear rules and booking requirements before fishing.',
  ),
  summary:
      'Official Linear Fisheries pages provide the venue, map, rules and latest-catch spine for a first test pack.',
  externalPlace: null,
  connectorStatuses: [
    MockVenueConnectorStatus(
      connectorName: 'google_places',
      displayName: 'Google Places',
      status: 'not_configured',
      summary: 'Backend Places enrichment needs a server-side Places key.',
      evidenceCount: 0,
      dataGaps: ['Set GOOGLE_PLACES_API_KEY to test live Places enrichment.'],
    ),
    MockVenueConnectorStatus(
      connectorName: 'catch_gocatch',
      displayName: 'Catch / GoCatch',
      status: 'partner_required',
      summary:
          'Partner/API access is required for live booking and catch-report import.',
      evidenceCount: 1,
      dataGaps: ['Use official partner access or fishery-approved links.'],
    ),
    MockVenueConnectorStatus(
      connectorName: 'swimbooker',
      displayName: 'swimbooker',
      status: 'manual_directory',
      summary:
          'Manual source links are supported until an official API is configured.',
      evidenceCount: 1,
      dataGaps: ['No public Swimbooker API is configured.'],
    ),
    MockVenueConnectorStatus(
      connectorName: 'facebook_groups',
      displayName: 'Facebook groups',
      status: 'blocked_by_policy',
      summary: 'Group scraping/import is disabled.',
      evidenceCount: 0,
      dataGaps: [
        'Use explicit user-provided links or fishery-owned public pages only.'
      ],
    ),
  ],
  weather: MockVenueWeather(
      source: 'offline_demo',
      airTempC: 17.8,
      pressureHpa: 1008.8,
      windSpeedMps: 3.0),
  swims: [
    MockVenueSwimIntelligence(
        name: 'Brasenose One',
        sourceUrl:
            'https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start'),
    MockVenueSwimIntelligence(
        name: 'Hunts Corner Lake',
        sourceUrl:
            'https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start'),
    MockVenueSwimIntelligence(
        name: 'Unity Lake',
        sourceUrl:
            'https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start'),
    MockVenueSwimIntelligence(
        name: 'Tar Farm Lake No. 5',
        sourceUrl:
            'https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start'),
  ],
  mapAssets: [
    MockVenueMapAsset(
      title: 'Linear Fisheries site map',
      url: 'https://www.linear-fisheries.co.uk/index.cfm?fuseaction=main.map',
      assetType: 'official_site_map',
      licenseStatus: 'source_link_only_pending_permission',
      cacheAllowed: false,
      attribution: 'Linear Fisheries',
      notes: 'Source link only until map-image licensing is reviewed.',
    ),
  ],
  newsItems: [
    MockVenueNewsItem(
      title: 'Catch booking reference',
      summary:
          'Linear links selected bookings through the GoCatch/Catch platform.',
      url: 'https://www.linear-fisheries.co.uk/',
      sourceName: 'Linear Fisheries',
    ),
  ],
  catchReports: [
    MockVenueNewsItem(
      title: 'Latest-catches page',
      summary:
          'Public reports can inform context, but should not be treated as guaranteed current form.',
      url:
          'https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start',
      sourceName: 'Linear Fisheries',
    ),
  ],
  sourceEvidence: [
    MockVenueSourceEvidence(
      sourceName: 'Linear Fisheries',
      sourceType: 'official_fishery_site',
      url: 'https://www.linear-fisheries.co.uk/',
      title: 'Official Linear Fisheries homepage',
      summary: 'Official source for overview, rules, maps and latest catches.',
      confidence: 95,
    ),
    MockVenueSourceEvidence(
      sourceName: 'Catch / GoCatch',
      sourceType: 'booking_directory',
      url: 'https://www.gocatch.fish/',
      title: 'Catch venue platform',
      summary: 'Booking connector referenced by the official fishery site.',
      confidence: 75,
    ),
  ],
  licensingNotes: [
    'Public map assets are source links only until licensing review marks them cacheable.',
    'Linear Fisheries site map: cache blocked.',
  ],
  dataGaps: [
    'Swim boundaries and bathymetry are not normalized yet.',
    'Facebook/group data requires a permitted connector or user-provided links.',
  ],
  ethicalWarnings: [
    'Never disturb spawning fish.',
    'Follow fishery rules and fish care requirements.',
  ],
);

const mockVenueIntelligenceEmbryo = MockVenueIntelligence(
  query: 'Embryo Norton Disney',
  matchedKey: 'embryo-norton-disney',
  confidenceScore: 92,
  suggestedVenue: MockVenue(
    id: 'embryo-norton-disney',
    name: 'Embryo Norton Disney',
    locationLabel: 'Swinderby Road / Butt Lane, Norton Disney, LN6 9QH',
    sessionCount: 0,
    privacy: 'Private',
    type: 'day_ticket',
    approximateLatitude: 53.123845,
    approximateLongitude: -0.675704,
    acreage: 140,
    stockNotes:
        'Official source describes a six-lake complex with fish to 30lb+ in every lake.',
    rulesNotes:
        'Cashless site. Report to lodge. Swim choice is first come, first served.',
  ),
  summary:
      'Official Embryo pages expose lake sizes, swim counts, stock notes and public depth-map links.',
  externalPlace: null,
  connectorStatuses: [
    MockVenueConnectorStatus(
      connectorName: 'google_places',
      displayName: 'Google Places',
      status: 'not_configured',
      summary: 'Backend Places enrichment needs a server-side Places key.',
      evidenceCount: 0,
      dataGaps: ['Set GOOGLE_PLACES_API_KEY to test live Places enrichment.'],
    ),
    MockVenueConnectorStatus(
      connectorName: 'catch_gocatch',
      displayName: 'Catch / GoCatch',
      status: 'partner_required',
      summary:
          'Partner/API access is required for live booking and catch-report import.',
      evidenceCount: 1,
      dataGaps: ['Use official partner access or fishery-approved links.'],
    ),
    MockVenueConnectorStatus(
      connectorName: 'swimbooker',
      displayName: 'swimbooker',
      status: 'manual_directory',
      summary:
          'Manual source links are supported until an official API is configured.',
      evidenceCount: 1,
      dataGaps: ['No public Swimbooker API is configured.'],
    ),
    MockVenueConnectorStatus(
      connectorName: 'facebook_groups',
      displayName: 'Facebook groups',
      status: 'blocked_by_policy',
      summary: 'Group scraping/import is disabled.',
      evidenceCount: 0,
      dataGaps: [
        'Use explicit user-provided links or fishery-owned public pages only.'
      ],
    ),
  ],
  weather: MockVenueWeather(
      source: 'offline_demo',
      airTempC: 14.5,
      pressureHpa: 1009.2,
      windSpeedMps: 3.1),
  swims: [
    MockVenueSwimIntelligence(
      name: "Pettitt's Lake",
      acreage: 16,
      swimCount: 13,
      stockNotes: "Official page describes Pettitt's as the big-fish lake.",
      featureNotes: 'Official page references an egg-box lake bed in places.',
      depthMapUrl:
          'https://www.embryoangling.org/wp-content/uploads/2020/07/Pettitts_Depth_Map_Website.jpg',
      sourceUrl: 'https://www.embryoangling.org/venue/pettitts-lake/',
    ),
    MockVenueSwimIntelligence(
        name: "Holden's Lake",
        acreage: 11,
        sourceUrl: 'https://www.embryoangling.org/venue/holdens-lake/'),
    MockVenueSwimIntelligence(
        name: "Turner's Lake",
        acreage: 18,
        sourceUrl: 'https://www.embryoangling.org/venue/turners-lake/'),
    MockVenueSwimIntelligence(
        name: "Billy's Lake",
        acreage: 27,
        sourceUrl: 'https://www.embryoangling.org/venue/billys-lake/'),
  ],
  mapAssets: [
    MockVenueMapAsset(
      title: "Pettitt's Lake depth map",
      url:
          'https://www.embryoangling.org/wp-content/uploads/2020/07/Pettitts_Depth_Map_Website.jpg',
      assetType: 'official_depth_map',
      licenseStatus: 'source_link_only_pending_permission',
      cacheAllowed: false,
      attribution: 'Embryo Angling',
      notes:
          'Linked from the official Embryo page; cache only after licensing review.',
    ),
  ],
  newsItems: [
    MockVenueNewsItem(
      title: 'Norton Disney official page',
      summary:
          'Official venue overview, address, rules, booking and lake information.',
      url: 'https://www.embryoangling.org/norton-disney/',
      sourceName: 'Embryo Angling',
    ),
  ],
  catchReports: [
    MockVenueNewsItem(
      title: "Pettitt's named fish list",
      summary: 'Treat stock evidence separately from current catch form.',
      url: 'https://www.embryoangling.org/venue/pettitts-lake/',
      sourceName: 'Embryo Angling',
    ),
  ],
  sourceEvidence: [
    MockVenueSourceEvidence(
      sourceName: 'Embryo Angling',
      sourceType: 'official_fishery_site',
      url: 'https://www.embryoangling.org/norton-disney/',
      title: 'Official Norton Disney overview',
      summary:
          'Official source for complex overview, address, prices, rules, lake list and stock notes.',
      confidence: 95,
    ),
    MockVenueSourceEvidence(
      sourceName: 'Embryo Angling',
      sourceType: 'official_depth_map',
      url: 'https://www.embryoangling.org/venue/pettitts-lake/',
      title: "Pettitt's Lake depth-map page",
      summary: 'Official page links a high-resolution depth map.',
      confidence: 95,
    ),
  ],
  licensingNotes: [
    'Public map assets are source links only until licensing review marks them cacheable.',
    "Pettitt's Lake depth map: cache blocked.",
  ],
  dataGaps: [
    'Facebook and Instagram updates should not be scraped without permission.',
    'Depth maps need licensing review before caching copies inside the app.',
  ],
  ethicalWarnings: [
    'Never disturb spawning fish.',
    'Follow fishery rules and fish care requirements.',
  ],
);

const mockRecommendation = MockRecommendation(
  biteOpportunity: 62,
  confidence: 50,
  zone: 'Windward reedline',
  layer: 'Upper third near inflow water',
  tactic:
      'Keep one rod mobile and work from fresh shows before committing bait.',
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
  alternativePlan:
      'If the move produces only liners, adjust depth or presentation before adding bait.',
);

const mockWeatherCondition = MockWeatherCondition(
  source: 'offline_demo',
  providerCount: 2,
  condition: 'partly_cloudy',
  airTempC: 17.8,
  approxSurfaceTempC: 17.9,
  approxSurfaceTempConfidence: 65,
  pressureHpa: 1008.8,
  windSpeedMps: 3.2,
  windDirectionDegrees: 220,
  windDirectionLabel: 'SW',
  rainfallMm: 0,
  precipitationIntensity: 'none',
  cloudCoverPercent: 42,
  humidityPercent: 74,
  dataGaps: [
    'Use a thermometer reading when surface temperature matters for decisions.',
  ],
  approximationNotes: [
    'Approximate surface temperature is inferred from air, cloud, wind and rain; it is not a measured water reading.',
  ],
);

const mockIntelligenceBrief = MockIntelligenceBrief(
  headline: 'Grounded live-session brief',
  confidenceScore: 52,
  recommendations: [
    'Check water pushed by the SW wind first, then validate with shows or liners before committing bait.',
    'On silt, record lead feel and favour presentations that avoid burying the hook bait.',
    'Where weed is present, mark clear presentation pockets and record any cleaned-off rigs.',
  ],
  evidence: [
    'User observations: two shows at 70-80 yards off the reedline; one liner on the middle rod.',
    'Bottom notes: gravel, silt.',
  ],
  dataGaps: [
    'Live weather has not been attached to this session.',
    'No photos, annotated maps or rig/catch captures are attached yet.',
  ],
  safetyWarnings: [
    'Never disturb spawning fish.',
    'Follow current fishery rules, fish care requirements and local law.',
  ],
  noGuaranteeNotice:
      'This is a source-grounded watercraft brief, not a catch prediction or guarantee.',
);

const mockAnglingAIStatus = MockProviderStatus(
  providerName: 'AnglingAI',
  configured: false,
  summary:
      'Set ANGLINGAI_API_KEY to enable optional AnglingAI venue, weather and vision enrichment.',
  dataGaps: ['No AnglingAI API key is configured.'],
);

MockVenueIntelligence fallbackVenueIntelligence(String query) {
  final normalized = query.toLowerCase();
  if (normalized.contains('linear')) {
    return mockVenueIntelligenceLinear;
  }
  return mockVenueIntelligenceEmbryo;
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return 0;
}

double? _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

List<T> _modelList<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) {
    return [];
  }
  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
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
