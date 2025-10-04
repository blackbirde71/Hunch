// feed.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'globals.dart';
import 'market.dart';
import 'database.dart';
import 'package:auto_size_text/auto_size_text.dart';

Future<void> onSwipe(SwipeAction action) async {
  // Persist what the user just swiped on
  if (infoCache.isNotEmpty) {
    final current = infoCache[0];
    final market = Market(
      id: (current?['id'] ?? '').toString(),
      question: (current?['question'] ?? '') as String,
      description: (current?['description'] ?? '') as String,
      price: ((current?['yes_price']) as num?)?.toDouble() ?? 0.0,
      action: action,
    );

    String answerStr;
    switch (action) {
      case SwipeAction.yes:
        answerStr = "yes";
        break;
      case SwipeAction.no:
        answerStr = "no";
        break;
      case SwipeAction.blank:
        answerStr = "blank";
        break;
    }

    final answerRecord = Answer(
      questionId: current['id'] as int,
      answer: answerStr,
    );

    answerList.add(answerRecord);

    marketsBox.put(market.id, market);
  }

  // Remove the current card from the cache
  if (infoCache.length <= cacheSize / 2) {
    infoCache.removeAt(0);
  } else {
    // before fetching new questions, send most recent answers to supabase
    sendAnswers(answerList);
    answerList.clear();

    // final nextIds = [questionIds[qIndex]];

    // final questions = await getQuestionsByIds(nextIds);
    // if (questions.isNotEmpty) {
    //   infoCache.add(questions[0]);
    // }
    final cacheQIDs = getCacheQIDs(infoCache);
    final nextQs = await getUnansweredQuestions(cacheSize ~/ 2, cacheQIDs);
    infoCache.addAll(nextQs);
  }
}

List<int> getCacheQIDs(List<Map<String, dynamic>> infoCache) {
  List<int> ret = [];
  for (int i = 0; i < infoCache.length; i++) {
    final id = infoCache[i]['id'];
    if (id is int) ret.add(id);
  }
  return ret;
}


class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardStack();
  }
}

class CardStack extends StatefulWidget {
  const CardStack({super.key});

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> {
  bool _allComplete = false;

  void _onCardSwiped() {
    setState(() {
      if (infoCache.isEmpty && qIndex >= questionIds.length) {
        _allComplete = true;
      }
    });
  }

  Widget build(BuildContext context) {
    // Show completion state only AFTER final swipe
    if (_allComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            "You completed all hunches!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Peek card - only show if there's a next card
        if (infoCache.length > 1)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
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
                child: CardContent(data: infoCache[1]),
              ),
            ),
          ),
        // Active card - always swipeable when not complete
        Center(
          child: SwipeableCard(
            data: infoCache.isNotEmpty ? infoCache[0] : <String, dynamic>{},
            onSwiped: _onCardSwiped,
            showInstructions: qIndex == cacheSize,
          ),
        ),
      ],
    );
  }
}

// Shared card content component - single source of truth for card presentation

class CardContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const CardContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: (data['picture_data'] != null)
                ? Image.memory(
                    data['picture_data'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : Container(color: const Color(0xFFE5E5E5)),
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
              child: AutoSizeText(
                (data['question'] ?? '') as String,
                textAlign: TextAlign.center,
                maxLines: 4, // Prevent overflow; adjust as needed
                minFontSize: 16, // Don't shrink below this size
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
              (data['description'] ?? '') as String,
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
    );
  }
}



class SwipeableCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onSwiped;
  final bool showInstructions;

  const SwipeableCard({
    super.key,
    required this.data,
    required this.onSwiped,
    this.showInstructions = false,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  double _dragX = 0;
  double _dragY = 0;
  Offset _dragStart = Offset.zero;

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) async {
    if (_dragX.abs() > 80) {
      final action = _dragX > 0 ? SwipeAction.yes : SwipeAction.no;
      await onSwipe(action);
      widget.onSwiped();
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotation = (_dragX / MediaQuery.of(context).size.width) * 0.4;
    final opacity = (1 - _dragX.abs() / 500).clamp(0.0, 1.0);
    final scale = (1 - _dragX.abs() / 3000).clamp(0.0, 1.0);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Card with embedded Yes/No overlays
          Transform.translate(
            offset: Offset(_dragX, _dragY * 0.3),
            child: Transform.rotate(
              angle: rotation,
              alignment: Alignment.center,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Stack(
                    children: [
                      // Base card container
                      Container(
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
                        child: CardContent(data: widget.data),
                      ),
                      // Yes/No overlays - centered on the card itself
                      if (_dragX < -40)
                        Center(
                          child: Opacity(
                            opacity: ((_dragX.abs() - 40) / 60).clamp(0.0, 1.0),
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
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_dragX > 40)
                        Center(
                          child: Opacity(
                            opacity: ((_dragX.abs() - 40) / 60).clamp(0.0, 1.0),
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
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -0.5,
                                ),
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
          // Instructions overlay - fixed to screen, not card
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
