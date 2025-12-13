import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';
import '../utils/scoring_logic.dart';

/*
class WeatherService {
  static const String _zipApiBase = "https://api.zippopotam.us/us";
  static const String _meteoBase = "https://api.open-meteo.com/v1/forecast";

  Future<Map<String, double>?> getCoordinatesFromZip(String zipCode) async {
    try {
      final response = await http.get(Uri.parse("$_zipApiBase/$zipCode"));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['places'] != null && (data['places'] as List).isNotEmpty) {
        final place = data['places'][0];
        return {
          'lat': double.parse(place['latitude']),
          'lng': double.parse(place['longitude']),
        };
      }
      return null;
    } catch (e) {
      print("Error fetching coords: $e");
      return null;
    }
  }

  Future<WeatherData?> getCurrentWeather(String zipCode) async {
    final coords = await getCoordinatesFromZip(zipCode);
    if (coords == null) return null;

    try {
      final url = Uri.parse(
          "$_meteoBase?latitude=${coords['lat']}&longitude=${coords['lng']}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto");
      
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception("Weather API failed");

      final data = jsonDecode(response.body);
      final current = data['current'];

      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        conditions: _weatherCodeToDescription(current['weather_code']),
        humidity: (current['relative_humidity_2m'] as num).toInt(),
        windSpeed: "${current['wind_speed_10m']} mph",
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print("Error fetching weather: $e");
      return null;
    }
  }

  Future<List<DayForecast>?> getInspectionForecast(String zipCode, {int days = 7}) async {
    final coords = await getCoordinatesFromZip(zipCode);
    if (coords == null) return null;

    try {
      final url = Uri.parse(
          "$_meteoBase?latitude=${coords['lat']}&longitude=${coords['lng']}&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,cloud_cover,wind_speed_10m,rain,showers,snow_depth&temperature_unit=fahrenheit&wind_speed_unit=mph&forecast_days=15&timezone=auto");
      
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final hourly = data['hourly'];
      final List<String> times = List<String>.from(hourly['time']);
      
      // Group by day
      Map<String, List<HourlyForecast>> dayMap = {};
      
      for (int i = 0; i < times.length; i++) {
        String timeStr = times[i];
        DateTime dt = DateTime.parse(timeStr);
        String dateKey = timeStr.substring(0, 10); // YYYY-MM-DD

        // Calculate mapped rain (rain + showers) - though open meteo 'rain' might suffice
        double rainVal = (hourly['rain']?[i] ?? 0.0) + (hourly['showers']?[i] ?? 0.0);

        final hf = HourlyForecast(
          time: dt,
          temperature: (hourly['temperature_2m'][i] as num).toDouble(),
          relativeHumidity: (hourly['relative_humidity_2m'][i] as num).toDouble(),
          precipitationProbability: (hourly['precipitation_probability'][i] as num).toDouble(),
          weatherCode: (hourly['weather_code'][i] as num).toInt(),
          cloudCover: (hourly['cloud_cover'][i] as num).toInt(),
          windSpeed: (hourly['wind_speed_10m'][i] as num).toDouble(),
          rain: rainVal,
        );

        if (!dayMap.containsKey(dateKey)) {
          dayMap[dateKey] = [];
        }
        dayMap[dateKey]!.add(hf);
      }

      List<DayForecast> forecasts = [];
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day); // midnight

      dayMap.forEach((dateKey, hours) {
        // Skip past days?
        if (DateTime.parse(dateKey).isBefore(today)) return;

        // Calculate Best Window
        BestTime? bestWindow = _findBestDailyWindow(hours);
        List<BestTime> bestTimes = bestWindow != null ? [bestWindow] : [];
        int maxScore = bestWindow?.score ?? 0;

        String overallScore;
        if (maxScore >= 85) overallScore = 'excellent';
        else if (maxScore >= 70) overallScore = 'good';
        else if (maxScore >= 55) overallScore = 'fair';
        else overallScore = 'poor';

        forecasts.add(DayForecast(
          date: dateKey,
          hours: hours,
          bestTimes: bestTimes,
          overallScore: overallScore,
        ));
      });

      return forecasts.take(days).toList();

    } catch (e) {
      print("Error fetching forecast: $e");
      return null;
    }
  }

  BestTime? _findBestDailyWindow(List<HourlyForecast> periods) {
    // Logic from weather.ts: periods.slice(i, i+4), window 9AM-5PM, need >=3 daylight hours to qualify
    List<BestTime> windows = [];

    // Ensure we don't go out of bounds
    if (periods.length < 4) return null;

    for (int i = 0; i <= periods.length - 4; i++) {
      var window = periods.sublist(i, i + 4);

      // Filter daylight (9-17)
      var daylightWindow = window.where((p) {
        int h = p.time.hour;
        return h >= 9 && h <= 17;
      }).toList();

      if (daylightWindow.length >= 3) {
        // Calculate score for each hour individually (deprecated logic in TS but used here)
        // TS: const scores = daytimeWindow.map(p => calculateBeeInspectionScore(p))
        // calculateBeeInspectionScore calls calculateWindowScore([p]).score
        
        List<int> scores = daylightWindow.map((p) {
          return ScoringLogic.calculateWindowScore([p])['score'] as int;
        }).toList();

        double avg = scores.reduce((a, b) => a + b) / scores.length;
        
        windows.add(BestTime(
          score: avg.round(), 
          start: daylightWindow.first.time.toIso8601String(),
          end: daylightWindow.last.time.toIso8601String()
        ));
      }
    }

    if (windows.isEmpty) return null;
    
    // Return max score
    return windows.reduce((curr, next) => curr.score > next.score ? curr : next);
  }

  String _weatherCodeToDescription(int code) {
    if (code == 0) return "Clear";
    if (code <= 3) return "Partly Cloudy";
    if (code <= 48) return "Foggy";
    if (code <= 67) return "Rainy";
    if (code <= 77) return "Snowy";
    if (code <= 82) return "Showers";
    if (code <= 99) return "Thunderstorm";
    return "Unknown";
  }
}
*/

