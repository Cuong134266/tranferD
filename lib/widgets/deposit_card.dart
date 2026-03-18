import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model for deposit card
class DepositCardData {
  final String userName;
  final String tag;
  final String description;
  final String amount;
  final String rateLabel;
  final String rate;
  final String termLabel;
  final String term;
  final String? badgeText;
  final Color avatarColor;
  final String? avatarImage; // null = colored circle, set = photo
  final bool isFeatured;

  const DepositCardData({
    required this.userName,
    this.tag = '#Tiền gửi số',
    required this.description,
    required this.amount,
    this.rateLabel = 'Lãi suất /năm',
    required this.rate,
    this.termLabel = 'Kỳ hạn còn lại',
    required this.term,
    this.badgeText,
    this.avatarColor = const Color(0xFF3A00F9),
    this.avatarImage,
    this.isFeatured = false,
  });
}

class DepositCard extends StatefulWidget {
  final DepositCardData data;
  final bool showDivider;

  const DepositCard({super.key, required this.data, this.showDivider = true});

  @override
  State<DepositCard> createState() => _DepositCardState();
}

class _DepositCardState extends State<DepositCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleCtrl,
        curve: Curves.easeInOut,
        reverseCurve: Curves.elasticOut, // bouncy spring on release
      ),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _scaleCtrl.forward();
  }

  Future<void> _handleTapUp(TapUpDetails _) async {
    // Ensure the press animation is visible even on quick taps
    if (_scaleCtrl.isAnimating) {
      await _scaleCtrl.forward();
    }
    await Future.delayed(const Duration(milliseconds: 80));
    _scaleCtrl.reverse();
  }

  void _handleTapCancel() {
    _scaleCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Figma: Card (VERTICAL, paddingTop:12)
            //   └── User (HORIZONTAL, gap:8)
            //       ├── Avatar (24×24, top-aligned)
            //       └── Content (VERTICAL)
            //           ├── Header (name + desc)
            //           ├── InfoCard (green card)
            //           └── Actions
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar — 24×24, photo or colored circle + initial
                  if (d.avatarImage != null)
                    ClipOval(
                      child: Image.asset(
                        d.avatarImage!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: d.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        d.userName.isNotEmpty ? d.userName[0] : '',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Content column — everything right of avatar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section (name + desc)
                        _buildHeader(d),
                        // Green info card
                        _buildInfoCard(d),
                        // Actions (share + Nhận)
                        _buildActions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divider — full width, outside the avatar row
            if (widget.showDivider) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: Color(0xFFDFE4EC)),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  /// Figma: Header section — name + tag + description
  /// VERTICAL, gap:4, paddingBottom:8
  Widget _buildHeader(DepositCardData d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + tag row — fs:12, gap:4
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                d.userName,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 18 / 12,
                  color: const Color(0xFF01250F),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  d.tag,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: const Color(0xFF307A62),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Caption — fs:12, color:#7A8DA3
          Text(
            d.description,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
              color: const Color(0xFF7A8DA3),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DepositCardData d) {
    // Figma: Featured bg=#E2FDCE(node24:640), Normal bg=#F5FED8(node18:477)
    // pad: pl:4 pr:12 py:12, gap:4, radius:12
    final bgColor = d.isFeatured
        ? const Color(0xFFE2FDCE) // Featured: mint green
        : const Color(0xFFF5FED8); // Normal: light lime-yellow

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card body
        Container(
          padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coin illustration — 48×48 (Figma saving_illus_coin: 48px)
              SizedBox(
                width: 48,
                height: 48,
                child: Image.asset(
                  'assets/images/img-coin.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              // Right column: amount + rate + term
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount — fs:18 SemiBold, color:#01250F (text/main)
                    Text(
                      d.amount,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 24 / 18,
                        color: const Color(0xFF01250F),
                      ),
                    ),
                    // Rate row — Figma: HORIZONTAL, gap:12
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            d.rateLabel,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 18 / 12,
                              color: const Color(0xFF495463),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          d.rate,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 32 / 20,
                            color: const Color(0xFF307A62),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Term row — Figma: HORIZONTAL, gap:12
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.termLabel,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 18 / 12,
                              color: const Color(0xFF495463),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          d.term,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 18 / 12,
                            color: const Color(0xFF01250F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Badge — only show if badgeText is set
        if (d.badgeText != null)
          Positioned(
            top: -5,
            right: -4,
            child: Transform.rotate(
              angle: 0.035, // ~2 degrees
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 3, 6, 3),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC6F84C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      d.badgeText!,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 14 / 10,
                        color: const Color(0xFFC6F84C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    // Figma: HORIZONTAL, SPACE_BETWEEN, crossAxis CENTER, paddingTop:8
    // Button: 58×26, bg #C6F84C, text #024521, radius:4, fs:12 SemiBold
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Share / link forward icon — 20×20, color #94A3B8
          GestureDetector(
            onTap: () {},
            child: SvgPicture.asset(
              'assets/icons/ic-link-forward.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF94A3B8),
                BlendMode.srcIn,
              ),
            ),
          ),
          // "Nhận" button — Figma: 58×26
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFC6F84C),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                'Nhận',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 18 / 12,
                  color: const Color(0xFF024521),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
