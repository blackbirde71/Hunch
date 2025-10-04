// get ids

// batch get stuff from id

import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class Answer {
  final int questionId;
  final String answer; // 'yes' or 'no'
  final int? timeSpentSeconds;

  Answer({
    required this.questionId,
    required this.answer,
    this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson(String userId) => {
        'user_id': userId,
        'question_id': questionId,
        'answer': answer,
        'time_spent_seconds': timeSpentSeconds,
      };
}

final supabase = Supabase.instance.client;

/// Fetches all question IDs from the database.
///
/// Returns a list of question IDs.
Future<List<int>> getQuestionIds() async {
  final response = await supabase.from('questions').select('id');
  return response.map<int>((row) => row['id'] as int).toList();
}

/// Fetches questions by their IDs.
///
/// [ids] - List of question IDs to fetch
///
/// Returns a list of question maps with the following fields:
/// - `id` (int)
/// - `question` (String)
/// - `description` (String)
/// - `yes_price` (double)
/// - `picture_data` (Uint8List?)
///
/// To display the image: `Image.memory(question['picture_data'])`
Future<List<Map<String, dynamic>>> getQuestionsByIds(List<int> ids) async {
  if (ids.isEmpty) return [];

  final response =
      await supabase.from('questions').select().inFilter('id', ids);

  // Convert hex images to bytes
  return response.map((question) {
    if (question['picture_base64'] != null) {
      question['picture_data'] =
          base64Decode(question['picture_base64'] as String);
    }
    return question;
  }).toList();
}

Map<String, dynamic> _processQuestion(Map<String, dynamic> question) {
  if (question['picture_base64'] != null) {
    question['picture_data'] =
        base64Decode(question['picture_base64'] as String);
  }
  return question;
}

/// Fetches up to `limit` questions that the user has not seen and are not in `cache`.
Future<List<Map<String, dynamic>>> getUnansweredQuestions(
    int limit, List<int> cache) async {
  if (limit == 0) return [];

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    // If not signed in, just return random questions
    final questions = await supabase.from('questions').select().limit(limit);
    return questions.map(_processQuestion).toList();
  }

  final answered = await supabase
      .from('user_interactions')
      .select('question_id')
      .eq('user_id', user.id);

  final answeredIds = answered.map<int>((r) => r['question_id'] as int).toList()
    ..addAll(cache);

  var query = supabase.from('questions').select();
  if (answeredIds.isNotEmpty) {
    query = query.not('id', 'in', answeredIds);
  }

  final questions = await query.limit(limit);
  return questions.map(_processQuestion).toList();
}

Future<void> sendAnswers(List<Answer> answers) async {
  if (answers.isEmpty) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  final data = answers.map((answer) => answer.toJson(user.id)).toList();

  await supabase.from('user_interactions').insert(data);
}
