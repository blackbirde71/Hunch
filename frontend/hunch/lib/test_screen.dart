// lib/screens/test_image_screen.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:hunch/database.dart';
// Import your question repository file

class TestImageScreen extends StatefulWidget {
  @override
  _TestImageScreenState createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  Map<String, dynamic>? question;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTestQuestion();
  }

  Future<void> loadTestQuestion() async {
    try {
      // Get first few question IDs
      final ids = await getQuestionIds();

      if (ids.isEmpty) {
        setState(() {
          error = 'No questions found in database';
          loading = false;
        });
        return;
      }

      // Fetch first question
      final questions = await getQuestionsByIds([ids.first]);

      setState(() {
        question = questions.isNotEmpty ? questions.first : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Test')),
      body: Center(
        child: loading
            ? CircularProgressIndicator()
            : error != null
                ? Text('Error: $error', style: TextStyle(color: Colors.red))
                : question == null
                    ? Text('No question loaded')
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ID: ${question!['id']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Text(
                              question!['question'] ?? 'No question text',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 16),
                            if (question!['picture_data'] != null) ...[
                              Text('✅ Image found! Displaying...'),
                              SizedBox(height: 16),
                              Image.memory(
                                question!['picture_data'] as Uint8List,
                                fit: BoxFit.contain,
                              ),
                            ] else
                              Text('❌ No image data for this question'),
                            SizedBox(height: 16),
                            Text('Yes Price: ${question!['yes_price']}'),
                          ],
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            loading = true;
            error = null;
          });
          loadTestQuestion();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
