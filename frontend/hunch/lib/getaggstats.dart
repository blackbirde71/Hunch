// getaggstats.dart

import "database.dart";
import "globals.dart";

// return the polymarket and hack harvard stats associated with each question id

class Stats {
  final int questionId;
  final double polymarketProb; // 'yes' or 'no'
  final double ? hackHarvardProb;

  Stats({
    required this.questionId,
    required this.polymarketProb,
    this.hackHarvardProb,
  });
}


Future<List<Stats>> getStats() async {
    // get ids for questions we've already answered
    // Returns keys; normalize to both String (for DB) and int (for UI)
    final rawKeys = marketsBox.keys.toList();
    final List<String> stringKeys = (rawKeys as List)
        .map<String>((k) => k.toString())
        .toList();
    final List<int> intKeys = (rawKeys as List)
        .map<int>((k) => k is int ? k : int.parse(k.toString()))
        .toList();
    print(stringKeys);

    // get the statistics for each market
    final stats = await getStatsDB(stringKeys);

    print(stats);

    // return a list of id, polymarket prob, hackharvard prob for each market the user has swiped on
    List<Stats> ret = [];
    for (int i = 0; i < stats.length; i++) {
        final newMarket = Stats(
            questionId: intKeys[i],
            polymarketProb: stats[i]["yes_price"].toDouble(),
            hackHarvardProb: stats[i]["yes_count"].toDouble() / (stats[i]["no_count"] + stats[i]["yes_count"]).toDouble()
        );
        ret.add(newMarket);
    }

    return ret;
}