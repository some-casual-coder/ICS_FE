import 'package:flutter/material.dart';

class SwipeTutorialOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const SwipeTutorialOverlay({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();
}

class _SwipeTutorialOverlayState extends State<SwipeTutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _lineOpacityAnimation;
  int _currentStep = 0;
  final int _totalSteps = 4;

  final List<Map<String, dynamic>> _swipeInstructions = [
    {
      'text': 'Swipe right if interested',
      'start': const Offset(-0.3, 0),
      'end': const Offset(0.3, 0),
      'color': Colors.green,
      'icon': Icons.swipe_right_outlined,
    },
    {
      'text': 'Swipe left if not interested',
      'start': const Offset(0.3, 0),
      'end': const Offset(-0.3, 0),
      'color': Colors.red,
      'icon': Icons.swipe_left_outlined,
    },
    {
      'text': "Swipe up if you've watched and liked",
      'start': const Offset(0, 0.3),
      'end': const Offset(0, -0.3),
      'color': Colors.blue,
      'icon': Icons.swipe_up_outlined,
    },
    {
      'text': "Swipe down if you're not sure",
      'start': const Offset(0, -0.3),
      'end': const Offset(0, 0.3),
      'color': Colors.orange,
      'icon': Icons.swipe_down_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _swipeAnimation = Tween<Offset>(
      begin: _swipeInstructions[_currentStep]['start'],
      end: _swipeInstructions[_currentStep]['end'],
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _lineOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
    ));

    _swipeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            if (_currentStep < _totalSteps - 1) {
              setState(() {
                _currentStep++;
                _setupAnimations();
                _swipeController.forward(from: 0.0);
              });
            } else {
              widget.onClose();
            }
          }
        });
      }
    });

    _swipeController.forward();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _swipeController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Swipe motion lines
                    // ...List.generate(2, (index) {
                    //   final offset =
                    //       _swipeAnimation.value * ((index + 1) * 0.5);
                    //   return Opacity(
                    //     opacity: _lineOpacityAnimation.value * 0.5,
                    //     child: Transform.translate(
                    //       offset: Offset(
                    //         offset.dx * MediaQuery.of(context).size.width,
                    //         offset.dy * MediaQuery.of(context).size.height,
                    //       ),
                    //       child: Container(
                    //         width: 20,
                    //         height: 2,
                    //         decoration: BoxDecoration(
                    //           color: Colors.white,
                    //           borderRadius: BorderRadius.circular(1),
                    //         ),
                    //       ),
                    //     ),
                    //   );
                    // }),
                    // Hand icon
                    Transform.translate(
                      offset: Offset(
                        _swipeAnimation.value.dx *
                            MediaQuery.of(context).size.width,
                        _swipeAnimation.value.dy *
                            MediaQuery.of(context).size.height,
                      ),
                      child: Icon(
                        _swipeInstructions[_currentStep]['icon'],
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Instruction text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              _swipeInstructions[_currentStep]['text'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}
