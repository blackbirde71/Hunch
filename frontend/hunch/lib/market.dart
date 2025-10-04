import 'package:hive/hive.dart';

part 'market.g.dart'; // generated automatically

@HiveType(typeId: 0)
class Market extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String question;

  @HiveField(2)
  String description;

  @HiveField(3)
  double price;

  @HiveField(4)
  SwipeAction action;

  Market({
    required this.id,
    required this.question,
    required this.description,
    required this.price,
    required this.action,
  });
}

@HiveType(typeId: 1)
enum SwipeAction {
  @HiveField(0)
  yes,
  @HiveField(1)
  no,
  @HiveField(2)
  blank,
}
