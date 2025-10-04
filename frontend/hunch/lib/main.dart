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
import 'auth.dart';

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

  // infoCache = await getQuestionsByIds(questionIds.sublist(0, cacheSize));
  infoCache = await getUnansweredQuestions(cacheSize, []);
  // final testMarket = Market(f
  //   id: "111",
  //   question: "HI?!",
  //   description: "ajsdfnjksd,nfkshb",
  //   price: 0.2,
  //   action: SwipeAction.blank
  // );

  marketsBox = await Hive.openBox<Market>('markets');

  // remember which questions we've seen
  // qIndex = marketsBox.get("qIndex") ?? cacheSize;

  // marketsBox.put(testMarket.id, testMarket);

  // print(marketsBox.get(testMarket.id)?.question);

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
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

final disableAuth = false;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check if user is signed in
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (disableAuth || session != null) {
          return const MainScreen();
        } else {
          return AuthScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _breathingController;
  late Animation<double> _translateYAnimation;
  late Animation<double> _scaleYAnimation;
  late Animation<double> _scaleXAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _translateYAnimation = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleYAnimation = Tween<double>(
      begin: 1.02,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleXAnimation = Tween<double>(
      begin: 0.99,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 70,
        title: AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _translateYAnimation.value),
              child: Transform.scale(
                scaleY: _scaleYAnimation.value,
                scaleX: _scaleXAnimation.value,
                filterQuality: FilterQuality.medium,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            // decoration: BoxDecoration(
            //   color: Colors.black,
            //   border: Border.all(color: Colors.black, width: 3),
            // ),
            child: Image.asset(
              'assets/hunch_logo.jpeg',
              width: 150,
              height: 40,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 3),
        ),
      ),
      body: _selectedIndex == 0 ? const FeedScreen() : const HunchesScreen(),
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


