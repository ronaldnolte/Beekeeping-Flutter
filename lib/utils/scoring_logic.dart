class ScoringLogic {
  static const List<int> stormCodes = [95, 96, 99];

  static Map<String, dynamic> calculateWindowScore(List<dynamic> hours) {
    // hours should be List<HourlyForecast>
    // But to match the flexible input of the TS version, we'll type it securely next.
    if (hours.isEmpty) {
      return {'score': 0, 'details': {}};
    }

    // Calculate aggregates
    double sumTemp = 0;
    double maxWind = 0; // mph
    double maxPop = 0; // %
    double maxRainRate = 0; // inch or mm? Open-Meteo default is usually mm but code said > 0.5 (likely inches if manual? or mm?)
    // In TS: maxRainRate > 0.5 (unit unclear in TS default but wind was mph, temp F)
    // Open-Meteo URL in TS: &precipitation_unit=inch (wait, I need to check the URL)
    // TS URL: `current=...&temperature_unit=fahrenheit&wind_speed_unit=mph` 
    // Forecast URL: `&temperature_unit=fahrenheit&wind_speed_unit=mph` - NO precipitation_unit specified in TS line 244.
    // Default Open-Meteo precip is mm. 
    // TS line 138: if (maxRainRate > 0.5)
    // If mm, 0.5mm is very small using logic "Heavy Rain > 0.5"? 
    // Actually 0.5mm is very light. 0.5 inch is heavy.
    // If the TS code was built without specifying unit, it got mm.
    // If it meant inches, the logic `> 0.5` (inches) makes sense for "Heavy", but `> 0.5` mm is TINY.
    // Wait, let's look at the TS line 138 again: `details: { fail: 'Heavy Rain (> 0.02")' ... }` is NOT in the TS I read?
    // Let me check TS Line 138 in the file content I read earlier.
    // Line 138: `if (maxRainRate > 0.5) return { score: 0, details: { fail: 'Heavy Rain (> 0.02")', ... } }`
    // The console log says "Heavy Rain (> 0.02")" but the check is `> 0.5`. 
    // 0.5 mm is approx 0.02 inches. So the check is correct for MM (0.5mm ~= 0.02in).
    
    // Aggregates
    bool hasStorm = false;
    double sumCloud = 0;
    double sumHumidity = 0;

    for (var h in hours) {
      sumTemp += h.temperature;
      
      double wind = h.windSpeed ?? 0;
      if (wind > maxWind) maxWind = wind;

      double pop = h.precipitationProbability ?? 0;
      if (pop > maxPop) maxPop = pop;

      // Note: rain in OpenMeteo is usually 'rain' + 'showers' + 'snow_melt' etc, or 'precipitation'
      // The model mapping needs to ensure we get 'precipitation' if available.
      // If we use 'precipitation' value from API (mm).
      // TS line 122: maxRainRate = Math.max(...hours.map(h => h.rain || h.precipitation || 0))
      // It checks rain or precip.
      double valRain = h.rain ?? 0.0; // Assuming mapped
      if (valRain > maxRainRate) maxRainRate = valRain;

      if (stormCodes.contains(h.weatherCode)) hasStorm = true;

      sumCloud += (h.cloudCover ?? 50);
      sumHumidity += (h.relativeHumidity ?? 50);
    }

    double avgTemp = sumTemp / hours.length;
    double avgCloud = sumCloud / hours.length;
    double avgHumidity = sumHumidity / hours.length;

    // Check prime time (10 AM - 4 PM which is hours 10..15 inclusive, i.e. < 16)
    bool allHoursInPrimeTime = hours.every((h) {
      int hour = h.time.hour;
      return hour >= 10 && hour < 16;
    });

    // Fail Conditions
    // 55 F
    if (avgTemp < 55) return _fail('Too Cold (< 55°F)', avgTemp, maxWind, avgCloud, maxPop, avgHumidity);
    // 24 mph
    if (maxWind > 24) return _fail('High Wind (> 24 mph)', avgTemp, maxWind, avgCloud, maxPop, avgHumidity);
    // 49 %
    if (maxPop > 49) return _fail('High Rain Chance (> 49%)', avgTemp, maxWind, avgCloud, maxPop, avgHumidity);
    // 0.5 mm
    if (maxRainRate > 0.5) return _fail('Heavy Rain (> 0.02")', avgTemp, maxWind, avgCloud, maxPop, avgHumidity);
    // Storm
    if (hasStorm) return _fail('Thunderstorm Detected', avgTemp, maxWind, avgCloud, maxPop, avgHumidity);

    // Score Calculation
    int tempScore = 0;
    if (avgTemp >= 75) tempScore = 30;
    else if (avgTemp >= 70) tempScore = 28;
    else if (avgTemp >= 65) tempScore = 25;
    else if (avgTemp >= 60) tempScore = 20;
    else if (avgTemp >= 57) tempScore = 12;
    else if (avgTemp >= 55) tempScore = 5;

    int cloudScore = 0;
    if (avgCloud <= 20) cloudScore = 20;
    else if (avgCloud <= 40) cloudScore = 17;
    else if (avgCloud <= 60) cloudScore = 12;
    else if (avgCloud <= 80) cloudScore = 6;
    else cloudScore = 2;

    int windScore = 0;
    if (maxWind <= 5) windScore = 20;
    else if (maxWind <= 10) windScore = 18;
    else if (maxWind <= 15) windScore = 12;
    else if (maxWind <= 20) windScore = 6;
    else if (maxWind <= 24) windScore = 2;

    int precipScore = 0;
    if (maxPop == 0) precipScore = 15;
    else if (maxPop <= 10) precipScore = 12;
    else if (maxPop <= 20) precipScore = 8;
    else if (maxPop <= 35) precipScore = 4;
    else if (maxPop <= 49) precipScore = 1;

    int humidityScore = 0;
    if (avgHumidity >= 30 && avgHumidity <= 70) humidityScore = 5;
    else humidityScore = 2;

    int timeBonus = 0;
    if (allHoursInPrimeTime) timeBonus = 10;

    int totalScore = tempScore + cloudScore + windScore + precipScore + humidityScore + timeBonus;
    if (totalScore > 100) totalScore = 100;

    return {
      'score': totalScore,
      'details': {
        'avgTemp': avgTemp,
        'maxWind': maxWind,
        'avgCloud': avgCloud,
        'maxPop': maxPop,
        'avgHumidity': avgHumidity,
      },
      'scoreBreakdown': {
        'temperature': tempScore,
        'cloud': cloudScore,
        'wind': windScore,
        'precipitation': precipScore,
        'humidity': humidityScore,
        'timeBonus': timeBonus,
      }
    };
  }

  static Map<String, dynamic> _fail(String reason, double t, double w, double c, double p, double h) {
    return {
      'score': 0,
      'details': {
        'fail': reason,
        'avgTemp': t,
        'maxWind': w,
        'avgCloud': c,
        'maxPop': p,
        'avgHumidity': h,
      }
    };
  }
}
