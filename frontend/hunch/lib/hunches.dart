// hunches.dart
import 'package:flutter/material.dart';

class HunchesScreen extends StatelessWidget {
  const HunchesScreen({super.key});

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
    return Column(
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
          child: Center(
            child: Text(
              'Hunches',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
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