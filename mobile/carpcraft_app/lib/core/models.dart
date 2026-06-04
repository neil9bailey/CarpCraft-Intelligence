class VenueSummary {
  const VenueSummary({
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

  factory VenueSummary.fromJson(Map<String, dynamic> json) {
    return VenueSummary(
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

class VenueIntelligenceReport {
  const VenueIntelligenceReport({
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
  final VenueSummary suggestedVenue;
  final String summary;
  final VenueExternalPlace? externalPlace;
  final List<VenueConnectorStatus> connectorStatuses;
  final List<VenueSwimIntelligence> swims;
  final List<VenueMapAsset> mapAssets;
  final List<VenueNewsItem> newsItems;
  final List<VenueNewsItem> catchReports;
  final List<VenueSourceEvidence> sourceEvidence;
  final List<String> licensingNotes;
  final List<String> dataGaps;
  final List<String> ethicalWarnings;
  final VenueWeather? weather;

  factory VenueIntelligenceReport.fromJson(Map<String, dynamic> json) {
    final suggestedVenue = json['suggested_venue'];
    return VenueIntelligenceReport(
      query: json['query'] as String? ?? '',
      matchedKey: json['matched_key'] as String? ?? 'unknown',
      confidenceScore: _intValue(json['confidence_score']),
      suggestedVenue: suggestedVenue is Map<String, dynamic>
          ? VenueSummary.fromJson(suggestedVenue)
          : const VenueSummary(
              id: 'unknown-venue',
              name: 'Unnamed venue',
              locationLabel: 'Approximate location only',
              sessionCount: 0,
              privacy: 'Private',
            ),
      summary: json['summary'] as String? ?? 'No grounded summary returned.',
      externalPlace: json['external_place'] is Map<String, dynamic>
          ? VenueExternalPlace.fromJson(
              json['external_place'] as Map<String, dynamic>)
          : null,
      connectorStatuses:
          _modelList(json['connector_statuses'], VenueConnectorStatus.fromJson),
      swims: _modelList(json['swims'], VenueSwimIntelligence.fromJson),
      mapAssets: _modelList(json['map_assets'], VenueMapAsset.fromJson),
      newsItems: _modelList(json['news_items'], VenueNewsItem.fromJson),
      catchReports: _modelList(json['catch_reports'], VenueNewsItem.fromJson),
      sourceEvidence:
          _modelList(json['source_evidence'], VenueSourceEvidence.fromJson),
      licensingNotes: _stringList(json['licensing_notes']),
      dataGaps: _stringList(json['data_gaps']),
      ethicalWarnings: _stringList(json['ethical_warnings']),
      weather: json['weather'] is Map<String, dynamic>
          ? VenueWeather.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FisheryProfileSection {
  const FisheryProfileSection({
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

  factory FisheryProfileSection.fromJson(Map<String, dynamic> json) {
    return FisheryProfileSection(
      category: json['category'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Section',
      summary: json['summary'] as String?,
      items: _stringList(json['items']),
      sourceUrls: _stringList(json['source_urls']),
      confidence: _intValue(json['confidence']),
    );
  }
}

class FisheryProfile {
  const FisheryProfile({
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
  final List<FisheryProfileSection> sections;
  final List<VenueSwimIntelligence> lakes;
  final List<VenueSourceEvidence> sources;
  final List<VenueMapAsset> mapAssets;

  factory FisheryProfile.fromJson(Map<String, dynamic> json) {
    return FisheryProfile(
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
      sections: _modelList(json['sections'], FisheryProfileSection.fromJson),
      lakes: _modelList(json['lakes'], VenueSwimIntelligence.fromJson),
      sources: _modelList(json['sources'], (source) {
        return VenueSourceEvidence(
          sourceName: source['source_name'] as String? ?? 'Source',
          sourceType: source['source_kind'] as String? ?? 'source',
          url: source['url'] as String? ?? '',
          title: source['title'] as String? ?? 'Source',
          summary: source['summary'] as String? ?? '',
          confidence: _intValue(source['confidence']),
          attributionRequired: source['attribution_required'] as bool? ?? true,
          usageNotes: source['data_rights_notes'] as String?,
        );
      }),
      mapAssets: _modelList(json['map_assets'], VenueMapAsset.fromJson),
    );
  }

  bool get hasCoordinates =>
      approximateLatitude != null && approximateLongitude != null;
}

class VenueExternalPlace {
  const VenueExternalPlace({
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

  factory VenueExternalPlace.fromJson(Map<String, dynamic> json) {
    return VenueExternalPlace(
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

class VenueConnectorStatus {
  const VenueConnectorStatus({
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

  factory VenueConnectorStatus.fromJson(Map<String, dynamic> json) {
    return VenueConnectorStatus(
      connectorName: json['connector_name'] as String? ?? 'connector',
      displayName: json['display_name'] as String? ?? 'Connector',
      status: json['status'] as String? ?? 'unknown',
      summary: json['summary'] as String? ?? '',
      evidenceCount: _intValue(json['evidence_count']),
      dataGaps: _stringList(json['data_gaps']),
    );
  }
}

class VenueWeather {
  const VenueWeather({
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

  factory VenueWeather.fromJson(Map<String, dynamic> json) {
    return VenueWeather(
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

class WeatherConditionSnapshot {
  const WeatherConditionSnapshot({
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

  factory WeatherConditionSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherConditionSnapshot(
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

class VenueSourceEvidence {
  const VenueSourceEvidence({
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

  factory VenueSourceEvidence.fromJson(Map<String, dynamic> json) {
    return VenueSourceEvidence(
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

class VenueMapAsset {
  const VenueMapAsset({
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

  factory VenueMapAsset.fromJson(Map<String, dynamic> json) {
    return VenueMapAsset(
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

class VenueNewsItem {
  const VenueNewsItem({
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

  factory VenueNewsItem.fromJson(Map<String, dynamic> json) {
    return VenueNewsItem(
      title: json['title'] as String? ?? 'Public update',
      summary: json['summary'] as String? ?? '',
      url: json['url'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? 'Unknown source',
      publishedOn: json['published_on'] as String?,
    );
  }
}

class VenueSwimIntelligence {
  const VenueSwimIntelligence({
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

  factory VenueSwimIntelligence.fromJson(Map<String, dynamic> json) {
    return VenueSwimIntelligence(
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

class RecommendationSummary {
  const RecommendationSummary({
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

  factory RecommendationSummary.fromJson(Map<String, dynamic> json) {
    final locationScore = _intValue(json['location_score']);
    final feedingScore = _intValue(json['feeding_window_score']);
    final presentationScore = _intValue(json['presentation_fit_score']);
    final biteOpportunity =
        ((locationScore + feedingScore + presentationScore) / 3).round();
    return RecommendationSummary(
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

class IntelligenceBrief {
  const IntelligenceBrief({
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

  factory IntelligenceBrief.fromJson(Map<String, dynamic> json) {
    final evidenceItems = json['evidence'];
    return IntelligenceBrief(
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

class ProviderStatus {
  const ProviderStatus({
    required this.providerName,
    required this.configured,
    required this.summary,
    required this.dataGaps,
  });

  final String providerName;
  final bool configured;
  final String summary;
  final List<String> dataGaps;

  factory ProviderStatus.fromJson(Map<String, dynamic> json) {
    return ProviderStatus(
      providerName: json['provider_name'] as String? ?? 'Provider',
      configured: json['configured'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      dataGaps: _stringList(json['data_gaps']),
    );
  }
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
