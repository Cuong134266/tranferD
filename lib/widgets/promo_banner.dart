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

  static const List<_BannerData> _banners = [
    _BannerData(
      subtitle: 'Sang tay — không mất lãi',
      title: 'Lãi đến 13.5%/năm ✦',
    ),
    _BannerData(subtitle: 'Tiền gửi lãi cao', title: 'Săn sổ ngay!'),
    _BannerData(
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

class _BannerData {
  final String subtitle;
  final String title;
  const _BannerData({required this.subtitle, required this.title});
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Figma: total frame 327×104px, card bg 327×80px at y:24
    return SizedBox(
      height: 104,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background image — shared img-banner.png for all 3 slides
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/img-banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomLeft,
              ),
            ),
          ),

          // Text overlay — Figma: left:12, top:39, right clears illustration
          Positioned(
            left: 16,
            top: 39,
            right: 120, // leave space for illustration on right
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: Colors.white.withAlpha(229),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 28 / 18,
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
