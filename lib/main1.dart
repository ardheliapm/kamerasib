import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';


void main() {
  runApp(const GeolocatorDemoApp());
}

class GeolocatorDemoApp extends StatelessWidget {
  const GeolocatorDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geolocator Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const GeolocatorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GeolocatorPage extends StatefulWidget {
  const GeolocatorPage({super.key});
  @override
  State<GeolocatorPage> createState() => _GeolocatorPageState();
}

class _GeolocatorPageState extends State<GeolocatorPage> {
  final List<String> _logs = [];
  StreamSubscription<Position>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _add('Location service OFF'); // minta user nyalakan GPS
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      _add('Permission DENIED');
      return false;
    }
    if (perm == LocationPermission.deniedForever) {
      _add('Permission DENIED FOREVER (buka settings)');
      return false;
    }
    return true;
  }

  Future<void> _getCurrent() async {
    if (!await _ensurePermission()) return;
    final pos = await Geolocator.getCurrentPosition();
    _add('Current: ${pos.latitude}, ${pos.longitude}');
  }

  void _toggleStream() async {
    if (_sub == null) {
      if (!await _ensurePermission()) return;
      _sub = Geolocator.getPositionStream().listen((pos) {
        _add('Stream: ${pos.latitude}, ${pos.longitude}');
      });
      _add('Stream START');
      setState(() {});
      return;
    }
    if (_sub!.isPaused) {
      _sub!.resume();
      _add('Stream RESUME');
    } else {
      _sub!.pause();
      _add('Stream PAUSE');
    }
    setState(() {});
  }

  void _openSettings() async {
    final ok = await Geolocator.openAppSettings();
    _add(ok ? 'Opened app settings' : 'Failed to open settings');
  }

  void _add(String s) {
    setState(() => _logs.insert(0, s));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final streaming = _sub != null && !_sub!.isPaused;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocator (App Example)'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Open App Settings',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text(_logs[i]),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: _getCurrent,
            icon: const Icon(Icons.my_location),
            label: const Text('Get current'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _toggleStream,
            icon: Icon(streaming ? Icons.pause : Icons.play_arrow),
            label: Text(streaming ? 'Pause stream' : 'Start stream'),
          ),
        ],
      ),
    );
  }
}
