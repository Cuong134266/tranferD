import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom track shape: gradient 3 màu + 2 dots tại 30% và 70%
/// Dot tại 30%: "Nhận tiền nhanh" — white fill + green border khi thumb vượt qua
/// Dot tại 70%: "Lãi cao hơn" — white fill + yellow border khi thumb vượt qua
class GradientSliderTrackShape extends SliderTrackShape {
  final double sliderValue; // 0.0 → 1.0, để tô màu dot

  const GradientSliderTrackShape({this.sliderValue = 0.0});

  static const double _dot1Frac = 0.30; // 30%
  static const double _dot2Frac = 0.70; // 70%
  static const double _dotRadius = 4.0; // 8×8 dot

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 12;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final radius = Radius.circular(trackRect.height / 2);
    final RRect rRect = RRect.fromRectAndRadius(trackRect, radius);

    // ── Background track — full gradient 20% opacity ──
    final Paint bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(trackRect.left, 0),
        Offset(trackRect.right, 0),
        [
          AppTheme.sliderUptrend.withValues(alpha: 0.20),
          AppTheme.sliderSideways.withValues(alpha: 0.20),
          AppTheme.sliderDowntrend.withValues(alpha: 0.20),
        ],
        [0.0, 0.7381, 1.0],
      );
    context.canvas.drawRRect(rRect, bgPaint);

    // ── Active track — clipped to thumb position ──
    final double thumbX = thumbCenter.dx;
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbX,
      trackRect.bottom,
    );
    if (activeRect.width > 0) {
      final RRect activeRRect = RRect.fromRectAndCorners(
        activeRect,
        topLeft: radius,
        bottomLeft: radius,
      );
      final Paint activePaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(trackRect.left, 0),
          Offset(trackRect.right, 0),
          [
            AppTheme.sliderUptrend,
            AppTheme.sliderSideways,
            AppTheme.sliderDowntrend,
          ],
          [0.0, 0.7381, 1.0],
        );
      context.canvas.drawRRect(activeRRect, activePaint);
    }

    // ── Dots tại 30% và 70% ──
    final double trackCenterY = trackRect.top + trackRect.height / 2;

    _drawDot(
      context.canvas,
      trackRect,
      trackCenterY,
      fraction: _dot1Frac,
      passed: sliderValue >= _dot1Frac,
      passedBorderColor: AppTheme.sliderUptrend,
      unpasedBorderColor: const Color(0xFFB5C1D3),
    );

    _drawDot(
      context.canvas,
      trackRect,
      trackCenterY,
      fraction: _dot2Frac,
      passed: sliderValue >= _dot2Frac,
      passedBorderColor: AppTheme.sliderSideways,
      unpasedBorderColor: const Color(0xFFB5C1D3),
    );
  }

  void _drawDot(
    Canvas canvas,
    Rect trackRect,
    double centerY, {
    required double fraction,
    required bool passed,
    required Color passedBorderColor,
    required Color unpasedBorderColor,
  }) {
    final double cx = trackRect.left + trackRect.width * fraction;
    final Offset center = Offset(cx, centerY);

    // Fill: trắng
    canvas.drawCircle(center, _dotRadius, Paint()..color = Colors.white);

    // Border: màu theo trạng thái
    canvas.drawCircle(
      center,
      _dotRadius,
      Paint()
        ..color = passed ? passedBorderColor : unpasedBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

/// Custom thumb shape — khớp Figma node 73:2075
/// Frame 18×18 (white fill + #307A62 stroke) + Ellipse 10×10 (#307A62 fill)
class CustomThumbShape extends SliderComponentShape {
  // Figma: Frame 18×18 → bán kính 9
  final double outerRadius;
  // Figma: Ellipse 10×10 → bán kính 5
  final double innerRadius;
  // Figma stroke color & fill color: rgba(48,122,98,1)
  static const Color _green = Color(0xFF307A62);

  const CustomThumbShape({this.outerRadius = 9.0, this.innerRadius = 5.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isInteractive) =>
      Size.fromRadius(outerRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 1),
      outerRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Vòng ngoài: white fill
    canvas.drawCircle(center, outerRadius, Paint()..color = Colors.white);

    // Viền ngoài: #307A62, strokeWidth = 1.5 (Figma default stroke)
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = _green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Vòng trong: #307A62 fill (Ellipse 10×10 → r=5)
    canvas.drawCircle(center, innerRadius, Paint()..color = _green);
  }
}

/// Labels bên dưới slider track, căn theo vị trí dot 30% và 60%
/// Dot thực được vẽ trên Canvas trong GradientSliderTrackShape
class SliderMarkersRow extends StatelessWidget {
  final double sliderValue;
  const SliderMarkersRow({super.key, this.sliderValue = 0.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        const double dot1Frac = 0.30;
        const double dot2Frac = 0.60;

        return SizedBox(
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Label "Nhận tiền nhanh" căn giữa tại 30%
              Positioned(
                left: w * dot1Frac,
                top: 0,
                child: _MarkerLabel(
                  label: 'Nhận tiền nhanh',
                  active: sliderValue >= dot1Frac,
                ),
              ),
              // Label "Lãi cao hơn" căn giữa tại 60%
              Positioned(
                left: w * dot2Frac,
                top: 0,
                child: _MarkerLabel(
                  label: 'Lãi cao hơn',
                  active: sliderValue >= dot2Frac,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarkerLabel extends StatelessWidget {
  final String label;
  final bool active;
  const _MarkerLabel({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.5, 0), // căn giữa text dưới dot
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Be Vietnam Pro',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: active
              ? const ui.Color.fromARGB(
                  255,
                  43,
                  49,
                  58,
                ) // text-color/sub-4 khi đã qua
              : const Color(0xFFB5C1D3), // text-color/sub-2 mặc định
        ),
      ),
    );
  }
}
