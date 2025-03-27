import 'package:flutter/material.dart';
import 'screens/midnight_calculator.dart';
import 'screens/decibel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'structwafels Toolbox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'structwafels Toolbox 1'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Text('Applications'),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              title: Text('Midnight Calculator'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              title: Text('Sound Meter'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
          ],
        ),
      ),
      body: _getScreen(),
    );
  }

  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apps,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Structwafels Toolbox',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Available Tools:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: ListTile(
                  leading: const Icon(Icons.calculate),
                  title: const Text('Midnight Calculator'),
                  subtitle: const Text('Calculate astronomical midnight'),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: const Text('Sound Meter'),
                  subtitle: const Text('Measure ambient sound levels'),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        );
      case 1:
        return const MidnightCalculatorScreen();
      case 2:
        return const SoundMeterScreen();
      default:
        return const Center(
          child: Text('Screen not found'),
        );
    }
  }
}
