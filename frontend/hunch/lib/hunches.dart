// hunches.dart
import 'package:flutter/material.dart';

class HunchesScreen extends StatelessWidget {
  const HunchesScreen({super.key});

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