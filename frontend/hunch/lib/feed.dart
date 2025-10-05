// feed.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import 'globals.dart';
import 'market.dart';
import 'database.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  final _prefetchCount = 4;

  void _prefetchNextImages() {
    final end = math.min(_prefetchCount, infoCache.length);
    for (int i = 0; i < end; i++) {
      final imageUrl = infoCache[i]['image_url'];
      if (imageUrl != null && (imageUrl as String).isNotEmpty) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    }
  }

  void _onCardSwiped() {
    setState(() {
      if (infoCache.isEmpty && qIndex >= questionIds.length) {
        _allComplete = true;
      }
    });
    _prefetchNextImages();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loadingCache, // your global ValueNotifier<bool>
      builder: (context, isLoading, child) {
        // Show completion state only AFTER final swipe
        if (infoCache.isEmpty) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
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
        }

        // Normal card stack
        return Stack(
          children: [
            if (infoCache.length > 1)
              Positioned.fill(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                    child: CardContent(
                      data: infoCache[1],
                      isActive: false,
                    ),
                  ),
                ),
              ),
            if (infoCache.isNotEmpty)
              Center(
                child: SwipeableCard(
                  data: infoCache[0],
                  onSwiped: _onCardSwiped,
                  showInstructions: qIndex == cacheSize,
                ),
              ),
          ],
        );
      },
    );
  }
}

// Shared card content component - single source of truth for card presentation

class CardContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isActive;

  const CardContent({super.key, required this.data, this.isActive = false});

  @override
  State<CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<CardContent> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;

  @override
  void initState() {
    print('CardContent initState called');
    print('Data in initState: ${widget.data}');
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant CardContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldUrl = oldWidget.data['video_url'] as String?;
    final newUrl = widget.data['video_url'] as String?;

    // Reinitialize video if the URL changed
    if (oldUrl != newUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _error = null;
      _initVideo();
    }

    if (oldWidget.isActive != widget.isActive) {
      _updatePlaybackState();
    }
  }

  void _initVideo() {
    final videoUrl = widget.data['video_url'] as String?;

    // Clean up old controller if the video changed
    if (_controller != null &&
        _controller!.dataSource != videoUrl &&
        videoUrl != null &&
        videoUrl.isNotEmpty) {
      _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }

    // Skip if no valid URL or already initializing
    if (_isInitializing || videoUrl == null || videoUrl.isEmpty) return;

    _isInitializing = true;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
        _isInitializing = false;
        _error = null;
      });
      controller.setLooping(true);
      if (widget.isActive) {
        controller.play();
      }
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isInitializing = false;
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _updatePlaybackState() {
    if (_controller == null) return;
    if (widget.isActive) {
      _controller!.play();
    } else {
      _controller!.pause();
    }
  }

  Widget _buildMedia() {
    final videoUrl = widget.data['video_url'] as String?;
    final imageUrl = widget.data['image_url'] as String?;

    // Always attempt to init if we have a valid video URL
    if (videoUrl != null && videoUrl.isNotEmpty) {
      if ((_controller == null || !_isInitialized) && _error == null) {
        _initVideo();
      }

      if (_error != null) {
        // Fallback to image if video failed
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Image.network(imageUrl,
              fit: BoxFit.cover, width: double.infinity);
        }
        return const Center(
          child:
              Text('Video failed to load', style: TextStyle(color: Colors.red)),
        );
      }

      if (_isInitialized && _controller != null) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    // Fall back to image if no video
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity);
    }

    // Default placeholder
    return Container(color: const Color(0xFFE5E5E5));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image or Video
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: _buildMedia(),
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
                (widget.data['question'] ?? '') as String,
                textAlign: TextAlign.center,
                maxLines: 4,
                minFontSize: 16,
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
            child: MarkdownBody(
              data: (widget.data['description'] ?? '') as String,
              selectable: false,
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Colors.black.withOpacity(0.5),
                  height: 1.3,
                ),
                h1: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Colors.black,
                ),
                h2: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Colors.black,
                ),
                h3: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: Colors.black,
                ),
                blockquote: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.black.withOpacity(0.6),
                ),
                code: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.8),
                ),
                listBullet: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.5),
                ),
                blockSpacing: 8,
                listIndent: 16,
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

  void updateCache(List<int> pastQIDS) async {
    loadingCache.value = true;
    infoCache.addAll(await getUnansweredQuestions(cacheSize, pastQIDS));
    loadingCache.value = false;
  }

  Future<void> onSwipe(SwipeAction action) async {
    if (infoCache.isEmpty) {
      return;
    }
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
    infoCache.removeAt(0);
    if (infoCache.length <= cacheSize / 2) {
      // before fetching new questions, send most recent answers to supabase
      sendAnswers(answerList);
      answerList.clear();

      // final nextIds = [questionIds[qIndex]];

      // final questions = await getQuestionsByIds(nextIds);
      // if (questions.isNotEmpty) {
      //   infoCache.add(questions[0]);
      // }

      // get the question ids of the pat ones
      List<int> pastQIDS = getCacheQIDs(infoCache);

      for (Answer a in answerList) {
        pastQIDS.add(a.questionId);
      }

      updateCache(pastQIDS);
    }
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 40),
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
                        child: CardContent(
                          data: widget.data,
                          isActive: true,
                        ),
                      ),
                      // Yes/No overlays - centered on the card itself
                      if (_dragX < -40)
                        Center(
                          child: Opacity(
                            opacity: ((_dragX.abs() - 40) / 60).clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                border:
                                    Border.all(color: Colors.black, width: 3),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA3E635),
                                border:
                                    Border.all(color: Colors.black, width: 3),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
