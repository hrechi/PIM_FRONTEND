import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AiAgronomistScreen extends StatefulWidget {
  final String parcelId;

  const AiAgronomistScreen({Key? key, required this.parcelId}) : super(key: key);

  @override
  _AiAgronomistScreenState createState() => _AiAgronomistScreenState();
}

class _AiAgronomistScreenState extends State<AiAgronomistScreen> {
  String _advice = "Tap the button to get AI advice.";
  bool _isLoading = false;

  Future<void> fetchAiAdvice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Replace with your NestJS IP/Port. Use 10.0.2.2 for Android Emulator.
      final url = Uri.parse('http://10.0.2.2:3000/agronomist/advice/${widget.parcelId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _advice = data['advice'];
        });
      } else {
        setState(() {
          _advice = "Failed to load advice from server.";
        });
      }
    } catch (e) {
      setState(() {
        _advice = "Error connecting to server: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Insights')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : fetchAiAdvice,
              icon: _isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.auto_awesome),
              label: Text('Ask AI Agronomist'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _advice,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}