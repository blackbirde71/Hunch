// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hunch/database.dart';
import 'package:hunch/test_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feed.dart';
import 'hunches.dart';
import 'market.dart';
import 'globals.dart';


void onSwipe(SwipeAction action) async {

  // add to hive what the user just swiped on
  marketsBox.put(infoCache[0]?['id'], {
    'question': infoCache[0]?['question'],
    'description': infoCache[0]?['description'],
    'swipe': action
  });

  // remove the first card from the infoCache
  if (infoCache.isNotEmpty) {
    infoCache.removeAt(0);
  }

  // get the index of the next card
  qIndex = qIndex + 1;

  // get the next item from supabase
  List<Map<String, dynamic>> questions = await getQuestionsByIds([questionIds[qIndex]]);
  Map<String, dynamic> nextCard = questions[0];

  // add it to the cache
  infoCache.add(nextCard);

}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MarketAdapter());
  Hive.registerAdapter(SwipeActionAdapter());

  await Hive.openBox<Market>('markets');
  
  // db init
  await Supabase.initialize(
    url: 'https://benwvphuubnrzdlhvjzu.supabase.co',
    // dont flame it is anon key
    anonKey: 'sb_publishable_JiGhx5v95JaN977zMHHlRA_A2nn7wnT',
  );

  questionIds = await getQuestionIds();

  // TODO: need to remove the questionIDs we've already seen
  infoCache = await getQuestionsByIds(questionIds.sublist(0, cacheSize));

  final testMarket = Market(
    id: "111",
    question: "HI?!",
    description: "ajsdfnjksd,nfkshb",
    price: 0.2,
    action: SwipeAction.blank
  );

  marketsBox = await Hive.openBox<Market>('markets');

  // remember which questions we've seen
  qIndex = marketsBox.get("qIndex") ?? cacheSize;

  marketsBox.put(testMarket.id, testMarket);

  print(marketsBox.get(testMarket.id)?.question);

  runApp(const HunchApp());
}

class HunchApp extends StatelessWidget {
  const HunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hunch',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'System',
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: SafeArea(
              bottom: false,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Streak
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              right: BorderSide(color: Colors.black, width: 3)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hunches Made',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '23',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Brand
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'Hunch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ),
                    // Accuracy
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(color: Colors.black, width: 3)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ACCURACY',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '68.4%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? const FeedScreen()
                : const HunchesScreen(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.bug_report),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TestImageScreen()),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 3)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.layers, size: 24),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 24),
              label: 'Hunches',
            ),
          ],
        ),
      ),
    );
  }
}
