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
  final String badgeText;
  final bool isFeatured; // Figma: featured=#E2FDCE, normal=#F5FED8

  const DepositCardData({
    required this.userName,
    this.tag = '#Tiền gửi số',
    required this.description,
    required this.amount,
    this.rateLabel = 'Lãi suất /năm',
    required this.rate,
    this.termLabel = 'Kỳ hạn còn lại',
    required this.term,
    required this.badgeText,
    this.isFeatured = false,
  });
}

class DepositCard extends StatefulWidget {
  final DepositCardData data;
  final bool showDivider;

  const DepositCard({
    super.key,
    required this.data,
    this.showDivider = true,
  });

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
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.984).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Padding(
          // Figma: Card has pt:12, no horizontal padding (handled by parent)
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserRow(d),
              const SizedBox(height: 8),
              _buildInfoCard(d),
              const SizedBox(height: 8),
              _buildActions(),
              if (widget.showDivider) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 1, color: Color(0xFFEAEFF5)),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRow(DepositCardData d) {
    // Figma: gap:8 between avatar(24x24 rounded) and content column
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar — 24×24, rounded circle (Figma: size:24 rounded:25px)
        ClipOval(
          child: Image.asset(
            'assets/images/img-ava.png',
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
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
                        color: const Color(0xFF307A62), // brand color
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Caption — fs:12, color:#7A8DA3 (text/sub-3)
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
        ),
      ],
    );
  }

  Widget _buildInfoCard(DepositCardData d) {
    // Figma: Featured bg=#E2FDCE(node24:640), Normal bg=#F5FED8(node18:477)
    // pad: pl:4 pr:12 py:12, gap:4, radius:12
    final bgColor = d.isFeatured
        ? const Color(0xFFE2FDCE)   // Featured: mint green
        : const Color(0xFFF5FED8);  // Normal: light lime-yellow

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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(height: 2),
                    // Rate row — label left, rate right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          d.rateLabel,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                            color: const Color(0xFF495463), // text/sub-4
                          ),
                        ),
                        // Rate — fs:20 SemiBold, color:#307A62 (brand)
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
                    const SizedBox(height: 4),
                    // Term row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d.termLabel,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                            color: const Color(0xFF495463),
                          ),
                        ),
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

        // Badge — Figma: black bg, lime icon circle, lime text. top:-10.7 right:-5.48
        // rotate: 2 degrees
        Positioned(
          top: -10,
          right: 2,
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
                  // Lime circle with trending up icon
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC6F84C), // lime #C6F84C
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Badge text — fs:10 SemiBold, lime color
                  Text(
                    d.badgeText,
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
    // Figma: share icon left, "Nhận" button right
    // Button: bg #C6F84C, text #024521 (dark green), radius:4, fs:12 SemiBold
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Share / link forward icon
        GestureDetector(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SvgPicture.asset(
              'assets/icons/ic-link-forward.svg',
              width: 20,
              height: 20,
            ),
          ),
        ),
        // "Nhận" button
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFC6F84C),
              borderRadius: BorderRadius.circular(4),
            ),
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
    );
  }
}
