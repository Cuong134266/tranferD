import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/deposit_card.dart';
import '../widgets/custom_slider_track.dart';
import 'config_params_screen.dart';

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
  late double _principal; // Tiền gốc
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
    final raw = widget.data.amount
        .replaceAll(',', '')
        .replaceAll(' đ', '')
        .trim();
    final base = double.tryParse(raw) ?? 300000000;
    // Tiền gốc (principal)
    final principal = base;
    // Lãi không kỳ hạn = 0.05% × gốc
    final nonTermInterest = principal * 0.0005;
    // Phí đăng tin
    const listingFee = 3000.0;
    // Lãi đến hạn = gốc × lãi suất hiện tại × (kỳ hạn gốc/12)
    final fullTermInterest =
        principal * (_currentRate / 100) * (_totalTermMonths / 12);

    _principal = principal;
    _minAmount = principal + nonTermInterest + listingFee;
    _maxAmount = principal + fullTermInterest - 0.001 * principal;
    _selectedAmount = _minAmount + (_maxAmount - _minAmount) * _amountFraction;

    _amountCtrl = TextEditingController(text: _formatCurrency(_selectedAmount));
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

  // Người nhận thanh toán = số tiền nhập + phí chuyển nhượng + phí đăng tin
  double get _receiverAmount => _selectedAmount + (_principal * 0.01) + 3000;

  // Số tiền tất toán trước hạn = gốc + lãi không kỳ hạn 0.05%
  double get _earlySettleAmount => _principal * 1.0005;

  // Lời = số tiền mong muốn - số tiền tất toán trước hạn
  double get _profitAmount => _selectedAmount - _earlySettleAmount;

  // % = ((_selectedAmount - _minAmount) * 12) / (6 * _minAmount) * 100
  double get _transferRatePercent =>
      (_selectedAmount - _principal) * 12 / (6 * _principal) * 100;

  String get _transferRateStr => '${_transferRatePercent.toStringAsFixed(1)}%';

  bool get _canContinue => _amountFraction > 0.0;

  // ── Interest rate comparison logic ──
  // Lãi suất mở mới 6 tháng hiện tại
  double _newDepositRate = 6.2; // %/năm
  // Lãi suất sổ hiện tại (12 tháng)
  double _currentRate = 8.4; // %/năm
  // Kỳ hạn còn lại (giả sử 6 tháng)
  int _remainingMonths = 6;
  // Kỳ hạn gốc của sổ (12 tháng)
  int _totalTermMonths = 12;

  // Tổng gốc + lãi cuối kỳ của sổ (dùng kỳ hạn gốc 12 tháng)
  double get _maturityAmount =>
      _principal * (1 + _currentRate / 100 * _totalTermMonths / 12);

  // So sánh:
  // A = tổng gốc lãi cuối kỳ - số tiền người bán nhập
  // B = số tiền người bán nhập × lãi mở mới × kỳ hạn còn lại
  // Nếu A - B > 0 → dễ chuyển, < 0 → khó chuyển
  double get _transferDiff {
    final a = _maturityAmount - _selectedAmount;
    final b =
        _selectedAmount * (_newDepositRate / 100) * (_remainingMonths / 12);
    return a - b;
  }

  bool get _isEasyTransfer => _transferDiff > 0;

  // ── Recalculate all derived amounts after config change ──
  void _recalculateAmounts() {
    final principal = _principal;
    final nonTermInterest = principal * 0.0005;
    const listingFee = 3000.0;
    final fullTermInterest =
        principal * (_currentRate / 100) * (_totalTermMonths / 12);

    _minAmount = principal + nonTermInterest + listingFee;
    _maxAmount = principal + fullTermInterest - 0.001 * principal;
    _selectedAmount = _minAmount + (_maxAmount - _minAmount) * _amountFraction;
    _amountCtrl.text = _formatCurrency(_selectedAmount);
  }

  // ── Amount validation ──
  String? get _amountError {
    if (_selectedAmount < _minAmount) {
      return 'Số tiền tối thiểu ${_formatCurrency(_minAmount)}₫';
    }
    if (_selectedAmount > _maxAmount) {
      return 'Số tiền tối đa ${_formatCurrency(_maxAmount)}₫';
    }
    return null;
  }

  String _formatCurrency(double amount) {
    final isNeg = amount < 0;
    final formatted = amount.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    if (isNeg) buffer.write('-');
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildTopNav(context),
      ),
      body: Stack(
        children: [
          // ── Scrollable content ──
          CustomScrollView(
            slivers: [
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

    // Parse term from data
    final term = d.term; // e.g. "12 tháng"

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
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                        color: const Color(0xFF307A62),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Amount — Figma: 16px SemiBold #01250f, ₫ ngay sau số
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatCurrency(_principal),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: const Color(0xFF01250F),
                            ),
                          ),
                          TextSpan(
                            text: ' ₫',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: const Color(0xFF01250F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badges: "12 tháng" (gray) + "7.3%/năm" (green)
                    Row(
                      children: [
                        _BadgePill(label: term),
                        const SizedBox(width: 4),
                        _BadgePillGreen(label: '$_currentRate%/năm'),
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
                  borderRadius: BorderRadius.circular(8),
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

          // Collapsed: "Người nhận thanh toán" row + insight
          // Expanded: Phí details + chart panel
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
                firstCurve: Curves.easeIn,
                secondCurve: Curves.easeOut,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Column(
                  children: [
                    // "Người nhận thanh toán" collapsed row
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = true),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Người nhận thanh toán',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 18 / 12,
                                  color: const Color(0xFF495463),
                                ),
                              ),
                            ),
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
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: AppTheme.textDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Insight box
                    _buildInsightBox(),
                  ],
                ),
                secondChild: _buildExpandedPanel(),
              ),
            ),
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
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    height: 36 / 28,
                    letterSpacing: -1.0,
                    color: AppTheme.inputGreen,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final raw = val
                        .replaceAll(',', '')
                        .replaceAll('.', '')
                        .trim();
                    final typed = double.tryParse(raw);
                    if (typed != null) {
                      setState(() {
                        _selectedAmount = typed;
                        _amountFraction =
                            ((_selectedAmount - _minAmount) /
                                    (_maxAmount - _minAmount))
                                .clamp(0.0, 1.0);
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
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  height: 36 / 28,
                  letterSpacing: -1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Line divider below the amount
        const SizedBox(height: 4),
        Divider(
          height: 1,
          thickness: 1,
          color: _amountError != null
              ? AppTheme.errorText
              : AppTheme.cardBorder,
        ),
        // Error message
        if (_amountError != null) ...[
          const SizedBox(height: 6),
          Text(
            _amountError!,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.errorText,
            ),
          ),
        ],
        // Dynamic amount suggestions (only when focused & has input)
        if (_amountFocus.hasFocus) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (_) {
              final raw = _amountCtrl.text.replaceAll(',', '').trim();
              if (raw.isEmpty || raw == '0') return const SizedBox.shrink();
              final base = int.tryParse(raw);
              if (base == null || base <= 0) return const SizedBox.shrink();
              // Generate suggestions: base × 1M, 10M, 100M, 1B (filter reasonable ones)
              final suggestions = <double>[];
              for (final multiplier in [
                1000000,
                10000000,
                100000000,
                1000000000,
              ]) {
                final val = base.toDouble() * multiplier;
                if (val >= _minAmount * 0.5 &&
                    val <= _maxAmount * 1.5 &&
                    val != _selectedAmount) {
                  suggestions.add(val);
                }
              }
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: suggestions
                    .map((amt) => _buildSuggestionChip(amt))
                    .toList(),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        // Range labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatCurrency(_minAmount)} ₫',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${_formatCurrency(_maxAmount)} ₫',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 0), // test 0px
        // Gradient slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            trackShape: GradientSliderTrackShape(sliderValue: _amountFraction),
            thumbColor: Colors.white,
            thumbShape: const CustomThumbShape(),
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

  // ── Suggestion chip ──
  Widget _buildSuggestionChip(double amount) {
    final isSelected = (_selectedAmount - amount).abs() < 1;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmount = amount;
          _amountFraction = ((amount - _minAmount) / (_maxAmount - _minAmount))
              .clamp(0.0, 1.0);
          _amountCtrl.text = _formatCurrency(amount);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGreen : AppTheme.surfaceSub,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          _formatShort(amount),
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Insight highlight box ──
  Widget _buildInsightBox() {
    final profit = _profitAmount;
    final isLoss = profit < 0;
    final profitStr = _formatShort(profit.abs());
    final accentColor = isLoss
        ? const Color(0xFFE53935)
        : AppTheme.successGreen;
    final bgColor = isLoss ? const Color(0xFFFFF0F0) : AppTheme.successSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
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
                  TextSpan(text: isLoss ? 'Lỗ ' : 'Lời '),
                  TextSpan(
                    text: profitStr.contains('Tr') ? profitStr : '$profitStr ₫',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 22 / 14,
                      color: accentColor,
                    ),
                  ),
                  TextSpan(
                    text: ' ($_transferRateStr/năm)',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
                      color: accentColor,
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
    final feeTransfer = _principal * 0.01; // 1% sổ gốc
    const feeListing = 3000.0;
    // Chart values: chuyển nhượng = số tiền người dùng nhập, tất toán = _earlySettleAmount
    final valTransfer = _selectedAmount;
    final valEarlySettle = _earlySettleAmount;

    // Figma text styles
    final ls = GoogleFonts.beVietnamPro(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      color: const Color(0xFF495463),
    );
    final fv = GoogleFonts.beVietnamPro(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      color: const Color(0xFF01250F),
    );
    final rv = GoogleFonts.beVietnamPro(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 24 / 16,
      color: const Color(0xFF01250F),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Phí chuyển nhượng ──
        Row(
          children: [
            Text('Phí chuyển nhượng', style: ls),
            const SizedBox(width: 4),
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF7A8DA3),
            ),
            const Expanded(child: SizedBox()),
            Text('${_formatCurrency(feeTransfer)} ₫', style: fv),
          ],
        ),
        const SizedBox(height: 12),

        // ── Phí đăng tin ──
        Row(
          children: [
            Text('Phí đăng tin', style: ls),
            const Expanded(child: SizedBox()),
            Text('${_formatCurrency(feeListing)} ₫', style: fv),
          ],
        ),
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
            Text('${_formatCurrency(_receiverAmount)} ₫', style: rv),
          ],
        ),
        const SizedBox(height: 12),

        // ── Highlight box ──
        Builder(
          builder: (context) {
            final isLoss = _profitAmount < 0;
            final highlightBg = isLoss
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFEBFEF1);
            final barColor = isLoss
                ? const Color(0xFFE53935)
                : const Color(0xFF39B16B);
            // Dynamic heights: based on (value - số tiền gửi gốc)
            // This shows the gain/loss above the deposit principal
            const maxH = 91.0;
            const minH = 20.0;
            final principal = _principal; // số tiền gửi gốc
            final deltaTransfer = (valTransfer - principal).abs();
            final deltaSettle = (valEarlySettle - principal).abs();
            final maxDelta = deltaTransfer > deltaSettle
                ? deltaTransfer
                : deltaSettle;
            final barSettleH = maxDelta > 0
                ? (minH + (maxH - minH) * (deltaSettle / maxDelta)).clamp(
                    minH,
                    maxH,
                  )
                : maxH * 0.66;
            final barTransferH = maxDelta > 0
                ? (minH + (maxH - minH) * (deltaTransfer / maxDelta)).clamp(
                    minH,
                    maxH,
                  )
                : maxH;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: highlightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon "Lời / Lỗ"
                  Builder(
                    builder: (context) {
                      final profitStr = _formatShort(_profitAmount.abs());
                      final accentColor = barColor;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isLoss
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_up_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  TextSpan(text: isLoss ? 'Lỗ ' : 'Lời '),
                                  TextSpan(
                                    text: profitStr.contains('Tr')
                                        ? profitStr
                                        : '$profitStr ₫',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 22 / 14,
                                      color: accentColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ($_transferRateStr/năm)',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 18 / 12,
                                      color: accentColor,
                                    ),
                                  ),
                                  const TextSpan(text: ' so với tất toán'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Preview section: labels+chart ──
                  SizedBox(
                    height: 103,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Labels column (left)
                        Positioned(
                          left: 0,
                          top: 0,
                          right: 110,
                          bottom: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Nếu chuyển nhượng',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10,
                                  height: 14 / 10,
                                  color: const Color(0xFF7A8DA3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const _DashedDivider(),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatCurrency(valTransfer)} ₫',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 22 / 14,
                                  color: const Color(0xFF01250F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nếu tất toán trước hạn',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10,
                                  height: 14 / 10,
                                  color: const Color(0xFF7A8DA3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const _DashedDivider(),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatCurrency(valEarlySettle)} ₫',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 22 / 14,
                                  color: const Color(0xFF01250F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Chart bars — dynamic
                        Positioned(
                          right: 0,
                          bottom: 12,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bar 1: tất toán (gray)
                              Container(
                                width: 40,
                                height: barSettleH,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7A8DA3,
                                  ).withValues(alpha: 0.25),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Bar 2: chuyển nhượng (green/red + stripes)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                child: SizedBox(
                                  width: 40,
                                  height: barTransferH,
                                  child: CustomPaint(
                                    painter: _DiagonalStripePainter(
                                      barColor: barColor,
                                      stripeColor: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                      stripeWidth: 2.5,
                                      stripeSpacing: 8.0,
                                    ),
                                  ),
                                ),
                              ),
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
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 14 / 10,
                      color: const Color(0xFF7A8DA3),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // ── Thu gọn button ──
        GestureDetector(
          onTap: () => setState(() => _isExpanded = false),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Thu gọn',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 18 / 12,
                  color: const Color(0xFF307A62),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 16,
                color: Color(0xFF307A62),
              ),
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
    final easy = _isEasyTransfer;
    final bgColor = easy ? AppTheme.successSub : AppTheme.dangerSub;
    final accentColor = easy ? AppTheme.successGreen : AppTheme.dangerRed;
    final badgeBg = easy ? Colors.black : AppTheme.dangerRed;
    final badgeText = easy ? 'Dễ chuyển nhượng' : 'Khó chuyển nhượng';
    final badgeTextColor = easy ? AppTheme.limeAccent : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Market insight text (top area)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                child: easy
                    ? RichText(
                        text: TextSpan(
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.618,
                            height: 18.927 / 12.618,
                            color: AppTheme.textDark,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Tài sản chuyển nhượng có sức hút tốt hơn\n',
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),
                            TextSpan(
                              text: '80% mặt bằng hiện tại',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12.618,
                                fontWeight: FontWeight.w600,
                                height: 18.927 / 12.618,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            height: 18 / 12,
                          ),
                          children: [
                            TextSpan(
                              text: 'Tin chuyển nhượng kém sức hút!\n',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 18 / 12,
                                color: accentColor,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Điều chỉnh số tiền muốn nhận để tài sản của bạn nổi bật và dễ chuyển nhượng hơn.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 18 / 12,
                                color: const Color(0xFF112727),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              // White surface card — covers entire bottom area (full width)
              _buildWhiteSurfaceCard(),
            ],
          ),
        ),
        // Floating badge
        Positioned(
          top: -3,
          left: -6,
          child: Transform.rotate(
            angle: -2 * math.pi / 180,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 3, 6, 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(36.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  if (easy) ...[
                    Container(
                      width: 16.5,
                      height: 16.5,
                      decoration: const BoxDecoration(
                        color: AppTheme.limeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 11,
                        color: Colors.black,
                      ),
                    ),
                  ] else ...[
                    SvgPicture.asset(
                      'assets/icons/ic_warning_circle.svg',
                      width: 16,
                      height: 16,
                    ),
                  ],
                  const SizedBox(width: 2),
                  Text(
                    badgeText,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 14 / 10,
                      color: badgeTextColor,
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
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            // Row 1: Visibility
            _InfoRow(
              iconWidget: SvgPicture.asset(
                'assets/icons/ic_globe.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppTheme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
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
            const SizedBox(height: 4),
            // Row 2: Expiry
            _InfoRow(
              iconWidget: SvgPicture.asset(
                'assets/icons/ic_calendar.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppTheme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
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
            // Dashed divider before "Gợi ý tin đăng"
            const SizedBox(height: 12),
            const _DashedDivider(),
            const SizedBox(height: 12),
            // "Gợi ý tin đăng" section inside white card
            _buildSuggestedPostSection(),
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

    return Column(
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
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
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
                    ? () async {
                        final result = await Navigator.of(context)
                            .push<ConfigParams>(
                              MaterialPageRoute(
                                builder: (_) => ConfigParamsScreen(
                                  principal: _principal,
                                  originalRate: _currentRate,
                                  totalTermMonths: _totalTermMonths,
                                  remainingMonths: _remainingMonths,
                                  newOpeningRate: _newDepositRate,
                                ),
                              ),
                            );
                        if (result != null && mounted) {
                          setState(() {
                            _principal = result.principal;
                            _currentRate = result.originalRate;
                            _totalTermMonths = result.totalTermMonths;
                            _remainingMonths = result.remainingMonths;
                            _newDepositRate = result.newOpeningRate;
                            _recalculateAmounts();
                          });
                        }
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 53,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFF136F42)
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
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Info row for white surface card (iconWidget + richText + arrow)
class _InfoRow extends StatelessWidget {
  final Widget iconWidget;
  final RichText richText;

  const _InfoRow({required this.iconWidget, required this.richText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          iconWidget,
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

/// Diagonal stripe painter — theo Figma node 73:2121
/// Vẽ background barColor + overlay các đường chéo 45° màu stripeColor
class _DiagonalStripePainter extends CustomPainter {
  final Color barColor;
  final Color stripeColor;
  final double stripeWidth;
  final double stripeSpacing;

  const _DiagonalStripePainter({
    required this.barColor,
    required this.stripeColor,
    this.stripeWidth = 2.5,
    this.stripeSpacing = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = barColor,
    );

    // Diagonal stripes at 45°
    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    final step = stripeWidth + stripeSpacing;
    final total = size.width + size.height;

    for (double offset = 0; offset < total; offset += step) {
      final x1 = offset < size.height ? 0.0 : offset - size.height;
      final y1 = offset < size.height ? offset : size.height;
      final x2 = offset < size.width ? offset : size.width;
      final y2 = offset < size.width ? 0.0 : offset - size.width;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stripePaint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter old) =>
      old.barColor != barColor ||
      old.stripeColor != stripeColor ||
      old.stripeWidth != stripeWidth ||
      old.stripeSpacing != stripeSpacing;
}
