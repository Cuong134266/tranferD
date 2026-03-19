import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/deposit_card.dart';
import '../widgets/custom_slider_track.dart';

class PostListingScreen extends StatefulWidget {
  final DepositCardData data;

  const PostListingScreen({super.key, required this.data});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen>
    with SingleTickerProviderStateMixin {
  // Slider fraction 0.0 → 1.0
  double _amountFraction = 0.33;

  // These would come from the DepositCardData in a real app
  late double _minAmount;
  late double _maxAmount;
  late double _selectedAmount;

  late TextEditingController _amountCtrl;
  late FocusNode _amountFocus;
  bool _isExpanded = false;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Parse original amount from string (e.g. "300,000,000 đ")
    final raw = widget.data.amount.replaceAll(',', '').replaceAll(' đ', '').trim();
    final base = double.tryParse(raw) ?? 300000000;
    _minAmount = base;
    _maxAmount = base * 1.073;
    _selectedAmount = _minAmount + (_maxAmount - _minAmount) * _amountFraction;

    _amountCtrl = TextEditingController(
      text: _formatCurrency(_selectedAmount),
    );
    _amountFocus = FocusNode();
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        // Khi focus: select-all để user thay thế hoặc tiếp tục gõ
        // Giữ nguyên text có dấu phẩy, formatter sẽ xử lý live
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _amountCtrl.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _amountCtrl.text.length,
          );
        });
      } else {
        // Mất focus: format lại và clamp vào min/max
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _onAmountEditingDone();
        });
      }
    });

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _amountFraction = value;
      _selectedAmount = _minAmount + (_maxAmount - _minAmount) * value;
    });
    // Cập nhật controller SAU setState để tránh rebuild loop
    if (!_amountFocus.hasFocus) {
      final newText = _formatCurrency(_selectedAmount);
      if (_amountCtrl.text != newText) {
        _amountCtrl.text = newText;
      }
    }
  }

  // Khi người dùng gõ xong → parse → clamp → update slider
  void _onAmountEditingDone() {
    final raw = _amountCtrl.text.replaceAll(',', '').replaceAll('.', '').trim();
    final typed = double.tryParse(raw);
    if (typed != null) {
      final clamped = typed.clamp(_minAmount, _maxAmount);
      setState(() {
        _selectedAmount = clamped;
        _amountFraction = (clamped - _minAmount) / (_maxAmount - _minAmount);
        _amountCtrl.text = _formatCurrency(clamped);
      });
    } else {
      // Không parse được → reset về giá trị hiện tại
      _amountCtrl.text = _formatCurrency(_selectedAmount);
    }
  }

  // Receiver pays = selected + a simulated fee/premium (3% of base)
  double get _receiverAmount => _selectedAmount * 1.01503;

  // Profit compared to early termination
  double get _profitAmount => _selectedAmount - _minAmount + (_minAmount * 0.013);

  bool get _canContinue => _amountFraction > 0.0;

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return buffer.toString();
  }

  String _formatShort(double amount) {
    if (amount >= 1000000) {
      final tr = amount / 1000000;
      if (tr >= 10) return '${tr.toStringAsFixed(0)}Tr';
      return '${tr.toStringAsFixed(1)}Tr';
    }
    return _formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.contentBackground,
      body: Stack(
        children: [
          // ── Scrollable content ──
          CustomScrollView(
            slivers: [
              // Top nav bar (custom, not standard AppBar)
              SliverToBoxAdapter(child: _buildTopNav(context)),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25), // padding.pT
                          _buildDepositSourceCard(),
                          const SizedBox(height: 16),
                          _buildSuggestBox(),
                          const SizedBox(height: 25), // padding.pB
                          // Extra bottom padding so content doesn't hide behind CTA
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed Bottom CTA ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(context),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // TOP NAVIGATION BAR
  // ───────────────────────────────────────────────
  Widget _buildTopNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.contentBackground,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191F25).withValues(alpha: 0.08),
            blurRadius: 52.574,
            offset: const Offset(0, 10.515),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            children: [
              // Back button — circular border style from Figma
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Text(
                'Đăng tin',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16.82,
                  fontWeight: FontWeight.w600,
                  height: 25.235 / 16.82,
                  color: const Color(0xFF191F25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // SECTION 1: DEPOSIT SOURCE CARD
  // ───────────────────────────────────────────────
  Widget _buildDepositSourceCard() {
    final d = widget.data;

    // Parse term & rate from data
    final term = d.term; // e.g. "12 tháng"
    final rate = d.rate; // e.g. "7.3%"

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.contentBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191F25).withValues(alpha: 0.06),
            blurRadius: 4,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF191F25).withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: badges + thumbnail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: badges + amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Figma: #Tiền gửi số label → amount 18px → badges (theo đúng thứ tự)
                    Text(
                      '#Tiền gửi số',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12, fontWeight: FontWeight.w400,
                        height: 18 / 12,
                        color: const Color(0xFF307A62)),
                    ),
                    const SizedBox(height: 4),
                    // Amount — Figma: 18px Medium #01250f, ₫ ngay sau số
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: _formatCurrency(_minAmount),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18, fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: const Color(0xFF01250F))),
                        TextSpan(
                          text: ' ₫',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18, fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: const Color(0xFF01250F))),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    // Badges: "12 tháng" (gray) + "7.3%/năm" (green)
                    Row(
                      children: [
                        _BadgePill(label: term),
                        const SizedBox(width: 4),
                        _BadgePillGreen(label: '$rate/năm'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Coin thumbnail — Figma: 69×69, bg #F5FED8
              Container(
                width: 69,
                height: 69,
                decoration: BoxDecoration(
                  color: AppTheme.thumbnailBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/img-coin.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),

          // Dashed divider
          const SizedBox(height: 12),
          const _DashedDivider(),
          const SizedBox(height: 12),

          // Money input section
          _buildMoneyInput(),

          const SizedBox(height: 12),

          // Row: "Người nhận thanh toán" + amount + chevron toggle
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Người nhận thanh toán',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: const Color(0xFF495463),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_formatCurrency(_receiverAmount)} ₫',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Expand panel (Phí + kịch bản)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _isExpanded
                ? SizedBox(
                    key: const ValueKey('expanded'),
                    width: double.infinity,
                    child: _buildExpandedPanel())
                : SizedBox(
                    key: const ValueKey('insight'),
                    width: double.infinity,
                    child: _buildInsightBox()),
          ),
        ],
      ),
    );
  }

  // ── Money input ──
  Widget _buildMoneyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hint label
        Text(
          'Số tiền bạn muốn nhận',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
            color: AppTheme.textDescription,
          ),
        ),
        const SizedBox(height: 4),
        // Big amount — Row co theo nội dung, ₫ ngay sát số
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 40 / 30,
                    letterSpacing: -1.2,
                    color: AppTheme.inputGreen,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final raw =
                        val.replaceAll(',', '').replaceAll('.', '').trim();
                    final typed = double.tryParse(raw);
                    if (typed != null) {
                      final clamped = typed.clamp(_minAmount, _maxAmount);
                      setState(() {
                        _selectedAmount = clamped;
                        _amountFraction = (clamped - _minAmount) /
                            (_maxAmount - _minAmount);
                      });
                    }
                  },
                  onEditingComplete: () {
                    _onAmountEditingDone();
                    _amountFocus.unfocus();
                  },
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '₫',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  height: 40 / 30,
                  letterSpacing: -1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Line divider below the amount
        const SizedBox(height: 4),
        Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),
        const SizedBox(height: 12),
        // Range labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatCurrency(_minAmount)} ₫',
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 14 / 10,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${_formatCurrency(_maxAmount)} ₫',
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 14 / 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4), // 4px gap (Figma spacing.xxs)
        // Gradient slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            trackShape: GradientSliderTrackShape(sliderValue: _amountFraction),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 9,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            overlayColor: AppTheme.inputGreen.withValues(alpha: 0.15),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
          ),
          child: SizedBox(
            height: 32,
            child: Slider(
              value: _amountFraction,
              min: 0.0,
              max: 1.0,
              onChanged: _onSliderChanged,
            ),
          ),
        ),
        // Marker labels at 30%/70%/100%
        SliderMarkersRow(sliderValue: _amountFraction),
      ],
    );
  }

  // ── Insight highlight box ──
  Widget _buildInsightBox() {
    final profit = _profitAmount;
    final profitStr = _formatShort(profit);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.successSub,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending up icon in green circle
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Rich text
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 18 / 12,
                  color: AppTheme.textDark,
                ),
                children: [
                  const TextSpan(text: 'Lời '),
                  TextSpan(
                    text: profitStr,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 22 / 14,
                      color: AppTheme.successGreen,
                    ),
                  ),
                  TextSpan(
                    text: ' (~ ${widget.data.rate}/năm)',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12, fontWeight: FontWeight.w400,
                      height: 18 / 12,
                      color: AppTheme.successGreen,
                    ),
                  ),
                  const TextSpan(text: ' so với tất toán'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Expanded detail panel ── (Figma node 61-4643)
  Widget _buildExpandedPanel() {
    // _minAmount = sổ gốc (principal)
    final feeTransfer = _minAmount * 0.0008;          // 0.08% sổ gốc
    final earlySettleInterest = _minAmount * 0.0005;  // 0.05% sổ gốc
    const feeListing = 3000.0;
    final receiverAfterFee = _receiverAmount - feeTransfer - feeListing;
    // Chart values (Figma: chuyển nhượng = receiverAfterFee, tất toán = minAmount + interest)
    final valTransfer = receiverAfterFee;
    final valEarlySettle = _minAmount + earlySettleInterest;

    // Figma text styles
    final ls = GoogleFonts.beVietnamPro(
      fontSize: 12, fontWeight: FontWeight.w400,
      height: 18 / 12, color: const Color(0xFF495463));
    final fv = GoogleFonts.beVietnamPro(
      fontSize: 12, fontWeight: FontWeight.w500,
      height: 18 / 12, color: const Color(0xFF01250F));
    final rv = GoogleFonts.beVietnamPro(
      fontSize: 16, fontWeight: FontWeight.w500,
      height: 24 / 16, color: const Color(0xFF01250F));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Phí chuyển nhượng ──
        Row(
          children: [
            Text('Phí chuyển nhượng', style: ls),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFF7A8DA3)),
            const Expanded(child: SizedBox()),
            Text('${_formatCurrency(feeTransfer)} ₫', style: fv),
          ],
        ),
        const SizedBox(height: 12),

        // ── Phí đăng tin ──
        Row(children: [
          Text('Phí đăng tin', style: ls),
          const Expanded(child: SizedBox()),
          Text('${_formatCurrency(feeListing)} ₫', style: fv),
        ]),
        const SizedBox(height: 12),

        // ── Dashed divider ──
        const _DashedDivider(),
        const SizedBox(height: 12),

        // ── Người nhận thanh toán (net, after fees) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('Người nhận thanh toán', style: ls)),
            Text('${_formatCurrency(receiverAfterFee)} ₫', style: rv),
          ],
        ),
        const SizedBox(height: 12),

        // ── Highlight box (#EBFEF1) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEBFEF1),
            borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon "Lời hơn X (Thực nhận Y%/năm)" / "so với tất toán..."
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Green circle trending-up icon
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF39B16B), shape: BoxShape.circle),
                    child: const Center(
                      child: Icon(Icons.trending_up_rounded,
                          size: 13, color: Colors.white))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: "Lời hơn 4.1Tr" + "(Thực nhận 7.2%/năm)"
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: 'Lời hơn ',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12, height: 18 / 12,
                                    color: const Color(0xFF01250F))),
                                TextSpan(
                                  text: ' ${_formatShort(_profitAmount)}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    height: 22 / 14,
                                    color: const Color(0xFF39B16B))),
                              ])),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '(Thực nhận ${widget.data.rate}/năm)',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  height: 14 / 10,
                                  color: const Color(0xFF39B16B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Row 2: "so với tất toán trước hạn"
                        Text('so với tất toán trước hạn',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12, height: 18 / 12,
                            color: const Color(0xFF01250F))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Preview section: h=103px, labels+dashes left, chart right ──
              SizedBox(
                height: 103,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Labels column (left)
                    Positioned(
                      left: 0, top: 0, right: 110,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Row 1: label + dashed line
                          Text('Nếu chuyển nhượng',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10, height: 14 / 10,
                              color: const Color(0xFF7A8DA3))),
                          const SizedBox(height: 2),
                          const _DashedDivider(),
                          const SizedBox(height: 4),
                          Text('${_formatCurrency(valTransfer)} ₫',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14, fontWeight: FontWeight.w500,
                              height: 22 / 14,
                              color: const Color(0xFF01250F))),
                          const SizedBox(height: 8),
                          // Row 2: label + dashed line
                          Text('Nếu tất toán trước hạn',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10, height: 14 / 10,
                              color: const Color(0xFF7A8DA3))),
                          const SizedBox(height: 2),
                          const _DashedDivider(),
                          const SizedBox(height: 4),
                          Text('${_formatCurrency(valEarlySettle)} ₫',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14, fontWeight: FontWeight.w500,
                              height: 22 / 14,
                              color: const Color(0xFF01250F))),
                        ],
                      ),
                    ),
                    // Chart — bars aligned to bottom-right, Figma: col1 gray h=60, col2 green h=91
                    Positioned(
                      right: 0,
                      bottom: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bar 1: tất toán (gray, 60px, rounded top)
                          Container(
                            width: 40, height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A8DA3).withValues(alpha: 0.25),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)))),
                          const SizedBox(width: 4),
                          // Bar 2: chuyển nhượng (green, 91px, rounded top)
                          Container(
                            width: 40, height: 91,
                            decoration: const BoxDecoration(
                              color: Color(0xFF39B16B),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Ghi chú italic
              Text(
                'Thông tin tính toán dựa trên tham khảo biểu lãi suất tiền gửi hiện tại của MB',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10, fontStyle: FontStyle.italic,
                  height: 14 / 10, color: const Color(0xFF7A8DA3))),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Thu gọn button ──
        GestureDetector(
          onTap: () => setState(() => _isExpanded = false),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Thu gọn',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  height: 18 / 12, color: const Color(0xFF307A62))),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_up_rounded,
                size: 16, color: Color(0xFF307A62)),
            ],
          ),
        ),
      ],
    );
  }


  // ───────────────────────────────────────────────
  // SECTION 2: SUGGEST BOX
  // ───────────────────────────────────────────────
  Widget _buildSuggestBox() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.successSub, // #EBFEF1
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Market insight text (top area)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.618,
                      height: 18.927 / 12.618,
                      color: AppTheme.textDark,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Tài sản chuyển nhượng có sức hút tốt hơn\n',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      TextSpan(
                        text: '80% mặt bằng hiện tại',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.618,
                          fontWeight: FontWeight.w600,
                          height: 18.927 / 12.618,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // White surface card with 2 rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildWhiteSurfaceCard(),
              ),
              const SizedBox(height: 12),
              // "Gợi ý tin đăng" section
              _buildSuggestedPostSection(),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Floating badge: "Dễ chuyển nhượng" — top-left, rotated -2°
        Positioned(
          top: -3,
          left: -6,
          child: Transform.rotate(
            angle: -2 * math.pi / 180, // -2 degrees
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 3, 6, 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lime circle + bulb icon
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.limeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      size: 10,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Dễ chuyển nhượng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 14 / 10,
                      color: AppTheme.limeAccent,
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

  // ── White surface card (visibility + expiry rows) ──
  Widget _buildWhiteSurfaceCard() {
    final expiryDate = _getExpiryDate();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191F25).withValues(alpha: 0.06),
            blurRadius: 4,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF191F25).withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        child: Column(
          children: [
            // Row 1: Visibility
            _InfoRow(
              icon: Icons.language_rounded,
              richText: RichText(
                text: TextSpan(
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: AppTheme.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Mọi người',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandGreen,
                        height: 18 / 12,
                      ),
                    ),
                    const TextSpan(text: ' có thể xem tin'),
                  ],
                ),
              ),
            ),
            // Dashed divider between rows
            const _DashedDivider(),
            // Row 2: Expiry
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              richText: RichText(
                text: TextSpan(
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: AppTheme.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Hết hạn sau '),
                    TextSpan(
                      text: '3 ngày',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandGreen,
                        height: 18 / 12,
                      ),
                    ),
                    TextSpan(text: ' | $expiryDate'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExpiryDate() {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 3));
    return '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}';
  }

  // ── Suggested post section ──
  Widget _buildSuggestedPostSection() {
    final d = widget.data;
    // Simulated AI suggestion based on deposit data
    final suggestion =
        'Cơ hội thu lời 🎉🎉🎉 Sổ còn ${d.term}, lãi ${d.rate}, '
        'gửi ${_formatShort(_minAmount)} nhận ${_formatShort(_minAmount * 0.06)} mỗi năm';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Gợi ý tin đăng',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 22 / 14,
                  color: const Color(0xFF082219),
                ),
              ),
              const Spacer(),
              // "Thay đổi" text button
              GestureDetector(
                onTap: () {
                  // In a real app, trigger AI suggestion refresh
                  setState(() {}); // Fake refresh
                },
                child: Row(
                  children: [
                    Text(
                      'Thay đổi',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 22 / 14,
                        color: AppTheme.brandGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: AppTheme.brandGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preview quote box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSub, // #F6F7F9
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Opening quote
                Text(
                  '\u201C', // "
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                // Content + closing quote in same flex
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      suggestion,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 22 / 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Closing quote
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '\u201D', // "
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // BOTTOM CTA BAR
  // ───────────────────────────────────────────────
  Widget _buildBottomCTA(BuildContext context) {
    final isEnabled = _canContinue;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191F25).withValues(alpha: 0.06),
            blurRadius: 50.471,
            offset: const Offset(0, -5.257),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 17, 25, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary button
              GestureDetector(
                onTap: isEnabled
                    ? () {
                        // Navigate to next screen / confirmation
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 53,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.brandGreen
                        : AppTheme.disabledBtnBg,
                    borderRadius: BorderRadius.circular(8.412),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Tiếp tục',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16.82,
                      fontWeight: FontWeight.w600,
                      height: 25.235 / 16.82,
                      color: isEnabled
                          ? Colors.white
                          : AppTheme.disabledBtnText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 29), // spacing.xl bottom
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────

/// Badge pill component (Figma: [comp] badge text)
class _BadgePill extends StatelessWidget {
  final String label;
  const _BadgePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.badgePillBg, // #ECEFF3
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 14 / 10,
          color: AppTheme.textSecondary, // #495463
        ),
      ),
    );
  }
}

/// Badge pill với text màu xanh lá (Figma: 7.3%/năm badge)
class _BadgePillGreen extends StatelessWidget {
  final String label;
  const _BadgePillGreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.badgePillBg, // #ECEFF3
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 14 / 10,
          color: const Color(0xFF39B16B), // success green
        ),
      ),
    );
  }
}

/// Dashed divider (Figma: [comp] Divider — dashed variant)
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(color: const Color(0xFFDFE4EC)),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth, 0),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Info row for white surface card (icon + richText + arrow)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final RichText richText;

  const _InfoRow({required this.icon, required this.richText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: richText),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// TextInputFormatter: tu dong them dau phay moi 3 chu so khi go
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (!RegExp(r'^\d+$').hasMatch(digits)) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
