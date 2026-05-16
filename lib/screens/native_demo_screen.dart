import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../native/native_engine.dart';

class NativeDemoScreen extends StatefulWidget {
  const NativeDemoScreen({super.key});

  @override
  State<NativeDemoScreen> createState() => _NativeDemoScreenState();
}

class _NativeDemoScreenState extends State<NativeDemoScreen> {
  final NativeEngine _engine = NativeEngine();
  CancellationToken? _token;
  String _stats = "Loading stats...";
  Future<String>? _heavyTaskFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final stats = await _engine.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<String> _runHeavyTask() async {
    _token = CancellationToken();

    // Simulate a large JSON
    final Map<String, dynamic> largeData = {
      "id": 1,
      "name": "Heavy Task",
      "data": List.generate(100, (index) => "item_$index"),
    };
    final Uint8List input = Uint8List.fromList(utf8.encode(jsonEncode(largeData)));

    try {
      final result = await _engine.processJson(
        "heavy_task_key",
        input,
        token: _token,
      );

      // Update stats after completion (outside build phase)
      Future.delayed(Duration.zero, _refreshStats);

      return utf8.decode(result);
    } catch (e) {
      return "Error: $e";
    }
  }

  void _triggerTask() {
    setState(() {
      _heavyTaskFuture = _runHeavyTask();
    });
  }

  @override
  void dispose() {
    _token?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Native Go Engine Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cache Stats: $_stats", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _triggerTask,
              child: const Text("Run Heavy Task"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _token?.cancel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task Cancelled")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Cancel Task"),
            ),
            const SizedBox(height: 20),
            const Text("Result:", style: TextStyle(fontSize: 18)),
            Expanded(
              child: _heavyTaskFuture == null
                ? const Center(child: Text("Press button to start task"))
                : FutureBuilder<String>(
                    future: _heavyTaskFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }
                      return SingleChildScrollView(
                        child: Text(snapshot.data ?? "No data"),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
