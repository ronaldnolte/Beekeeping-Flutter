import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';
import '../utils/scoring_logic.dart';

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
