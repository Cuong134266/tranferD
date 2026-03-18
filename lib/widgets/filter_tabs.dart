import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterTabs extends StatefulWidget {
  const FilterTabs({super.key});

  @override
  State<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<FilterTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _labels = ['Nổi bật', 'Tất cả'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _labels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Padding FIRST, then LayoutBuilder so constraints.maxWidth = post-padding width.
    // Real mobile 375px: 375-48 = 327px > 250 → showLabel = true (full button).
    // Narrow Chrome ~285px: 285-48 = 237px < 250 → showLabel = false (icon only).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool showLabel = constraints.maxWidth >= 250;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Custom tabs with TabController sliding animation ──
              AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) {
                  final double t = _tabController.animation!.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _labels.length; i++) ...[
                        if (i > 0) const SizedBox(width: 11),
                        _CustomTab(
                          label: _labels[i],
                          activity: (1.0 - (t - i).abs()).clamp(0.0, 1.0),
                          isActive: _tabController.index == i,
                          onTap: () => _tabController.animateTo(i),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const Spacer(),

              // ── Filter button — Figma node 16:6819 ──
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 36,
                  padding:
                      EdgeInsets.symmetric(horizontal: showLabel ? 11 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFFEAEBEB),
                      width: 0.95,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic-filter-vertical.svg',
                        width: 20,
                        height: 20,
                      ),
                      if (showLabel) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Tìm tài sản',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 22 / 14,
                            color: const Color(0xFF112727),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Single animated tab chip ─────────────────────────────────────────────────
class _CustomTab extends StatelessWidget {
  final String label;
  final double activity; // 0.0 = inactive, 1.0 = fully active
  final bool isActive;
  final VoidCallback onTap;

  const _CustomTab({
    required this.label,
    required this.activity,
    required this.isActive,
    required this.onTap,
  });

  static const Color _textActive   = Color(0xFF112727); // tabsline/text-main
  static const Color _textInactive = Color(0xFF647373); // tabsline/text-sub
  static const Color _indicator    = Color(0xFF22C373); // tabsline/border-main

  @override
  Widget build(BuildContext context) {
    final textColor      = Color.lerp(_textInactive, _textActive, activity)!;
    final underlineColor = Color.lerp(Colors.transparent, _indicator, activity)!;

    // IntrinsicWidth + Column(stretch): underline fills exact label width.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label — pt:12, px:4, pb:5
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                left: 4,
                right: 4,
                bottom: 5,
              ),
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  height: 22 / 14,
                  color: textColor,
                ),
              ),
            ),

            // Active indicator — 2px, full label width, rounded 3px
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: underlineColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
