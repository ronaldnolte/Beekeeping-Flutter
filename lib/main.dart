import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/hives_screen.dart';
import 'screens/hive_details_screen.dart';
import 'screens/inspections_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/interventions_screen.dart';
import 'screens/manage_apiaries_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBQ5ulcY7SEVXGgnc5pDoqGMoDyjyqOF78",
      appId: "1:1071895750008:web:7fed7a61ca41c2ecc5948d",
      messagingSenderId: "1071895750008",
      projectId: "hive-forecast-web",
      authDomain: "hive-forecast-web.firebaseapp.com",
      storageBucket: "hive-forecast-web.firebasestorage.app",
      measurementId: "G-122WD451ZC",
    ),
  );
  runApp(const BeekeepingApp());
}

class BeekeepingApp extends StatelessWidget {
  const BeekeepingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beekeeping Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
           if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        // '/': (context) => const HomeScreen(), // Handled by home property
        '/forecast': (context) => const ForecastScreen(),
        '/hives': (context) => const HivesScreen(),
        '/hive_details': (context) => const HiveDetailsScreen(),
        '/inspections': (context) => const InspectionsScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/interventions': (context) => const InterventionsScreen(),
        '/manage_apiaries': (context) => const ManageApiariesScreen(),
      },
    );
  }
}
