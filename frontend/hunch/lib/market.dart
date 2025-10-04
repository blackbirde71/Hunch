import 'package:isar/isar.dart';

part 'market.g.dart';

@collection
class Market {
  Market({
    required this.id,
    required this.question,
    required this.description,
    required this.price,
    required this.action,
  });

  final Id id;
  final String question;
  final String description;
  final double price;
  @enumerated
  final Action action;
}

enum Action {
  yes,
  no,
  blank
}