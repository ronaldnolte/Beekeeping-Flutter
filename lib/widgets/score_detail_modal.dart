/*
import 'package:flutter/material.dart';
import '../models/weather_models.dart';

class ScoreDetailModal extends StatelessWidget {
  final InspectionScore scoreData;
  final String dateLabel;
  final String timeLabel;

  const ScoreDetailModal({
    super.key,
    required this.scoreData,
    required this.dateLabel,
    required this.timeLabel,
  });

  Color _getScoreColor(int score) {
    if (score >= 85) {
      return Colors.green.shade600;
    }
    if (score >= 70) {
      return Colors.green.shade400;
    }
    if (score >= 55) {
      return Colors.yellow.shade600; // Visible yellow
    }
    if (score >= 40) {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final details = scoreData.details;
    final breakdown = scoreData.scoreBreakdown;
    
    // Analyze "issues" and "positives" similar to TS logic
    List<String> issues = [];
    List<String> positives = [];

    if (details.fail != null) {
      issues.add("Condition Failed: ${details.fail}");
    }

    // Temp
    if (details.avgTemp >= 75) {
      positives.add("Ideal temperature (${details.avgTemp.round()}°F)");
    } else if (details.avgTemp >= 60) {
      positives.add("Good temperature (${details.avgTemp.round()}°F)");
    } else if (details.avgTemp >= 55) {
      issues.add("Cool temperature (${details.avgTemp.round()}°F)");
    } else {
      issues.add("Too cold (${details.avgTemp.round()}°F)");
    }

    // Wind
    if (details.maxWind <= 5) {
      positives.add("Calm winds (${details.maxWind.round()}mph)");
    } else if (details.maxWind <= 10) {
      positives.add("Light winds (${details.maxWind.round()}mph)");
    } else if (details.maxWind > 24) {
      issues.add("High winds (${details.maxWind.round()}mph)");
    }

    // Rain
    if (details.maxPop == 0) {
      positives.add("No rain expected");
    } else if (details.maxPop > 49) {
      issues.add("High rain chance (${details.maxPop.round()}%)");
    } else if (details.maxPop > 0) {
      issues.add("${details.maxPop.round()}% chance of rain");
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Inspection Conditions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text("$dateLabel • $timeLabel", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              
              // Big Score
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _getScoreColor(scoreData.score),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text("${scoreData.score}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text("Overall Score", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Grid
              if (breakdown != null)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.2,
                  children: [
                    _buildGridItem("Temperature", "${details.avgTemp.round()}°F", breakdown.temperature, 30),
                    _buildGridItem("Cloud", "${details.avgCloud.round()}%", breakdown.cloud, 20),
                    _buildGridItem("Wind", "${details.maxWind.round()}mph", breakdown.wind, 20),
                    _buildGridItem("Precip", "${details.maxPop.round()}%", breakdown.precipitation, 15),
                    _buildGridItem("Humidity", "${details.avgHumidity.round()}%", breakdown.humidity, 5),
                    _buildGridItem("Time Bonus", "10AM-4PM", breakdown.timeBonus, 10),
                  ],
                ),
              
              const SizedBox(height: 16),
              
              if (issues.isNotEmpty) ...[
                const Text("Issues:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ...issues.map((i) => Text("• $i", style: const TextStyle(color: Colors.grey))),
                const SizedBox(height: 8),
              ],
              
              if (positives.isNotEmpty) ...[
                const Text("Good Conditions:", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ...positives.map((p) => Text("• $p", style: const TextStyle(color: Colors.grey))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, String value, int score, int max) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text("$score/$max", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
*/
