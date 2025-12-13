import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/apiary.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';
import '../utils/scoring_logic.dart';
import '../widgets/score_detail_modal.dart';
import '../utils/theme.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  Apiary? _apiary;
  final WeatherService _weatherService = WeatherService();
  bool _loading = true;
  List<DayForecast>? _forecast;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_apiary == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Apiary?;
      if (args != null) {
        _apiary = args;
        _loadForecast();
      }
    }
  }

  Future<void> _loadForecast() async {
    if (_apiary == null) return;
    try {
      final data = await _weatherService.getInspectionForecast(_apiary!.zipCode, days: 14);
      if (mounted) {
        setState(() {
          _forecast = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load forecast";
          _loading = false;
        });
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green.shade600;
    if (score >= 70) return Colors.green.shade400;
    if (score >= 55) return Colors.yellow.shade600; // Adjusted for visibility
    if (score >= 40) return Colors.orange;
    return Colors.red.shade600;
  }

  InspectionScore _calculatePeriodScore(DayForecast day, int startHour, int endHour) {
    final hours = day.hours.where((h) {
      int hour = h.time.hour;
      return hour >= startHour && hour < endHour;
    }).toList();

    if (hours.isEmpty) {
      return InspectionScore(
        score: 0,
        details: ScoreDetails(
            fail: "No data", 
            avgTemp: 0, maxWind: 0, avgCloud: 0, maxPop: 0, avgHumidity: 0),
      );
    }

    // Use ScoringLogic
    final result = ScoringLogic.calculateWindowScore(hours);
    
    // Map map result back to strong types
    final detailsMap = result['details'] as Map<String, dynamic>;
    final breakdownMap = result['scoreBreakdown'] as Map<String, dynamic>?;

    return InspectionScore(
      score: result['score'],
      details: ScoreDetails(
        fail: detailsMap['fail'],
        avgTemp: (detailsMap['avgTemp'] as num).toDouble(),
        maxWind: (detailsMap['maxWind'] as num).toDouble(),
        avgCloud: (detailsMap['avgCloud'] as num).toDouble(),
        maxPop: (detailsMap['maxPop'] as num).toDouble(),
        avgHumidity: (detailsMap['avgHumidity'] as num).toDouble(),
      ),
      scoreBreakdown: breakdownMap == null ? null : ScoreBreakdown(
        temperature: breakdownMap['temperature'],
        cloud: breakdownMap['cloud'],
        wind: breakdownMap['wind'],
        precipitation: breakdownMap['precipitation'],
        humidity: breakdownMap['humidity'],
        timeBonus: breakdownMap['timeBonus'],
      ),
    );
  }

  void _showDetails(InspectionScore score, String dateStr, String periodLabel) {
    if (score.score == 0 && score.details.fail == "No data") return;

    showDialog(
      context: context,
      builder: (_) => ScoreDetailModal(
        scoreData: score, 
        dateLabel: dateStr, 
        timeLabel: periodLabel
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'label': 'Early AM', 'start': 8, 'end': 10},
      {'label': 'Late AM', 'start': 11, 'end': 13},
      {'label': 'Early PM', 'start': 14, 'end': 16},
      {'label': 'Late PM', 'start': 17, 'end': 19},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Forecast for ${_apiary?.name ?? 'Apiary'}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _forecast == null || _forecast!.isEmpty
                  ? const Center(child: Text("No forecast data available."))
                  : Column(
                      children: [
                        // Legend
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            spacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _LegendItem(color: Colors.green.shade600, text: "Excellent"),
                              _LegendItem(color: Colors.green.shade400, text: "Good"),
                              _LegendItem(color: Colors.yellow.shade600, text: "Fair"),
                              _LegendItem(color: Colors.orange, text: "Poor"),
                              _LegendItem(color: Colors.red.shade600, text: "Bad"),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 12,
                                columns: [
                                  const DataColumn(label: Text("Period", style: TextStyle(fontWeight: FontWeight.bold))),
                                  ..._forecast!.map((day) {
                                    final date = DateTime.parse(day.date);
                                    return DataColumn(
                                      label: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(DateFormat('EEE').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text(DateFormat('MMM d').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                rows: periods.map((period) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(period['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      ..._forecast!.map((day) {
                                        final scoreData = _calculatePeriodScore(
                                          day, 
                                          period['start'] as int, 
                                          period['end'] as int
                                        );
                                        return DataCell(
                                          InkWell(
                                            onTap: () => _showDetails(scoreData, day.date, period['label'] as String),
                                            child: Container(
                                              width: 50,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _getScoreColor(scoreData.score),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                "${scoreData.score > 0 ? scoreData.score : '-'}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
