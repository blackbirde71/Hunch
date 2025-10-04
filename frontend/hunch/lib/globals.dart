// globals.dart
import 'package:hunch/database.dart';

List<int> questionIds = [];
List<Map<String, dynamic>> infoCache = [];
const cacheSize = 2;
var marketsBox;
var qIndex = cacheSize;