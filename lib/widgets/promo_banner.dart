import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  // Each banner: bgImage for full-image banners OR bgColor+illusAsset for code-drawn
  static const List<_BannerData> _banners = [
    // Banner 1: original img-banner.png (full landscape image, has built-in bg + illus)
    _BannerData(
      bgImage: 'assets/images/img-banner.png',
      subtitle: 'Sang tay — không mất lãi',
      title: 'Lãi đến 13.5%/năm ✦',
    ),
    // Banner 2: purple — Flutter Container bg + trophy/coin illus
    _BannerData(
      bgColor: Color(0xFF5C1EA8),
      illusAsset: 'assets/images/img-coin.png', // safe vault (dark outline, transparent)
      subtitle: 'Tiền gửi an toàn — lãi tự nhiên',
      title: 'Sang tên trong 24 giờ',
    ),
    // Banner 3: navy blue — Flutter Container bg + passbook illus (transparent PNG)
    _BannerData(
      bgColor: Color(0xFF0D47A1),
      illusAsset: 'assets/images/illus-passbook.png',
      subtitle: 'Cần tiền gấp — bán sổ ngay',
      title: 'Nhận tiền ngay',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Figma node 16:6723: total container = 327×104px
        SizedBox(
          height: 104,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _BannerCard(data: _banners[i]),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF95A8C1)
                    : const Color(0xFFDFE4EC),
                borderRadius: BorderRadius.circular(active ? 4 : 200),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Data model ────────────────────────────────────────────────────────────────
class _BannerData {
  final String? bgImage;      // full landscape background image (banner 1)
  final Color? bgColor;       // Flutter-drawn color bg (banners 2 & 3)
  final String? illusAsset;   // transparent PNG illustration (banners 2 & 3)
  final String subtitle;
  final String title;

  const _BannerData({
    this.bgImage,
    this.bgColor,
    this.illusAsset,
    required this.subtitle,
    required this.title,
  });
}

// ─── Card widget ───────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Figma: total frame 327×104px
    // Card (bg) is 327×80px starting at y:24
    // Illustration overflows upward from y:24 into the top 24px space
    return SizedBox(
      height: 104,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Background ──
          if (data.bgImage != null)
            // Banner 1: full img-banner.png (already has bg + illus in image)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  data.bgImage!,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomLeft,
                ),
              ),
            )
          else ...[
            // Banners 2&3: colored card at bottom 80px, illustration overflows up
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: data.bgColor!,
                  child: CustomPaint(painter: _WavePainter(data.bgColor!)),
                ),
              ),
            ),
            // Illustration: transparent PNG, overflows from y≈0 down to bottom
            if (data.illusAsset != null)
              Positioned(
                right: 0,
                top: 0,       // starts from very top (overflows above card)
                bottom: 0,
                width: 110,   // ~33% of 327px
                child: Image.asset(
                  data.illusAsset!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
          ],

          // ── Text overlay ── Figma top:39, left:12, w:303 (right:24) ──
          Positioned(
            left: 12,
            top: 39,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 22 / 14,
                    color: Colors.white.withAlpha(229),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 32 / 20,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ─── Wave texture painter (mimics the subtle diagonal pattern on original banner) ─
class _WavePainter extends CustomPainter {
  final Color base;
  _WavePainter(this.base);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;

    // Draw 3 diagonal arcs like the original green banner's wave
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.1 + i * 0.3);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x, size.height * 0.5),
          width: size.height * 1.8,
          height: size.height * 1.8,
        ),
        -0.8,
        1.6,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.base != base;
}
