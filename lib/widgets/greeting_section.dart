import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingSection extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onPostTap; // tap icon → để đăng tin
  const GreetingSection({super.key, this.onSearchTap, this.onPostTap});

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection> {
  // ── Typewriter placeholder texts (savings-book transfer context) ──
  static const List<String> _placeholders = [
    'Sổ tiết kiệm cần tìm người nhận?',
    'Đăng tin nhượng sổ — kết nối ngay!',
    'Lãi cao, kỳ hạn đẹp? Chia sẻ đi!',
    'Sang tên sổ nhanh — an toàn — lãi tốt',
    'Muốn tất toán sớm? Nhượng sổ ngay hôm nay',
    'Tìm người nhận sổ uy tín trong 24 giờ',
  ];

  int _phraseIndex = 0;
  String _displayed = ''; // currently shown characters
  bool _isTyping = true; // true = typing forward, false = erasing

  Timer? _timer;

  static const Duration _typeSpeed = Duration(milliseconds: 55);
  static const Duration _eraseSpeed = Duration(milliseconds: 30);
  static const Duration _pauseAfterType = Duration(seconds: 5);
  static const Duration _pauseAfterErase = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    // Start typing the first phrase after a short initial delay
    Future.delayed(const Duration(milliseconds: 600), _startTyping);
  }

  void _startTyping() {
    if (!mounted) return;
    final fullText = _placeholders[_phraseIndex];
    _isTyping = true;

    _timer = Timer.periodic(_typeSpeed, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_displayed.length < fullText.length) {
        setState(
          () => _displayed = fullText.substring(0, _displayed.length + 1),
        );
      } else {
        // Fully typed — pause then start erasing
        t.cancel();
        Future.delayed(_pauseAfterType, _startErasing);
      }
    });
  }

  void _startErasing() {
    if (!mounted) return;
    _isTyping = false;

    _timer = Timer.periodic(_eraseSpeed, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_displayed.isNotEmpty) {
        setState(
          () => _displayed = _displayed.substring(0, _displayed.length - 1),
        );
      } else {
        // Fully erased — advance to next phrase
        t.cancel();
        _phraseIndex = (_phraseIndex + 1) % _placeholders.length;
        Future.delayed(_pauseAfterErase, _startTyping);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Figma node 19:624 — horizontal padding 24, inner card 12 all
    // Card: radius 16, shadow blur:10 y:6 rgba(69,118,103,8%)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14457667),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1: greeting + manage button — Figma 303×42 ──
            SizedBox(
              height: 42,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // top-aligned
                children: [
                  // Left: greeting text column (16:6713)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // "Xin chào!" — fs:12, lh:18, fw:400, #7A8DA3
                        Text(
                          'Xin chào!',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                            color: const Color(0xFF7A8DA3),
                          ),
                        ),
                        // Name — fs:14, lh:22, fw:600, #01250F
                        Text(
                          'Hoang Phu Ngoc Tuong',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 22 / 14,
                            color: const Color(0xFF01250F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: "Quản lý bản tin" button — top-aligned
                  // Figma: #ECEFF3 bg, radius:24, pad T4 R4 B4 L8
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // fs:10, lh:14, fw:600, #01250F
                          Text(
                            'Quản lý bản tin',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 14 / 10,
                              color: const Color(0xFF01250F),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Arrow icon — dark #191F25 via colorFilter
                          SvgPicture.asset(
                            'assets/icons/ic-arrow-right.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF01250F),
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Row 2: Search bar with typewriter placeholder ──
            // Figma: #ECEFF3 bg, radius:12, pad T8 R12 B8 L8
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSearchTap,
              child: Container(
                height: 48,
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFECEFF3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FFF4),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/img-ava.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const Icon(
                            Icons.person,
                            size: 20,
                            color: Color(0xFF307A62),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // IgnorePointer chỉ cho phần text — outer GestureDetector xử lý
                    Expanded(
                      child: IgnorePointer(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _displayed,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 18 / 12,
                                  color: const Color(0xFF7A8DA3),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            _BlinkingCursor(
                              visible: _isTyping || _displayed.isEmpty,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Icon send — GestureDetector riêng, nhận tap độc lập
                    GestureDetector(
                      onTap: widget.onPostTap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: SvgPicture.asset(
                          'assets/icons/ic-send.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blinking cursor widget ──
class _BlinkingCursor extends StatefulWidget {
  final bool visible;
  const _BlinkingCursor({required this.visible});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 1.5,
        height: 14,
        margin: const EdgeInsets.only(left: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF307A62),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
