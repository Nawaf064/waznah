import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ios_style.dart';

/// Startup branding; cold launches can defer destination initialization.
class WaznahIntro extends StatefulWidget {
  const WaznahIntro({
    super.key,
    required this.child,
    this.wordmark,
    this.onCompleted,
    this.firstFrameReady,
    this.deferDestination = false,
  });
  final bool deferDestination;
  final Future<void>? firstFrameReady;
  final VoidCallback? onCompleted;
  final Widget child;
  // Replace this slot with the approved wordmark without changing the animation.
  final Widget? wordmark;
  @override
  State<WaznahIntro> createState() => _WaznahIntroState();
}

class _WaznahIntroState extends State<WaznahIntro>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  bool _finished = false;
  bool _started = false;
  late bool _destinationMounted;
  bool _wasBackgrounded = false;
  @override
  void initState() {
    super.initState();
    _destinationMounted = !widget.deferDestination;
    WidgetsBinding.instance.addObserver(this);
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3600),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _finished = true;
              _destinationMounted = true;
            });
            widget.onCompleted?.call();
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _finished = true;
      _destinationMounted = true;
      _animation.stop();
    } else if (!_started && !_finished) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Building the first frame does not mean Android has displayed it yet.
        await widget.firstFrameReady;
        if (mounted && !_finished && !_wasBackgrounded) _animation.forward();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
      _animation.stop();
    } else if (state == AppLifecycleState.resumed) {
      final replay = _wasBackgrounded;
      _wasBackgrounded = false;
      if (replay &&
          !MediaQuery.disableAnimationsOf(context) &&
          (widget.onCompleted == null || !_finished)) {
        setState(() => _finished = false);
        _animation.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: !_finished,
        child: IgnorePointer(
          ignoring: !_finished,
          child: _destinationMounted
              ? RepaintBoundary(child: widget.child)
              : const ColoredBox(color: waznahBackground),
        ),
      ),
      if (!_finished)
        Positioned.fill(
          child: BlockSemantics(
            child: Semantics(
              label: 'وزنة، جارٍ فتح التطبيق',
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final t = _animation.value;
                    final zoom = Curves.easeInOutCubic.transform(
                      ((t - .45) / .3).clamp(0.0, 1.0),
                    );
                    final reveal = Curves.easeOut.transform(
                      ((t - .65) / .2).clamp(0.0, 1.0),
                    );
                    final fade = ((t - .92) / .08).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: 1 - fade,
                      child: ColoredBox(
                        color: waznahBackground,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                key: const ValueKey('intro-zoom'),
                                scale: 1.8 - zoom,
                                child: CustomPaint(
                                  size: const Size(150, 150),
                                  painter: _WrenchPainter(
                                    turns:
                                        Curves.easeOutCubic.transform(
                                          (t / .65).clamp(0.0, 1.0),
                                        ) *
                                        5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Opacity(
                                key: const ValueKey('intro-wordmark'),
                                opacity: reveal,
                                child: Transform.translate(
                                  offset: Offset(0, 18 * (1 - reveal)),
                                  child:
                                      widget.wordmark ??
                                      const SteelFinish(
                                        child: Text(
                                          'وزنة',
                                          style: TextStyle(
                                            inherit: false,
                                            fontFamily: 'WaznahArabic',
                                            fontSize: 48,
                                            fontWeight: FontWeight.w800,
                                            color: waznahInk,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _WrenchPainter extends CustomPainter {
  const _WrenchPainter({required this.turns});
  final double turns;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final nut = Path()..fillType = PathFillType.evenOdd;
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = math.cos(angle) * 23, y = math.sin(angle) * 23;
      if (i == 0) {
        nut.moveTo(x, y);
      } else {
        nut.lineTo(x, y);
      }
    }
    nut.close();
    nut.addOval(const Rect.fromLTWH(-9, -9, 18, 18));
    canvas.drawPath(nut, Paint()..color = waznahInk);
    canvas.save();
    canvas.rotate(turns * math.pi * 2);
    final wrench = Path()
      ..moveTo(-25, -25)
      ..lineTo(-16, -30)
      ..lineTo(-16, 7)
      ..lineTo(0, 17)
      ..lineTo(16, 7)
      ..lineTo(16, -30)
      ..lineTo(25, -25)
      ..quadraticBezierTo(40, 12, 14, 29)
      ..lineTo(12, 61)
      ..quadraticBezierTo(0, 76, -12, 61)
      ..lineTo(-14, 29)
      ..quadraticBezierTo(-40, 12, -25, -25)
      ..close();
    canvas.drawPath(
      wrench,
      Paint()
        ..shader = waznahSteel.createShader(
          const Rect.fromLTWH(-40, -30, 80, 106),
        ),
    );
    canvas.drawPath(
      wrench,
      Paint()
        ..color = waznahPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(0, 58),
      4,
      Paint()..color = waznahBackground,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WrenchPainter oldDelegate) => turns != oldDelegate.turns;
}
