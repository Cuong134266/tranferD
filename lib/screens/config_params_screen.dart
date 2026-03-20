import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Data class holding all configurable parameters
class ConfigParams {
  final double principal;        // Tiền gốc
  final double originalRate;     // Lãi suất sổ gốc (%/năm)
  final int totalTermMonths;     // Kỳ hạn (tháng)
  final int remainingMonths;     // Kỳ hạn còn lại (tháng)
  final double newOpeningRate;   // Lãi mở mới (%/năm)

  const ConfigParams({
    required this.principal,
    required this.originalRate,
    required this.totalTermMonths,
    required this.remainingMonths,
    required this.newOpeningRate,
  });
}

class ConfigParamsScreen extends StatefulWidget {
  final double principal;
  final double originalRate;
  final int totalTermMonths;
  final int remainingMonths;
  final double newOpeningRate;

  const ConfigParamsScreen({
    super.key,
    required this.principal,
    required this.originalRate,
    required this.totalTermMonths,
    required this.remainingMonths,
    required this.newOpeningRate,
  });

  @override
  State<ConfigParamsScreen> createState() => _ConfigParamsScreenState();
}

class _ConfigParamsScreenState extends State<ConfigParamsScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _principalCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _termCtrl;
  late TextEditingController _remainCtrl;
  late TextEditingController _newRateCtrl;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _principalCtrl = TextEditingController(
      text: _formatCurrency(widget.principal),
    );
    _rateCtrl = TextEditingController(
      text: widget.originalRate.toString(),
    );
    _termCtrl = TextEditingController(
      text: widget.totalTermMonths.toString(),
    );
    _remainCtrl = TextEditingController(
      text: widget.remainingMonths.toString(),
    );
    _newRateCtrl = TextEditingController(
      text: widget.newOpeningRate.toString(),
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _termCtrl.dispose();
    _remainCtrl.dispose();
    _newRateCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return buffer.toString();
  }

  void _onSave() {
    final principalRaw =
        _principalCtrl.text.replaceAll(',', '').replaceAll('.', '').trim();
    final principal = double.tryParse(principalRaw);
    final rate = double.tryParse(_rateCtrl.text.trim());
    final term = int.tryParse(_termCtrl.text.trim());
    final remain = int.tryParse(_remainCtrl.text.trim());
    final newRate = double.tryParse(_newRateCtrl.text.trim());

    if (principal == null ||
        rate == null ||
        term == null ||
        remain == null ||
        newRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập đầy đủ thông tin hợp lệ',
            style: GoogleFonts.beVietnamPro(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (remain > term) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kỳ hạn còn lại không thể lớn hơn kỳ hạn gốc',
            style: GoogleFonts.beVietnamPro(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      ConfigParams(
        principal: principal,
        originalRate: rate,
        totalTermMonths: term,
        remainingMonths: remain,
        newOpeningRate: newRate,
      ),
    );
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
          SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),
                      // Form card
                      _buildFormCard(),
                      const SizedBox(height: 16),
                      // Info note
                      _buildInfoNote(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(),
          ),
        ],
      ),
    );
  }

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
              Text(
                'Cấu hình tham số',
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF136F42).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.tune_rounded,
            size: 24,
            color: Color(0xFF136F42),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Điều chỉnh tham số tính toán',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 26 / 18,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Thay đổi các thông số để tính toán lại lãi suất chuyển nhượng.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 20 / 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildField(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Tiền gốc',
            controller: _principalCtrl,
            suffix: '₫',
            keyboardType: TextInputType.number,
            inputFormatters: [_CurrencyFormatter()],
          ),
          _buildDivider(),
          _buildField(
            icon: Icons.percent_rounded,
            label: 'Lãi suất sổ gốc',
            controller: _rateCtrl,
            suffix: '%/năm',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          _buildDivider(),
          _buildField(
            icon: Icons.calendar_month_outlined,
            label: 'Kỳ hạn',
            controller: _termCtrl,
            suffix: 'tháng',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildDivider(),
          _buildField(
            icon: Icons.timelapse_rounded,
            label: 'Kỳ hạn còn lại',
            controller: _remainCtrl,
            suffix: 'tháng',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildDivider(),
          _buildField(
            icon: Icons.trending_up_rounded,
            label: 'Lãi mở mới',
            controller: _newRateCtrl,
            suffix: '%/năm',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String suffix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 0),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF136F42)),
          ),
          const SizedBox(width: 12),
          // Label + input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                          color: AppTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFB0B8C4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      suffix,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.cardBorder.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFF9A825),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Các tham số sẽ được dùng để tính toán lại biểu đồ so sánh chuyển nhượng và tất toán trước hạn.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 18 / 12,
                color: const Color(0xFF8D6E08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
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
              GestureDetector(
                onTap: _onSave,
                child: Container(
                  width: double.infinity,
                  height: 53,
                  decoration: BoxDecoration(
                    color: const Color(0xFF136F42),
                    borderRadius: BorderRadius.circular(8.412),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Áp dụng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16.82,
                      fontWeight: FontWeight.w600,
                      height: 25.235 / 16.82,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 29),
            ],
          ),
        ),
      ),
    );
  }
}

/// Currency formatter: auto-add commas every 3 digits
class _CurrencyFormatter extends TextInputFormatter {
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
