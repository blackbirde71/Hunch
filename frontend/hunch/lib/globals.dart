// globals.dart
import 'package:hunch/database.dart';

List<int> questionIds = [];
List<Answer> answerList = [];
List<Map<String, dynamic>> infoCache = [];
const cacheSize = 5;
var marketsBox;
// var qIndex = cacheSize;
var qIndex = 0;