// --- NEW SERVICE (Migrated from Hive Forecast Mobile) ---

import 'package:intl/intl.dart';

class WeatherService {
  static const String _zipApiUrl = 'https://api.zippopotam.us/us/';
  static const String _weatherApiUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, double>?> getCoordinatesFromZip(String zip) async {
    try {
      final response = await http.get(Uri.parse('$_zipApiUrl$zip'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = double.parse(data['places'][0]['latitude']);
        final lng = double.parse(data['places'][0]['longitude']);
        return {'lat': lat, 'lng': lng};
      }
    } catch (e) {
      print("Error fetching coords: $e");
    }
    return null;
  }

  Future<WeatherData?> getCurrentWeather(String zipCode) async {
    final coords = await getCoordinatesFromZip(zipCode);
    if (coords == null) return null;

    try {
      final url = Uri.parse(
          "$_weatherApiUrl?latitude=${coords['lat']}&longitude=${coords['lng']}&current=temperature_2m,relative_humidity_2m,weathercode,windspeed_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto");
      
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception("Weather API failed");

      final data = jsonDecode(response.body);
      final current = data['current'];

      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        conditions: _getConditionCode((current['weathercode'] as num).toInt()),
        humidity: (current['relative_humidity_2m'] as num).toInt(),
        windSpeed: "${current['windspeed_10m']} mph",
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print("Error fetching weather: $e");
      return null;
    }
  }

  Future<List<DayForecast>?> getInspectionForecast(String zipCode, {int days = 14}) async {
    final coords = await getCoordinatesFromZip(zipCode);
    if (coords == null) return null;

    try {
      final uri = Uri.parse(
        '$_weatherApiUrl?latitude=${coords['lat']}&longitude=${coords['lng']}&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,weathercode,cloudcover,windspeed_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=auto&forecast_days=$days'
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        final windows = calculateForecast(weatherData);

        // Group windows by Date to create DayForecast objects
        Map<String, List<InspectionWindow>> grouped = {};
        for (var w in windows) {
          String dateKey = DateFormat('yyyy-MM-dd').format(w.startTime);
          if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
          grouped[dateKey]!.add(w);
        }

        List<DayForecast> forecasts = [];
        grouped.forEach((date, winList) {
          // Calculate overall score for the day (e.g., max score)
          double maxScore = winList.map((e) => e.score).reduce((a, b) => a > b ? a : b);
          String overall;
          if (maxScore >= 85) overall = 'excellent';
          else if (maxScore >= 70) overall = 'good';
          else if (maxScore >= 55) overall = 'fair';
          else overall = 'poor';

          forecasts.add(DayForecast(
            date: date,
            windows: winList,
            overallScore: overall
          ));
        });

        return forecasts;
      }
    } catch (e) {
      print("Error fetching forecast: $e");
    }
    return null;
  }

  List<InspectionWindow> calculateForecast(Map<String, dynamic> weatherData) {
    List<InspectionWindow> windows = [];
    final hourly = weatherData['hourly'];
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final humidities = hourly['relative_humidity_2m'] as List;
    final precipProbs = hourly['precipitation_probability'] as List;
    final precips = hourly['precipitation'] as List;
    final codes = hourly['weathercode'] as List;
    final clouds = hourly['cloudcover'] as List;
    final winds = hourly['windspeed_10m'] as List;

    // Group indices by Date (yyyy-MM-dd)
    Map<String, List<int>> dayIndices = {};
    for (int i = 0; i < times.length; i++) {
        DateTime t = DateTime.parse(times[i]);
        String dayKey = DateFormat('yyyy-MM-dd').format(t);
        if (!dayIndices.containsKey(dayKey)) dayIndices[dayKey] = [];
        dayIndices[dayKey]!.add(i);
    }

    final targetStartHours = [6, 8, 10, 12, 14, 16];

    // Iterate over each day
    for (var dayKey in dayIndices.keys) {
        List<int> indices = dayIndices[dayKey]!;
        
        for (int startHour in targetStartHours) {
            // Find index for this specific hour
            int? startIndex;
            for (int idx in indices) {
                if (DateTime.parse(times[idx]).hour == startHour) {
                    startIndex = idx;
                    break;
                }
            }

            // We need 2 hours of data: startHour and startHour + 1
            if (startIndex != null && (startIndex + 1) < times.length) {
                int i = startIndex; 
                // Using 2 data points for 2-hour window
                List<double> segmentTemps = [temps[i], temps[i+1]].map((e) => (e as num).toDouble()).toList();
                List<double> segmentWinds = [winds[i], winds[i+1]].map((e) => (e as num).toDouble()).toList();
                List<double> segmentClouds = [clouds[i], clouds[i+1]].map((e) => (e as num).toDouble()).toList();
                List<double> segmentPrecipProbs = [precipProbs[i], precipProbs[i+1]].map((e) => (e as num).toDouble()).toList();
                List<double> segmentPrecips = [precips[i], precips[i+1]].map((e) => (e as num).toDouble()).toList();
                List<int> segmentCodes = [codes[i], codes[i+1]].map((e) => (e as num).toInt()).toList();
                List<double> segmentHumidities = [humidities[i], humidities[i+1]].map((e) => (e as num).toDouble()).toList();

                // Averages
                double avgTemp = segmentTemps.reduce((a, b) => a + b) / 2;
                double avgWind = segmentWinds.reduce((a, b) => a + b) / 2;
                double avgCloud = segmentClouds.reduce((a, b) => a + b) / 2;
                double avgPrecipProb = segmentPrecipProbs.reduce((a, b) => a + b) / 2;
                double avgHumidity = segmentHumidities.reduce((a, b) => a + b) / 2;

                // Kill Checks (Min/Max)
                double minTemp = segmentTemps.reduce((curr, next) => curr < next ? curr : next);
                double maxWind = segmentWinds.reduce((curr, next) => curr > next ? curr : next);
                double maxPrecipProb = segmentPrecipProbs.reduce((curr, next) => curr > next ? curr : next);
                double maxPrecipRate = segmentPrecips.reduce((curr, next) => curr > next ? curr : next);
                bool hasStorm = segmentCodes.any((c) => [95, 96, 99].contains(c));

                List<String> issues = [];
                if (minTemp < 55) {
                  issues.add("Too Cold (< 55°F)");
                }
                if (maxWind > 24) {
                  issues.add("Too Windy (> 24mph)");
                }
                if (maxPrecipProb > 49) {
                  issues.add("Rain Likely (> 49%)");
                }
                if (maxPrecipRate > 0.02) {
                  issues.add("Raining");
                }
                if (hasStorm) {
                  issues.add("Stormy Weather");
                }

                double totalScore = 0;
                Map<String, int> breakdown = {};

                // Scoring Logic (Always calculate breakdown)
                // Temp (Max 40)
                int tempScore = 0;
                if (avgTemp >= 75) {
                  tempScore = 40;
                } else if (avgTemp >= 70) {
                  tempScore = 37;
                } else if (avgTemp >= 65) {
                  tempScore = 33;
                } else if (avgTemp >= 60) {
                  tempScore = 27;
                } else if (avgTemp >= 57) {
                  tempScore = 18;
                } else if (avgTemp >= 55) {
                  tempScore = 8;
                }
                breakdown['Temperature'] = tempScore;
                totalScore += tempScore;

                // Cloud (Max 20)
                int cloudScore = 0;
                if (avgCloud <= 20) {
                  cloudScore = 20;
                } else if (avgCloud <= 40) {
                  cloudScore = 17;
                } else if (avgCloud <= 60) {
                  cloudScore = 12;
                } else if (avgCloud <= 80) {
                  cloudScore = 6;
                } else {
                  cloudScore = 2;
                }
                breakdown['Cloud Cover'] = cloudScore;
                totalScore += cloudScore;

                // Wind (Max 20)
                int windScore = 0;
                if (avgWind <= 5) {
                  windScore = 20;
                } else if (avgWind <= 10) {
                  windScore = 18;
                } else if (avgWind <= 15) {
                  windScore = 12;
                } else if (avgWind <= 20) {
                  windScore = 6;
                } else if (avgWind <= 24) {
                  windScore = 2;
                }
                breakdown['Wind Speed'] = windScore;
                totalScore += windScore;

                // Precip Prob (Max 15)
                int precipScore = 0;
                if (avgPrecipProb == 0) {
                  precipScore = 15;
                } else if (avgPrecipProb <= 10) {
                  precipScore = 12;
                } else if (avgPrecipProb <= 20) {
                  precipScore = 8;
                } else if (avgPrecipProb <= 35) {
                  precipScore = 4;
                } else if (avgPrecipProb <= 49) {
                  precipScore = 1;
                }
                breakdown['Precipitation'] = precipScore;
                totalScore += precipScore;

                // Humidity (Max 5)
                int humidityScore = (avgHumidity >= 30 && avgHumidity <= 70) ? 5 : 0;
                breakdown['Humidity'] = humidityScore;
                totalScore += humidityScore;

                // Override total score if kill conditions exist, but keep breakdown
                if (issues.isNotEmpty) {
                    totalScore = 0;
                }

                windows.add(InspectionWindow(
                  startTime: DateTime.parse(times[i]),
                  endTime: DateTime.parse(times[i]).add(const Duration(hours: 2)),
                  score: totalScore,
                  tempF: avgTemp,
                  windMph: avgWind,
                  cloudCover: avgCloud,
                  precipProb: avgPrecipProb,
                  humidity: avgHumidity,
                  condition: _getConditionCode(segmentCodes[0]),
                  issues: issues,
                  scoreBreakdown: breakdown,
                ));
            }
        }
    }
    return windows;
  }
  
  String _getConditionCode(int code) {
      if (code == 0) return 'Clear';
      if (code <= 3) return 'Partly Cloudy';
      if (code <= 48) return 'Foggy';
      if (code <= 67) return 'Rainy';
      if (code <= 77) return 'Snowy';
      if (code <= 82) return 'Rain Showers';
      return 'Stormy';
  }
}
