import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/capture/capture_screens.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/recommendations/recommendation_screen.dart';
import 'features/sessions/session_screens.dart';
import 'features/settings/settings_screens.dart';
import 'features/venues/venues_screens.dart';
import 'features/weather/weather_screens.dart';

class AppRoutes {
  static const splash = '/';
  static const dashboard = '/dashboard';
  static const venues = '/venues';
  static const editVenue = '/venues/edit';
  static const venueDetail = '/venues/detail';
  static const swims = '/swims';
  static const editSwim = '/swims/edit';
  static const spotMap = '/spots/map';
  static const startSession = '/sessions/start';
  static const liveSession = '/sessions/live';
  static const rodSetup = '/sessions/rods';
  static const addObservation = '/sessions/observations/add';
  static const addWaterReading = '/sessions/water-reading/add';
  static const addCatch = '/sessions/catch/add';
  static const addBlank = '/sessions/blank/add';
  static const recommendation = '/recommendation';
  static const capture = '/capture';
  static const weather = '/weather';
  static const review = '/sessions/review';
  static const settings = '/settings';
  static const privacy = '/settings/privacy';
}

class CarpCraftApp extends StatelessWidget {
  const CarpCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarpCraft Intelligence',
      debugShowCheckedModeBanner: false,
      theme: buildCarpCraftTheme(),
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.venues: (_) => const VenueListScreen(),
        AppRoutes.editVenue: (_) => const EditVenueScreen(),
        AppRoutes.venueDetail: (_) => const VenueDetailScreen(),
        AppRoutes.swims: (_) => const SwimListScreen(),
        AppRoutes.editSwim: (_) => const EditSwimScreen(),
        AppRoutes.spotMap: (_) => const SpotMapScreen(),
        AppRoutes.startSession: (_) => const StartSessionScreen(),
        AppRoutes.liveSession: (_) => const LiveSessionDashboardScreen(),
        AppRoutes.rodSetup: (_) => const RodSetupScreen(),
        AppRoutes.addObservation: (_) => const AddObservationScreen(),
        AppRoutes.addWaterReading: (_) => const AddWaterReadingScreen(),
        AppRoutes.addCatch: (_) => const AddCatchScreen(),
        AppRoutes.addBlank: (_) => const AddBlankIntervalScreen(),
        AppRoutes.recommendation: (_) => const RecommendationScreen(),
        AppRoutes.capture: (_) => const CaptureScreen(),
        AppRoutes.weather: (_) => const WeatherScreen(),
        AppRoutes.review: (_) => const PostSessionReviewScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.privacy: (_) => const PrivacyControlsScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2E2A), Color(0xFF155E63), Color(0xFFC58B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child:
                      const Icon(Icons.insights, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 22),
                const Text(
                  'CarpCraft Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
