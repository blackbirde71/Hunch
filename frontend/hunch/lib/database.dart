// get ids

// batch get stuff from id

import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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
