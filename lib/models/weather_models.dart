import 'package:intl/intl.dart';

class WeatherData {
  final double temperature;
  final String conditions;
  final int? humidity;
  final String? windSpeed;
  final int lastUpdated;

  WeatherData({
    required this.temperature,
    required this.conditions,
    this.humidity,
    this.windSpeed,
    required this.lastUpdated,
  });
}

/*
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final double? relativeHumidity;
  final double? precipitationProbability;
  final int weatherCode;
  final int? cloudCover;
  final double? windSpeed;
  final double? windGusts;
  final double? rain;

  HourlyForecast({
    required this.time,
    required this.temperature,
    this.relativeHumidity,
    this.precipitationProbability,
    required this.weatherCode,
    this.cloudCover,
    this.windSpeed,
    this.windGusts,
    this.rain,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json, int index) {
    // This factory assumes we are parsing from the specific structure of Open-Meteo hourly arrays
    // Use named constructor or external parsing logic if preferred, but for porting simplicity:
    // Actually, Open-Meteo returns arrays of values, not objects per hour.
    // So the service will responsibly map this.
    // We will keep this class as a pure model.
    throw UnimplementedError("Use custom mapping in Service");
  }
}

class DayForecast {
  final String date;
  final List<HourlyForecast> hours;
  final List<BestTime> bestTimes;
  final String overallScore; // 'excellent' | 'good' | 'fair' | 'poor'

  DayForecast({
    required this.date,
    required this.hours,
    required this.bestTimes,
    required this.overallScore,
  });
}

class BestTime {
  final String start;
  final String end;
  final int score;

  BestTime({
    required this.start,
    required this.end,
    required this.score,
  });
}

class InspectionScore {
  final int score;
  final ScoreDetails details;
  final ScoreBreakdown? scoreBreakdown;

  InspectionScore({
    required this.score,
    required this.details,
    this.scoreBreakdown,
  });
}

class ScoreDetails {
  final String? fail;
  final double avgTemp;
  final double maxWind;
  final double avgCloud;
  final double maxPop;
  final double avgHumidity;

  ScoreDetails({
    this.fail,
    required this.avgTemp,
    required this.maxWind,
    required this.avgCloud,
    required this.maxPop,
    required this.avgHumidity,
  });
}

class ScoreBreakdown {
  final int temperature;
  final int cloud;
  final int wind;
  final int precipitation;
  final int humidity;
  final int timeBonus;

  ScoreBreakdown({
    required this.temperature,
    required this.cloud,
    required this.wind,
    required this.precipitation,
    required this.humidity,
    required this.timeBonus,
  });
}
*/

// --- NEW MODELS (Migrated from Hive Forecast Mobile) ---

class InspectionWindow {
  final DateTime startTime;
  final DateTime endTime;
  final double score;
  final double tempF;
  final double windMph;
  final double cloudCover;
  final double precipProb;
  final double humidity;
  final String condition; 
  final List<String> issues; 
  final Map<String, int> scoreBreakdown;

  InspectionWindow({
    required this.startTime,
    required this.endTime,
    required this.score,
    required this.tempF,
    required this.windMph,
    required this.cloudCover,
    required this.precipProb,
    required this.humidity,
    required this.condition,
    required this.issues,
    required this.scoreBreakdown,
  });
}

class DayForecast {
  final String date;
  final List<InspectionWindow> windows;
  final String overallScore;

  DayForecast({
    required this.date,
    required this.windows,
    required this.overallScore,
  });
}
