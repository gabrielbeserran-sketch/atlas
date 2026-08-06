class AtlasAdvancedDashboardData {
  const AtlasAdvancedDashboardData({required this.geoAssets,required this.pastureRecords,required this.agricultureRecords,required this.geneticProfiles,required this.aiForecasts,required this.implementedBlocks});
  final int geoAssets,pastureRecords,agricultureRecords,geneticProfiles,aiForecasts;
  final List<String> implementedBlocks;
  factory AtlasAdvancedDashboardData.fromMap(Map<String,dynamic> m)=>AtlasAdvancedDashboardData(geoAssets:(m['geo_assets'] as num?)?.toInt()??0,pastureRecords:(m['pasture_records'] as num?)?.toInt()??0,agricultureRecords:(m['agriculture_records'] as num?)?.toInt()??0,geneticProfiles:(m['genetic_profiles'] as num?)?.toInt()??0,aiForecasts:(m['ai_forecasts'] as num?)?.toInt()??0,implementedBlocks:((m['implemented_blocks'] as List?)??const[]).map((e)=>e.toString()).toList());
}

class AtlasAiForecastData {
  const AtlasAiForecastData({required this.type,required this.score,required this.confidence,required this.prediction,required this.evidence,required this.recommendation});
  final String type,recommendation; final double score,confidence; final Map<String,dynamic> prediction; final List<String> evidence;
  factory AtlasAiForecastData.fromMap(Map<String,dynamic> m)=>AtlasAiForecastData(type:m['type']?.toString()??'',score:(m['score'] as num?)?.toDouble()??0,confidence:(m['confidence_percent'] as num?)?.toDouble()??0,prediction:Map<String,dynamic>.from((m['prediction'] as Map?)??const{}),evidence:((m['evidence'] as List?)??const[]).map((e)=>e.toString()).toList(),recommendation:m['recommendation']?.toString()??'');
}
