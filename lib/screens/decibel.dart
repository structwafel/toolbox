import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';

class SoundMeterScreen extends StatefulWidget {
  const SoundMeterScreen({super.key});

  @override
  State<SoundMeterScreen> createState() => _SoundMeterScreenState();
}

class _SoundMeterScreenState extends State<SoundMeterScreen>
    with WidgetsBindingObserver {
  bool _isRecording = false;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  late NoiseMeter _noiseMeter;
  double _meanDB = 0.0;
  bool _hasPermission = false;

  // For smoothing
  final Queue<double> _recentReadings = Queue<double>();
  int _smoothingValue = 4; // Starting value
  static const int _minSmoothing = 1;
  static const int _maxSmoothing = 10;

  // For graph
  final List<FlSpot> _chartData = [];
  static const int _maxDataPoints = 100;
  int _xValue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noiseMeter = NoiseMeter();
    _checkPermissions().then((_) {
      if (_hasPermission) {
        _startRecording();
      }
    });
  }

  @override
  void dispose() {
    _stopRecording();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_hasPermission && !_isRecording) {
        _startRecording();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_isRecording) {
        _stopRecording();
      }
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
  }

  void _startRecording() async {
    if (!_hasPermission) {
      await _checkPermissions();
      if (!_hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone permission is required to measure sound levels'),
          ),
        );
        return;
      }
    }

    try {
      _noiseSubscription = _noiseMeter.noise.listen((noiseReading) {
        // Apply smoothing
        _recentReadings.add(noiseReading.meanDecibel);
        while (_recentReadings.length > _smoothingValue) {
          _recentReadings.removeFirst();
        }

        double smoothedValue = _recentReadings.isNotEmpty
            ? _recentReadings.reduce((a, b) => a + b) / _recentReadings.length
            : 0.0;

        // Add to chart data
        _chartData.add(FlSpot(_xValue.toDouble(), smoothedValue));
        _xValue++;

        if (_chartData.length > _maxDataPoints) {
          _chartData.removeAt(0);
        }

        setState(() {
          _meanDB = smoothedValue;
        });
      });

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting noise meter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error measuring sound: ${e.toString()}'),
        ),
      );
    }
  }

  void _stopRecording() {
    _noiseSubscription?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  void _updateSmoothing(int value) {
    setState(() {
      _smoothingValue = value;
      // Adjust current readings to match new smoothing value
      while (_recentReadings.length > _smoothingValue) {
        _recentReadings.removeFirst();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.volume_up,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Sound Meter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Current Sound Level',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_meanDB.toStringAsFixed(1)} dB',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
            ),
          ),

          // Sound level graph
          if (_chartData.isNotEmpty)
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100, // Adjust based on your expected dB range
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Smoothing control
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Smoothing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '$_smoothingValue',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: _smoothingValue.toDouble(),
                    min: _minSmoothing.toDouble(),
                    max: _maxSmoothing.toDouble(),
                    divisions: _maxSmoothing - _minSmoothing,
                    label: _smoothingValue.toString(),
                    onChanged: (value) => _updateSmoothing(value.toInt()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fast Response'),
                      Text('Smooth Response'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (!_hasPermission)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Microphone permission is required',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _checkPermissions();
                      if (_hasPermission) {
                        _startRecording();
                      }
                    },
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
