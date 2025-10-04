// main.dart
import 'package:flutter/material.dart';
import 'package:hunch/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feed.dart';
import 'hunches.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://benwvphuubnrzdlhvjzu.supabase.co',
    // dont flame it is anon key
    anonKey: 'sb_publishable_JiGhx5v95JaN977zMHHlRA_A2nn7wnT',
  );

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
