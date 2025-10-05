// hunches.dart
import 'package:flutter/material.dart';
import 'getaggstats.dart';

class HunchesScreen extends StatefulWidget {
  const HunchesScreen({super.key});

  @override
  State<HunchesScreen> createState() => _HunchesScreenState();
}

class _HunchesScreenState extends State<HunchesScreen> {
  // Mock data - replace with actual state management
  final List<ActiveHunch> _activeHunches = const [
    ActiveHunch(
      question: 'Trump wins Pennsylvania',
      context: 'Nov 5 → Nov 8',
      userChoice: true,
      marketConsensus: 67,
      imageUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&q=80',
    ),
    ActiveHunch(
      question: 'Bitcoin closes above \$70k this week',
      context: 'Sunday 11:59pm EST',
      userChoice: false,
      marketConsensus: 43,
      imageUrl: 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?w=800&q=80',
    ),
    ActiveHunch(
      question: 'OpenAI announces GPT-5 before December',
      context: 'Official announcement only',
      userChoice: true,
      marketConsensus: 28,
      imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _runGetStatsOnce();
  }

  Future<void> _runGetStatsOnce() async {
    try {
      final stats = await getStats();
      print('getStats() returned: ' + stats.toString());
    } catch (e, st) {
      print('getStats() failed: ' + e.toString());
      print(st.toString());
    }
  }

  double _calculateAverageGap() {
    if (_activeHunches.isEmpty) return 0;
    double totalGap = 0;
    for (var hunch in _activeHunches) {
      final impliedOdds = hunch.userChoice ? 100.0 : 0.0;
      totalGap += (impliedOdds - hunch.marketConsensus).abs();
    }
    return totalGap / _activeHunches.length;
  }

  @override
  Widget build(BuildContext context) {
    final avgGap = _calculateAverageGap();

    return Column(
      children: [
        // Stats bar
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
                  // Total hunches
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.black, width: 3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_activeHunches.length}',
                            style: const TextStyle(
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
                  // Average gap
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.black, width: 3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AVG GAP',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '±${avgGap.toStringAsFixed(0)}%',
                            style: const TextStyle(
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
                  // Pending resolution
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PENDING',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_activeHunches.length}',
                            style: const TextStyle(
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
        // Card list
        Expanded(
          child: _activeHunches.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No active hunches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _activeHunches.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: HunchCard(hunch: _activeHunches[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class HunchCard extends StatelessWidget {
  final ActiveHunch hunch;

  const HunchCard({super.key, required this.hunch});

  ConvictionLevel _calculateConviction() {
    final impliedOdds = hunch.userChoice ? 100.0 : 0.0;
    final gap = (impliedOdds - hunch.marketConsensus).abs();
    
    if (gap <= 15) return ConvictionLevel.aligned;
    if (gap <= 40) return ConvictionLevel.moderate;
    return ConvictionLevel.strong;
  }

  GradientColors _getGradientColors(ConvictionLevel level) {
    switch (level) {
      case ConvictionLevel.aligned:
        return GradientColors(
          start: const Color(0xFF64748B), // slate
          end: const Color(0xFF94A3B8),   // slate-light
        );
      case ConvictionLevel.moderate:
        return GradientColors(
          start: const Color(0xFFF59E0B), // amber
          end: const Color(0xFFFB923C),   // orange
        );
      case ConvictionLevel.strong:
        return GradientColors(
          start: const Color(0xFFEC4899), // pink
          end: const Color(0xFF8B5CF6),   // violet
        );
    }
  }

  String _getConvictionLabel(ConvictionLevel level) {
    switch (level) {
      case ConvictionLevel.aligned:
        return 'Consensus aligned';
      case ConvictionLevel.moderate:
        return 'Moderate divergence';
      case ConvictionLevel.strong:
        return 'Strong conviction';
    }
  }

  @override
  Widget build(BuildContext context) {
    final conviction = _calculateConviction();
    final gradientColors = _getGradientColors(conviction);
    final impliedOdds = hunch.userChoice ? 100.0 : 0.0;
    final edge = impliedOdds - hunch.marketConsensus;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header with user choice
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradientColors.start, gradientColors.end],
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User choice
                Text(
                  hunch.userChoice ? 'YES' : 'NO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Edge indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '${edge >= 0 ? '+' : ''}${edge.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Question section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hunch.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hunch.context,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Market data section
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(
                top: BorderSide(color: Colors.black, width: 3),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Market consensus
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MARKET',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hunch.marketConsensus}%',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                // Conviction label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    _getConvictionLabel(conviction),
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data models
class ActiveHunch {
  final String question;
  final String context;
  final bool userChoice; // true = YES, false = NO
  final int marketConsensus; // 0-100%
  final String imageUrl;

  const ActiveHunch({
    required this.question,
    required this.context,
    required this.userChoice,
    required this.marketConsensus,
    required this.imageUrl,
  });
}

enum ConvictionLevel {
  aligned,   // 0-15% gap
  moderate,  // 15-40% gap
  strong,    // 40%+ gap
}

class GradientColors {
  final Color start;
  final Color end;

  GradientColors({required this.start, required this.end});
}