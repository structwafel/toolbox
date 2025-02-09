import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:structwafel_toolbox/utils/custom_suncalc.dart'; // Assuming your custom library
import 'dart:async';

class MidnightCalculatorScreen extends StatefulWidget {
  const MidnightCalculatorScreen({super.key});

  @override
  _MidnightCalculatorScreenState createState() =>
      _MidnightCalculatorScreenState();
}

class _MidnightCalculatorScreenState extends State<MidnightCalculatorScreen>
    with WidgetsBindingObserver {
  Position? _currentPosition;
  String _coordinates = 'Fetching location...';
  String _countdown = 'Calculating...';
  bool _isPermissionDenied = false;
  StreamSubscription<Position>? _locationStreamSubscription;
  bool _isPaused = false; // Flag to track pause state
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _locationStreamSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final newPermission = await Geolocator.requestPermission();
      if (newPermission == LocationPermission.deniedForever) {
        setState(() {
          _isPermissionDenied = true;
          _coordinates = 'Location access denied';
        });
        return;
      }
    }

    if (!_isPaused) {
      _startListening();
    }
  }

  void _startListening() {
    if (_locationStreamSubscription != null) return;

    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _coordinates =
            'Lat: ${position.latitude.toStringAsFixed(4)}°\nLong: ${position.longitude.toStringAsFixed(4)}°';
        _isPermissionDenied = false;
      });
      _updateCountdown();
    }, onError: (error) {
      // <--- Add an error handler!
      setState(() {
        _coordinates = "Error: $error";
      });
    });
  }

  void _pauseResumeLocation() {
    if (_isPaused) {
      _startListening();
    } else {
      _locationStreamSubscription?.cancel();
      _locationStreamSubscription = null; // Set to null after canceling
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _updateCountdown() {
    if (_currentPosition == null) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final now = DateTime.now();
      final nextMidnight = calculateMidnight(now);
      final remaining = nextMidnight.difference(now);

      setState(() {
        _countdown =
            'Time until midnight: ${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  DateTime calculateMidnight(DateTime now) {
    final nextMidnight = SunCalc.getNadir(
            now, _currentPosition!.latitude, _currentPosition!.longitude)
        .toLocal();

    // Check if nadir is tomorrow
    if (nextMidnight.isBefore(now)) {
      return SunCalc.getNadir(now.add(Duration(days: 1)),
              _currentPosition!.latitude, _currentPosition!.longitude)
          .toLocal();
    }
    return nextMidnight;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_coordinates,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              IconButton(
                // The pause/resume button
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: _pauseResumeLocation,
                tooltip: _isPaused ? 'Resume updates' : 'Pause updates',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(_countdown, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          if (_isPermissionDenied)
            ElevatedButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}
