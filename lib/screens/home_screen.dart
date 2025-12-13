import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/apiary.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';
import '../models/weather_models.dart';
import 'manage_apiaries_screen.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final WeatherService _weatherService = WeatherService();

  List<Apiary> _apiaries = [];
  Apiary? _selectedApiary;
  Apiary? _confirmedApiary;
  
  WeatherData? _currentWeather;
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiaries = await _storage.getApiaries();
      setState(() {
        _apiaries = apiaries;
        // Auto-select the first one so the button isn't disabled
        if (_selectedApiary == null && _apiaries.isNotEmpty) {
          _selectedApiary = _apiaries.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }



  Future<void> _handleSync() async {
    await _loadData();
    if (_confirmedApiary != null) {
      await _fetchWeather(_confirmedApiary!.zipCode);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data synced successfully")),
      );
    }
  }

  void _confirmSelection() {
    setState(() {
      _confirmedApiary = _selectedApiary;
    });
    if (_confirmedApiary != null) {
      _fetchWeather(_confirmedApiary!.zipCode);
    }
  }

  Future<void> _fetchWeather(String zip) async {
    setState(() => _loadingWeather = true);
    final weather = await _weatherService.getCurrentWeather(zip);
    if (mounted) {
      setState(() {
        _currentWeather = weather;
        _loadingWeather = false;
      });
    }
  }

  Widget _buildMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        if (_confirmedApiary != null) {
          // Pass arguments if route is forecast
          Navigator.pushNamed(
            context, 
            route, 
            arguments: _confirmedApiary
          );
        }
      },
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey[700]),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background pattern or gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.background, Colors.white],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.2))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                            ),
                            child: const Icon(Icons.hive, color: Colors.white), 
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Beekeeping Manager",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentWeather != null && !_loadingWeather) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "${_currentWeather!.temperature.round()}°F",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _currentWeather!.conditions,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_confirmedApiary != null)
                                  Text(
                                    "${_confirmedApiary!.name} (${_confirmedApiary!.zipCode})",
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                          ],
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.grey),
                            tooltip: "Logout",
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Selection Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Select Apiary: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              constraints: const BoxConstraints(minWidth: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Apiary>(
                                  value: _selectedApiary ?? (_apiaries.isNotEmpty ? _apiaries.first : null),
                                  hint: const Text("Choose apiary..."),
                                  items: _apiaries.map((a) {
                                    return DropdownMenuItem(
                                      value: a,
                                      child: Text(a.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedApiary = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: (_selectedApiary == null || _selectedApiary == _confirmedApiary)
                                  ? null
                                  : _confirmSelection,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(), 
                                  padding: const EdgeInsets.all(16)
                              ),
                              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/manage_apiaries');
                                _loadData(); // Refresh list on return
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Text("Manage Apiaries", style: TextStyle(color: Colors.black87)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _handleSync,
                              icon: const Icon(Icons.sync, size: 20),
                              label: const Text("Sync Now"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                side: const BorderSide(color: Colors.grey),
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 48),

                        if (_confirmedApiary == null)
                           Center(
                            child: Column(
                              children: [
                                Text(
                                  _apiaries.isEmpty 
                                    ? "No apiaries found. Click the + button to create one."
                                    : "Select an apiary above and click OK to begin.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                                  childAspectRatio: 2.4, // Wide cards, adjusted for content height
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  children: [
                                    _buildMenuCard(
                                      title: "Hives",
                                      description: "View and manage your hives",
                                      icon: LucideIcons.home,
                                      color: Colors.amber,
                                      route: '/hives',
                                    ),

                                    _buildMenuCard(
                                      title: "Tasks",
                                      description: "To-do list for your apiary",
                                      icon: LucideIcons.checkSquare,
                                      color: Colors.green,
                                      route: '/tasks',
                                    ),
                                    _buildMenuCard(
                                      title: "Inspection Forecast",
                                      description: "Find optimal inspection times",
                                      icon: LucideIcons.cloudSun,
                                      color: Colors.orange,
                                      route: '/forecast', 
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
