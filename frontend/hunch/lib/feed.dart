
// feed.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PredictionCard {
  final String question;
  final String context;
  final String imageUrl;

  PredictionCard({
    required this.question,
    required this.context,
    required this.imageUrl,
  });
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Streak
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.black, width: 3)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STREAK',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '23',
                          style: TextStyle(
                            fontSize: 32,
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
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Hunch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                // Accuracy
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.black, width: 3)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ACCURACY',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '68.4%',
                          style: TextStyle(
                            fontSize: 32,
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
        // Card Stack
        const Expanded(
          child: CardStack(),
        ),
      ],
    );
  }
}

class CardStack extends StatefulWidget {
  const CardStack({super.key});

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> {
  int currentCard = 0;
  final List<PredictionCard> cards = [
    PredictionCard(
      question: 'Trump wins Pennsylvania',
      context: 'Nov 5 → Nov 8',
      imageUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&q=80',
    ),
    PredictionCard(
      question: 'Bitcoin closes above \$70k this week',
      context: 'Sunday 11:59pm EST',
      imageUrl: 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?w=800&q=80',
    ),
    PredictionCard(
      question: 'OpenAI announces GPT-5 before December',
      context: 'Official announcement only',
      imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
    ),
    PredictionCard(
      question: 'S&P 500 breaks 6000 this month',
      context: 'Intraday high counts',
      imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&q=80',
    ),
    PredictionCard(
      question: 'Major studio film uses AI actor in lead role',
      context: 'Theatrical release by Dec 31',
      imageUrl: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=800&q=80',
    ),
  ];

  void _onCardSwiped() {
    setState(() {
      if (currentCard < cards.length - 1) {
        currentCard++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentCard >= cards.length) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(56),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(8, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Complete',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Check back tonight',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Next card peek
        if (currentCard < cards.length - 1)
          Center(
            child: Transform.scale(
              scale: 0.94,
              child: Opacity(
                opacity: 0.35,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
              ),
            ),
          ),
        // Active card
        Center(
          child: SwipeableCard(
            card: cards[currentCard],
            onSwiped: _onCardSwiped,
            showInstructions: currentCard == 0,
          ),
        ),
      ],
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final PredictionCard card;
  final VoidCallback onSwiped;
  final bool showInstructions;

  const SwipeableCard({
    super.key,
    required this.card,
    required this.onSwiped,
    this.showInstructions = false,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  double _dragX = 0;
  bool _isDragging = false;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _isDragging = true;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragX.abs() > 80) {
      widget.onSwiped();
      setState(() {
        _dragX = 0;
        _isDragging = false;
      });
    } else {
      setState(() {
        _dragX = 0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragX * 0.03 / 180 * math.pi;
    final opacity = (1 - _dragX.abs() / 500).clamp(0.0, 1.0);
    final scale = (1 - _dragX.abs() / 3000).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Card
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(8, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Image
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                            ),
                            child: Image.network(
                              widget.card.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: const Color(0xFFE5E5E5));
                              },
                            ),
                          ),
                        ),
                        // Question
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                            child: Center(
                              child: Text(
                                widget.card.question,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Context
                        Container(
                          color: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              widget.card.context,
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Swipe indicators
          if (_dragX < -40)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 100,
              child: Opacity(
                opacity: ((_dragX.abs() - 40) / 60).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(_dragX, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_dragX > 40)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 100,
              child: Opacity(
                opacity: ((_dragX.abs() - 40) / 60).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(_dragX, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA3E635),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Instructions overlay
          if (widget.showInstructions)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(6, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '← No',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 32),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.black26,
                      ),
                      const SizedBox(width: 32),
                      const Text(
                        'Yes →',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA3E635),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}