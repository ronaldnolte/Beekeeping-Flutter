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

/*
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
*/

// --- NEW FORECAST SCREEN (Migrated from Hive Forecast Mobile) ---

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
       return Scaffold(
         appBar: AppBar(title: Text("Forecast for ${_apiary?.name ?? '...'}")), 
         body: const Center(child: CircularProgressIndicator())
       );
    }
    
    if (_error != null || _forecast == null || _forecast!.isEmpty) {
       return Scaffold(
         appBar: AppBar(title: Text("Forecast for ${_apiary?.name ?? '...'}")), 
         body: Center(child: Text(_error ?? "No forecast data."))
       );
    }

    // 1. Pivot Data: Group by Date -> Hour
    // We need to know all unique dates and unique hours.
    final Set<String> uniqueDates = {};
    final Map<String, Map<int, InspectionWindow>> gridData = {};

    // Flatten logic since our service now returns DayForecasts but UI logic works better with flat list of windows processing
    // Or we can just iterate the DayForecasts.
    // The Service returns List<DayForecast>.
    for (var d in _forecast!) {
      final dayStr = d.date; // already yyyy-MM-dd
      uniqueDates.add(dayStr);
      gridData[dayStr] = {};
      for (var w in d.windows) {
        gridData[dayStr]![w.startTime.hour] = w;
      }
    }

    final sortedDates = uniqueDates.toList()..sort();
    final sortedHours = [6, 8, 10, 12, 14, 16]; 

    return Scaffold(
      appBar: AppBar(
        title: Text("Forecast for ${_apiary?.name ?? 'Apiary'}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem("Excellent 85+", Colors.green.shade700),
                _buildLegendItem("Good 70-84", const Color(0xFF00C853)),
                _buildLegendItem("Fair 55-69", Colors.amber),
                _buildLegendItem("Poor 40-54", Colors.orange),
                _buildLegendItem("Not Rec <40", Colors.red),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    "Tap score for details.",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  // Info Dialog removed for now or can be added later
                  onTap: () {}, 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "How is this calculated?",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // The Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Table(
                    defaultColumnWidth: const FixedColumnWidth(60), // Width for data columns
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FixedColumnWidth(80), // First column (Time Labels) wider
                    },
                    children: [
                      // Header Row (Dates)
                      TableRow(
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          ...sortedDates.map((dateStr) {
                            final date = DateTime.parse(dateStr);
                            return TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(DateFormat('E').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(DateFormat('M/d').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      // Data Rows (Hours)
                      ...sortedHours.map((hour) {
                        String timeLabel = _formatHour(hour); // e.g. "6am"
                        
                        return TableRow(
                          children: [
                            // Row Header (Time)
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            // Data Cells
                            ...sortedDates.map((dateStr) {
                              final window = gridData[dateStr]?[hour];
                              if (window == null) {
                                  return Container(color: Colors.grey.shade200, height: 50);
                              }
                              return _buildTableCell(context, window);
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "* Days with numbers in red include conditions that are not recommended.",
                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
      switch (hour) {
        case 6: return "6-8am";
        case 8: return "8-10am";
        case 10: return "10am-12pm";
        case 12: return "12-2pm";
        case 14: return "2-4pm";
        case 16: return "4-6pm";
        default: return "$hour";
      }
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildTableCell(BuildContext context, InspectionWindow window) {
    final color = _getScoreColor(window.score);
    Color textColor = Colors.white;
    List<Shadow> textShadows = [
      const Shadow(blurRadius: 2.0, color: Colors.black45, offset: Offset(1.0, 1.0))
    ];

    if (window.score < 40) {
      textColor = Colors.black;
      textShadows = [];
    } else if (window.issues.isNotEmpty) {
      textColor = Colors.red; 
      textShadows = []; 
    } 

    return InkWell(
      onTap: () => _showDetails(context, window),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          window.score.toStringAsFixed(0),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: textShadows,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green.shade700;
    if (score >= 70) return const Color(0xFF00C853);
    if (score >= 55) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red; 
  }

  void _showDetails(BuildContext context, InspectionWindow window) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450, 
                maxHeight: 700, 
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4, 
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Inspection Conditions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('EEEE, MMMM d').format(window.startTime), style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            Text(_formatDetailTime(window.startTime.hour), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 20),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: _getScoreColor(window.score),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    window.score.toStringAsFixed(0),
                                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(
                                    'Overall Score',
                                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final calcWidth = (width - 24) / 3;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _buildStatCard("Temperature", "${window.tempF.toStringAsFixed(0)}°F", window.scoreBreakdown['Temperature'] ?? 0, 40, calcWidth),
                                    _buildStatCard("Cloud", "${window.cloudCover.toStringAsFixed(0)}%", window.scoreBreakdown['Cloud Cover'] ?? 0, 20, calcWidth),
                                    _buildStatCard("Wind", "${window.windMph.toStringAsFixed(0)}mph", window.scoreBreakdown['Wind Speed'] ?? 0, 20, calcWidth),
                                    _buildStatCard("Precip", "${window.precipProb.toStringAsFixed(0)}%", window.scoreBreakdown['Precipitation'] ?? 0, 15, calcWidth),
                                    _buildStatCard("Humidity", "${window.humidity.toStringAsFixed(0)}%", window.scoreBreakdown['Humidity'] ?? 0, 5, calcWidth),
                                  ],
                                );
                              }
                            ),
                            const SizedBox(height: 24),

                            if (window.issues.isNotEmpty) ...[
                               const Text('Issues:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                               const SizedBox(height: 8),
                               ...window.issues.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('• $e', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                                )),
                                const SizedBox(height: 16),
                            ],

                            if (_getPositiveConditions(window).isNotEmpty) ...[
                               const Text('Good Conditions:', 
                                    style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 16)),
                               const SizedBox(height: 8),
                               ..._getPositiveConditions(window).map((s) => Padding(
                                 padding: const EdgeInsets.only(bottom: 4),
                                 child: Text('• $s', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                               )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDetailTime(int hour) {
      if (hour >= 6 && hour < 10) {
        return "Morning";
      }
      if (hour >= 10 && hour < 14) {
        return "Mid-Day";
      }
      if (hour >= 14 && hour < 17) {
        return "Afternoon";
      }
      return "Evening";
  }

  List<String> _getPositiveConditions(InspectionWindow w) {
      List<String> cond = [];
      if (w.tempF >= 65 && w.tempF <= 85) {
        cond.add("Ideal temperature (${w.tempF.toStringAsFixed(0)}°F)");
      } else if (w.tempF > 55) {
        cond.add("Acceptable temperature (${w.tempF.toStringAsFixed(0)}°F)");
      }
      
      if (w.windMph < 10) {
        cond.add("Light winds (${w.windMph.toStringAsFixed(0)}mph)");
      } else if (w.windMph < 15) {
        cond.add("Manageable winds (${w.windMph.toStringAsFixed(0)}mph)");
      }

      if (w.cloudCover < 30) {
        cond.add("Sunny (${w.cloudCover.toStringAsFixed(0)}% clouds)");
      } else if (w.cloudCover < 60) {
        cond.add("Partly cloudy (${w.cloudCover.toStringAsFixed(0)}% clouds)");
      } else {
        cond.add("Cloudy but flyable");
      }

      if (w.precipProb < 10) {
        cond.add("No rain expected");
      }
      
      return cond;
  }

  Widget _buildStatCard(String label, String value, int score, int maxScore, double width) {
      bool isFail = score == 0 && label != "Time Bonus";
      
      return Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: isFail ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 1),
                  const SizedBox(height: 8),
                  Text('$score/$maxScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
          ),
      );
  }
} // End Class
