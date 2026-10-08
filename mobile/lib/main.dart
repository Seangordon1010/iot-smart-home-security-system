import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Security',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SecurityHomePage(),
    );
  }
}

class SecurityHomePage extends StatefulWidget {
  const SecurityHomePage({super.key});

  @override
  State<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends State<SecurityHomePage> {
  List<dynamic> events = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/events'),
      );

      if (response.statusCode == 200) {
        setState(() {
          events = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load events.';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Could not connect to the backend.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (errorMessage.isNotEmpty)
              Text(errorMessage)
            else if (events.isEmpty)
              const Text('No security events found.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning),
                        title: Text(event['event_type']),
                        subtitle: Text(
                          '${event['device_id']}\n${event['timestamp']}',
                        ),
                        trailing: Text(event['status']),
                      ),
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
