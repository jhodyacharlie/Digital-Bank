import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MascotMood { happy, waving, scanning }

class MyBcaMascot extends StatefulWidget {
  const MyBcaMascot({
    super.key,
    this.size = 76,
    this.mood = MascotMood.happy,
    this.speechText,
    this.onTap,
  });

  final double size;
  final MascotMood mood;
  final String? speechText;
  final VoidCallback? onTap;

  @override
  State<MyBcaMascot> createState() => _MyBcaMascotState();
}

class _MyBcaMascotState extends State<MyBcaMascot>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _blinkCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceCtrl.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_floatCtrl, _blinkCtrl, _bounceCtrl]),
            builder: (context, _) {
              final floatOffset = math.sin(_floatCtrl.value * math.pi) * 4.5;
              final bounceScale =
                  1.0 + math.sin(_bounceCtrl.value * math.pi) * 0.14;
              final waveAngle =
                  math.sin(_floatCtrl.value * 2 * math.pi) *
                  (widget.mood == MascotMood.waving ? 0.35 : 0.12);

              final blinkPhase = _blinkCtrl.value;
              final eyeScaleY = (blinkPhase > 0.90 && blinkPhase < 0.97)
                  ? 0.15
                  : 1.0;

              return Transform.translate(
                offset: Offset(0, -floatOffset),
                child: Transform.scale(
                  scale: bounceScale,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CustomPaint(
                      painter: _MascotPainter(
                        eyeScaleY: eyeScaleY,
                        waveAngle: waveAngle,
                        pulse: _floatCtrl.value,
                        mood: widget.mood,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.speechText != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.speechText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.eyeScaleY,
    required this.waveAngle,
    required this.pulse,
    required this.mood,
  });

  final double eyeScaleY;
  final double waveAngle;
  final double pulse;
  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.94),
        width: w * 0.52,
        height: h * 0.08,
      ),
      shadowPaint,
    );

    if (mood == MascotMood.scanning) {
      final ringPaint = Paint()
        ..color = const Color(0xFF64B5F6).withValues(alpha: 0.45 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(
        Offset(cx, h * 0.52),
        w * (0.40 + pulse * 0.18),
        ringPaint,
      );
    }

    final stemPaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, h * 0.19), Offset(cx, h * 0.09), stemPaint);
    final coinPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(Offset(cx, h * 0.08), w * 0.065, coinPaint);
    canvas.drawCircle(
      Offset(cx, h * 0.08),
      w * 0.04,
      Paint()..color = const Color(0xFFFFE082),
    );

    final armPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(w * 0.17, h * 0.58);
    canvas.rotate(-0.2 + waveAngle * 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.14, height: h * 0.24),
        Radius.circular(w * 0.07),
      ),
      armPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(w * 0.83, h * 0.54);
    canvas.rotate(0.25 - waveAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.14, height: h * 0.24),
        Radius.circular(w * 0.07),
      ),
      armPaint,
    );
    canvas.restore();

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.55),
        width: w * 0.64,
        height: h * 0.68,
      ),
      Radius.circular(w * 0.28),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E88E5), Color(0xFF004B93)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.46),
        width: w * 0.48,
        height: h * 0.26,
      ),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(visorRect, Paint()..color = const Color(0xFF061B36));

    final eyePaint = Paint()..color = const Color(0xFF4FC3F7);
    final leftEyeCenter = Offset(cx - w * 0.11, h * 0.45);
    final rightEyeCenter = Offset(cx + w * 0.11, h * 0.45);
    final eyeW = w * 0.085;
    final eyeH = h * 0.095 * eyeScaleY;

    canvas.drawOval(
      Rect.fromCenter(center: leftEyeCenter, width: eyeW, height: eyeH),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rightEyeCenter, width: eyeW, height: eyeH),
      eyePaint,
    );

    if (eyeScaleY > 0.5) {
      final glint = Paint()..color = Colors.white;
      canvas.drawCircle(
        leftEyeCenter.translate(-eyeW * 0.18, -eyeH * 0.2),
        w * 0.018,
        glint,
      );
      canvas.drawCircle(
        rightEyeCenter.translate(-eyeW * 0.18, -eyeH * 0.2),
        w * 0.018,
        glint,
      );
    }

    final smilePaint = Paint()
      ..color = const Color(0xFF81D4FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * 0.51),
        width: w * 0.14,
        height: h * 0.07,
      ),
      0.15,
      math.pi - 0.3,
      false,
      smilePaint,
    );

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.72),
        width: w * 0.32,
        height: h * 0.13,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'myBCA',
        style: TextStyle(
          color: const Color(0xFF004B93),
          fontSize: w * 0.085,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, h * 0.72 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.eyeScaleY != eyeScaleY ||
      old.waveAngle != waveAngle ||
      old.pulse != pulse ||
      old.mood != mood;
}
