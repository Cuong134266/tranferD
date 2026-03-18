import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/top_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/promo_banner.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/deposit_card.dart';
import '../widgets/view_all_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _sections = 5;

  // Real data matching Figma — first 2 are "Nổi bật" (featured)
  static const List<DepositCardData> _cards = [
    DepositCardData(
      userName: 'Nguyễn H. L',
      description: '🚀 Khuyến mãi đặc biệt, lãi suất 12% ưu đãi cho khách hàng mới!',
      amount: '1,250,000,000 đ',
      rateLabel: 'Lãi suất /năm',
      rate: '12.0%',
      term: '6 tháng',
      badgeText: 'Mở mới 8%',
      isFeatured: true,
    ),
    DepositCardData(
      userName: 'Trần M. K',
      description: '📊 Lãi suất hấp dẫn, không cần chứng minh thu nhập!',
      amount: '3,000,000,000 đ',
      rateLabel: 'Lãi suất /năm',
      rate: '11.5%',
      term: '1 năm',
      badgeText: 'Chỉ cần 5%',
      isFeatured: true,
    ),
    DepositCardData(
      userName: 'Phạm T. D',
      description: '💸 Tiền gửi kỳ hạn 24 tháng, lãi suất cao nhất thị trường!',
      amount: '5,500,000,000 đ',
      rateLabel: 'Lãi suất /năm',
      rate: '13.0%',
      term: '2 năm',
      badgeText: 'Chỉ mở mới 10%',
    ),
    DepositCardData(
      userName: 'Lê H. A',
      description: '🎉 Ưu đãi lãi suất 3 tháng cho khách hàng VIP!',
      amount: '750,000,000 đ',
      rateLabel: 'Lãi suất /năm',
      rate: '9.0%',
      term: '3 tháng',
      badgeText: 'Mở mới 7%',
    ),
    DepositCardData(
      userName: 'Đỗ V. P',
      description: '🏦 Đầu tư an toàn, lãi suất cao với kỳ hạn linh hoạt!',
      amount: '4,200,000,000 đ',
      rateLabel: 'Lãi suất /năm',
      rate: '11.0%',
      term: '18 tháng',
      badgeText: 'Khuyến mãi 6%',
    ),
  ];


  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _setupAnimations();
    _entryCtrl.forward();
  }

  void _setupAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnims = List.generate(_sections, (i) {
      final s = (i * 0.15).clamp(0.0, 0.7);
      final e = (s + 0.30).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Interval(s, e, curve: Curves.easeOut)),
      );
    });
    _slideAnims = List.generate(_sections, (i) {
      final s = (i * 0.15).clamp(0.0, 0.7);
      final e = (s + 0.30).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Interval(s, e, curve: Curves.easeOut)),
      );
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _entryCtrl.reset();
    _entryCtrl.forward();
  }

  Widget _fade(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Real Figma background gradient image (812×812, placed top-center)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 420,
            child: Image.asset(
              'assets/images/img-bg-home.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Main content scroll
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.brandGreen,
            backgroundColor: AppTheme.white,
            displacement: 60,
            strokeWidth: 2.5,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: menu | logo | power (Figma: 82px height)
                      _fade(0, const TopHeader()),

                      // Gap between header and card: Figma 19:624 is at y=110, header=82px => gap≈28
                      const SizedBox(height: 28),

                      // Greeting card (Figma: 375x122, padding L24 R24)
                      _fade(1, const GreetingSection()),
                      const SizedBox(height: 20),

                      // White content area with rounded top corners
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppTheme.contentBackground,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Promo banner — Figma: no top gap, banner content at y:0
                            _fade(2, const PromoBanner()),
                            const SizedBox(height: 16),

                            // Filter tabs
                            _fade(3, const FilterTabs()),
                            const SizedBox(height: 4),

                            // Deposit card feed
                            _fade(
                              4,
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    ..._cards.asMap().entries.map((e) =>
                                      DepositCard(
                                        data: e.value,
                                        showDivider: e.key < _cards.length - 1,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // "Tất cả" button
                                    const ViewAllButton(),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
