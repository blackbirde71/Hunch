import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: SafeArea(child: HunchesScreen())),
  ));
}

class HunchesScreen extends StatelessWidget {
  const HunchesScreen({super.key});

  final List<ActiveHunch> _activeHunches = const [
    ActiveHunch(
      question: 'Trump wins Pennsylvania',
      marketConsensus: 99,
      hackathonConsensus: 45,
      userBet: SwipeAction.yes,
    ),
    ActiveHunch(
      question: 'Bitcoin closes above \$70k this week',
      marketConsensus: 3,
      hackathonConsensus: 95,
      userBet: SwipeAction.no,
    ),
    ActiveHunch(
      question: 'OpenAI announces GPT-5 before December',
      marketConsensus: 28,
      hackathonConsensus: 35,
      userBet: SwipeAction.yes,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _activeHunches.length;
    final avgPolymarketDiff = _activeHunches
            .map((h) => (100 -
                (h.marketConsensus -
                        (h.userBet == SwipeAction.yes ? 100 : 0))
                    .abs()))
            .reduce((a, b) => a + b) /
        total;
    final avgHackHarvardDiff = _activeHunches
            .map((h) => (100 -
                (h.hackathonConsensus -
                        (h.userBet == SwipeAction.yes ? 100 : 0))
                    .abs()))
            .reduce((a, b) => a + b) /
        total;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 🔲 Unified Header Summary
        Container(
          height: 90,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 3)),
            boxShadow: [
              BoxShadow(color: Colors.black, offset: Offset(3, 3)),
            ],
          ),
          child: Row(
            children: [
              _SummaryCell(
                title: 'Number of hunches made:',
                value: '$total',
                showRightBorder: true,
              ),
              _SummaryCell(
                title: 'How similar to Polymarket:',
                value: '${avgPolymarketDiff.toStringAsFixed(0)}%',
                showRightBorder: true,
              ),
              _SummaryCell(
                title: 'How similar to HackHarvard:',
                value: '${avgHackHarvardDiff.toStringAsFixed(0)}%',
                showRightBorder: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const _Legend(),
        const SizedBox(height: 20),

        for (final h in _activeHunches)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: HunchCard(hunch: h),
          ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String title;
  final String value;
  final bool showRightBorder;
  const _SummaryCell({
    required this.title,
    required this.value,
    required this.showRightBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: showRightBorder
                ? const BorderSide(color: Colors.black, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Stack(
          children: [
            // Title (top-left)
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),
            // Value (bottom-center)
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(color: Color(0xFF2563EB), label: 'Polymarket average'),
          SizedBox(height: 10),
          _LegendItem(color: Color(0xFFA51C30), label: 'HackHarvard average'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class HunchCard extends StatelessWidget {
  final ActiveHunch hunch;
  const HunchCard({super.key, required this.hunch});

  @override
  Widget build(BuildContext context) {
    final color = switch (hunch.userBet) {
      SwipeAction.yes => const Color(0xFF22C55E),
      SwipeAction.no => const Color(0xFFEF4444),
      _ => Colors.grey,
    };
    final label = switch (hunch.userBet) {
      SwipeAction.yes => 'YES',
      SwipeAction.no => 'NO',
      _ => '-',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hunch.question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: 'You predicted: ',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ConsensusBar(
            market: hunch.marketConsensus,
            hackathon: hunch.hackathonConsensus,
          ),
        ],
      ),
    );
  }
}

class ConsensusBar extends StatelessWidget {
  final double market;
  final double hackathon;
  const ConsensusBar({
    super.key,
    required this.market,
    required this.hackathon,
  });

  @override
  Widget build(BuildContext context) {
    const border = 3.0;
    const barHeight = 25.0;
    const tickWidth = 3.0;
    const crimson = Color(0xFFA51C30);
    const blue = Color(0xFF2563EB);
    const labelSpacing = 12.0;

    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth - border * 2;
      double px(double v) =>
          border + (v.clamp(0, 100) / 100) * (width - tickWidth);

      return SizedBox(
        height: barHeight + 2 * (labelSpacing + 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main bar
            Positioned(
              top: labelSpacing + 14,
              left: 0,
              right: 0,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: border),
                ),
              ),
            ),

            // HackHarvard tick
            Positioned(
              left: px(hackathon),
              top: labelSpacing + 14 + border,
              height: barHeight - border * 2,
              child: Container(width: tickWidth, color: crimson),
            ),

            // HackHarvard percentage (below bar)
            Positioned(
              left: (px(hackathon) - 10)
                  .clamp(border, c.maxWidth - border - 26),
              bottom: 0,
              child: Text(
                '${hackathon.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: crimson,
                ),
              ),
            ),

            // Polymarket percentage (above bar, aligned with tick center)
            Positioned(
              left: (px(market) - 10)
                  .clamp(border, c.maxWidth - border - 26),
              top: labelSpacing - 6, // adjust to vertically center with tick
              child: Text(
                '${market.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: blue,
                ),
              ),
            ),

            // Polymarket tick
            Positioned(
              left: px(market),
              top: labelSpacing + 14 + border,
              height: barHeight - border * 2,
              child: Container(width: tickWidth, color: blue),
            ),
          ],
        ),
      );
    });
  }
}

/// ---------- DATA ----------
class ActiveHunch {
  final String question;
  final double marketConsensus;
  final double hackathonConsensus;
  final SwipeAction userBet;
  const ActiveHunch({
    required this.question,
    required this.marketConsensus,
    required this.hackathonConsensus,
    required this.userBet,
  });
}

enum SwipeAction { yes, no, blank }

