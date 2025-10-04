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

  print(ids);
  final response =
      await supabase.from('questions').select().inFilter('id', ids);

  // Convert hex images to bytes
  print("done");
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

Future<List<Map<String, dynamic>>> getUnansweredQuestions(
    int limit, List<int> inCache) async {
  if (limit == 0) return [];

  final user = Supabase.instance.client.auth.currentUser;

  // 1️⃣ Get all question IDs
  final allIdsResponse = await supabase.from('questions').select('id');
  final allIds = allIdsResponse.map<int>((q) => q['id'] as int).toList();

  if (user == null) {
    final selectedIds = allIds.take(limit).toList();
    return await getQuestionsByIds(selectedIds);
  }

  final answeredResponse = await supabase
      .from('user_interactions')
      .select('question_id')
      .eq('user_id', user.id);

  final answeredIds = {
    ...answeredResponse.map<int>((r) => r['question_id'] as int),
    ...inCache,
  };

  final unansweredIds =
      allIds.where((id) => !answeredIds.contains(id)).take(limit).toList();

  return await getQuestionsByIds(unansweredIds);
}

/// Fetches up to `limit` questions that the user has not seen and are not in `cache`.
Future<List<Map<String, dynamic>>> getUnansweredQuestions2(
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

  final answeredIds = [
    ...answered.map<int>((r) => r['question_id'] as int),
    ...cache
  ];
  

  print("start q");

  final questions = await supabase
      .from('questions')
      .select()
      .not('id', 'in', answeredIds)
      .limit(limit);

  print("end q");

  return questions.map(_processQuestion).toList();
}

Future<void> sendAnswers(List<Answer> answers) async {
  if (answers.isEmpty) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  final data = answers.map((answer) => answer.toJson(user.id)).toList();

  await supabase.from('user_interactions').insert(data);
}

Future<List<Map<String, dynamic>>> getStatsDB(List<String> ids) async {
  if (ids.isEmpty) return [];

  final user = supabase.auth.currentUser;
  if (user == null) return [];

  // Convert string IDs to integers
  final intIds = ids.map((id) => int.parse(id)).toList();

  // get polymarket and hackharvard yes, no count for a list of question IDs
  final stats = await supabase
    .from('questions')
    .select('''
    yes_price,
    yes_count,
    no_count''').inFilter('id', intIds);
  return stats;
}