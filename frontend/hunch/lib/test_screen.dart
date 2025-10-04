// lib/screens/test_image_screen.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:hunch/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestImageScreen extends StatefulWidget {
  @override
  _TestImageScreenState createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  Map<String, dynamic>? question;
  bool loading = true;
  String? error;
  String? successMessage;
  bool hasAnswered = false;
  String? userAnswer;

  @override
  void initState() {
    super.initState();
    loadTestQuestion();
  }

  Future<void> loadTestQuestion() async {
    try {
      setState(() {
        loading = true;
        error = null;
        successMessage = null;
      });

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

      if (questions.isEmpty) {
        setState(() {
          error = 'Could not load question';
          loading = false;
        });
        return;
      }

      // Check if user already answered this question
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final existing = await Supabase.instance.client
            .from('user_interactions')
            .select('answer')
            .eq('user_id', user.id)
            .eq('question_id', questions.first['id'])
            .maybeSingle();

        setState(() {
          hasAnswered = existing != null;
          userAnswer = existing?['answer'];
        });
      }

      setState(() {
        question = questions.first;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> answerQuestion(String answer) async {
    try {
      setState(() {
        loading = true;
        error = null;
        successMessage = null;
      });

      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        setState(() {
          error = 'You must be signed in to answer';
          loading = false;
        });
        return;
      }

      // Insert answer
      await sendAnswers([Answer(questionId: question!['id'], answer: answer)]);

      setState(() {
        successMessage =
            '✅ Answer recorded! Counters should update automatically.';
        hasAnswered = true;
        userAnswer = answer;
      });

      // Reload question to see updated counts
      await Future.delayed(Duration(milliseconds: 500));
      await loadTestQuestion();
    } catch (e) {
      setState(() {
        error = 'Failed to record answer: ${e.toString()}';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interaction Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: loading
            ? CircularProgressIndicator()
            : error != null
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Error: $error',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : question == null
                    ? Text('No question loaded')
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question Info
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question ID: ${question!['id']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    question!['question'] ?? 'No question text',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // Image
                            if (question!['image_url'] != null && (question!['image_url'] as String).isNotEmpty) ...[
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                ),
                                child: Image.network(
                                  question!['image_url'] as String,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                            ] else if (question!['picture_data'] != null) ...[
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                ),
                                child: Image.memory(
                                  question!['picture_data'] as Uint8List,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                            ] else
                              Container(
                                padding: EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                ),
                                child: Center(
                                  child: Text('❌ No image data'),
                                ),
                              ),

                            SizedBox(height: 24),

                            // Stats
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT STATS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            '${question!['yes_count'] ?? 0}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'YES',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            '${question!['no_count'] ?? 0}',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'NO',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  if ((question!['yes_count'] ?? 0) +
                                          (question!['no_count'] ?? 0) >
                                      0)
                                    Text(
                                      '${(((question!['yes_count'] ?? 0) * 100.0) / ((question!['yes_count'] ?? 0) + (question!['no_count'] ?? 0))).toStringAsFixed(1)}% said YES',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // Success message
                            if (successMessage != null)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  border:
                                      Border.all(color: Colors.green, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  successMessage!,
                                  style: TextStyle(color: Colors.green[900]),
                                ),
                              ),

                            if (successMessage != null) SizedBox(height: 16),

                            // Answer buttons or already answered message
                            if (hasAnswered)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  border:
                                      Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.blue),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'You answered: ${userAnswer?.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => answerQuestion('yes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                              color: Colors.black, width: 2),
                                        ),
                                      ),
                                      child: Text(
                                        'YES',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => answerQuestion('no'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                              color: Colors.black, width: 2),
                                        ),
                                      ),
                                      child: Text(
                                        'NO',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadTestQuestion,
        backgroundColor: Colors.orange,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
