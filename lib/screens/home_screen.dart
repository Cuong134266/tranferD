import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/top_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/promo_banner.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/deposit_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/view_all_button.dart';
import 'search_screen.dart';
import 'post_listing_screen.dart';

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
  int _selectedTab = 0;
  bool _isTabLoading = false;
  bool _showJumpTop = false;

  // Pagination state for "Tất cả" tab
  static const int _pageSize = 10;
  int _loadedCount = 10;
  bool _isLoadingMore = false;
  late ScrollController _scrollController;

  static const int _sections = 5;

  // ── Fake data: 6 featured cards ──
  static const List<DepositCardData> _featuredCards = [
    // ── Top 2: highest badge % → green #E2FDCE ──
    DepositCardData(
      userName: 'Phạm T. D',
      description: '💎 Sổ tiết kiệm kỳ hạn dài, lãi suất ưu đãi đặc biệt!',
      amount: '5,500,000,000 đ',
      rate: '13.0%',
      term: '2 năm',
      badgeText: 'Hơn mở mới 10%',
      avatarColor: Color(0xFF00897B),
      avatarImage: 'assets/images/avatar_1.png',
      isFeatured: true,
    ),
    DepositCardData(
      userName: 'Nguyễn H. L',
      description:
          '🚀 Khuyến mãi đặc biệt, lãi suất 12% ưu đãi cho khách hàng mới!',
      amount: '1,250,000,000 đ',
      rate: '12.0%',
      term: '6 tháng',
      badgeText: 'Hơn mở mới 8%',
      avatarColor: Color(0xFF3A00F9),
      isFeatured: true,
    ),
    // ── Rest: sorted by rate descending → yellow #F5FED8 ──
    DepositCardData(
      userName: 'Trần M. K',
      description: '📊 Lãi suất hấp dẫn, không cần chứng minh thu nhập!',
      amount: '3,000,000,000 đ',
      rate: '11.5%',
      term: '1 năm',
      badgeText: 'Hơn mở mới 5%',
      avatarColor: Color(0xFFE91E63),
      avatarImage: 'assets/images/avatar_2.png',
    ),
    DepositCardData(
      userName: 'Đỗ V. P',
      description: '🏦 Đầu tư an toàn, lãi suất cao với kỳ hạn linh hoạt!',
      amount: '4,200,000,000 đ',
      rate: '11.0%',
      term: '18 tháng',
      badgeText: 'Hơn mở mới 6%',
      avatarColor: Color(0xFF1565C0),
    ),
    DepositCardData(
      userName: 'Vũ T. H',
      description: '✨ Gửi tiền online nhận thêm 0.5% lãi suất thưởng!',
      amount: '2,800,000,000 đ',
      rate: '10.5%',
      term: '12 tháng',
      badgeText: 'Hơn mở mới 4%',
      avatarColor: Color(0xFF6A1B9A),
      avatarImage: 'assets/images/avatar_3.png',
    ),
    DepositCardData(
      userName: 'Lê H. A',
      description: '🎉 Ưu đãi lãi suất 3 tháng cho khách hàng VIP!',
      amount: '750,000,000 đ',
      rate: '9.0%',
      term: '3 tháng',
      badgeText: 'Hơn mở mới 3%',
      avatarColor: Color(0xFFFF6F00),
    ),
  ];

  // ── Fake data: 50 "all" cards ──
  static final List<DepositCardData> _allCards = _generateAllCards();

  static List<DepositCardData> _generateAllCards() {
    final names = [
      'Nguyễn V. A',
      'Trần T. B',
      'Lê H. C',
      'Phạm M. D',
      'Hoàng T. E',
      'Vũ Q. F',
      'Đặng N. G',
      'Bùi T. H',
      'Đỗ V. I',
      'Ngô T. K',
      'Dương H. L',
      'Lý M. N',
      'Hồ T. O',
      'Phan V. P',
      'Trương Q. R',
      'Mai T. S',
      'Tạ H. T',
      'Đinh V. U',
      'Lương T. V',
      'Châu M. X',
    ];
    final descriptions = [
      '💰 Sổ tiết kiệm ổn định, lãi suất hấp dẫn mỗi tháng!',
      '📈 Đầu tư thông minh, sinh lời bền vững qua từng kỳ!',
      '🌟 Ưu đãi vàng dành cho khách hàng gửi tiền lần đầu!',
      '🔒 An tâm tuyệt đối, bảo hiểm tiền gửi lên tới 125 triệu!',
      '💎 Kỳ hạn linh hoạt, phù hợp mọi nhu cầu tài chính!',
      '🚀 Gửi tiết kiệm online, nhận lãi cao hơn quầy 0.3%!',
      '🎯 Chiến lược tài chính thông minh với gói combo tiết kiệm!',
      '🏆 Top 3 ngân hàng có lãi suất cạnh tranh nhất thị trường!',
      '✨ Mở sổ mới hôm nay, nhận ngay voucher 500K!',
      '📊 Lãi kép tự động tái đầu tư, tối ưu lợi nhuận!',
    ];
    final terms = [
      '3 tháng',
      '6 tháng',
      '9 tháng',
      '12 tháng',
      '18 tháng',
      '24 tháng',
      '36 tháng',
    ];
    final badges = [
      'Hơn mở mới 5%',
      'Hơn mở mới 7%',
      'Hơn mở mới 3%',
      'Hơn mở mới 9%',
      'Hơn mở mới 4%',
      'Hơn mở mới 6%',
      'Hơn mở mới 8%',
      'Hơn mở mới 2%',
    ];
    final rand = Random(42); // Fixed seed for consistent data

    return List.generate(50, (i) {
      // Realistic range: 5 million to 10 billion
      final tier = rand.nextInt(10);
      int amount;
      if (tier < 3) {
        // 30%: small amounts 5M - 50M
        amount = (5 + rand.nextInt(46)) * 1000000;
      } else if (tier < 6) {
        // 30%: medium 50M - 500M
        amount = (50 + rand.nextInt(451)) * 1000000;
      } else if (tier < 9) {
        // 30%: large 500M - 5B
        amount = (500 + rand.nextInt(4501)) * 1000000;
      } else {
        // 10%: very large 5B - 10B
        amount = (5000 + rand.nextInt(5001)) * 1000000;
      }
      final rate = 6.0 + rand.nextDouble() * 7.0; // 6% to 13%
      final avatarColors = [
        const Color(0xFF3A00F9),
        const Color(0xFFE91E63),
        const Color(0xFF00897B),
        const Color(0xFFFF6F00),
        const Color(0xFF1565C0),
        const Color(0xFF6A1B9A),
        const Color(0xFFC62828),
        const Color(0xFF2E7D32),
        const Color(0xFF00838F),
        const Color(0xFF4527A0),
      ];
      final avatarImages = [
        'assets/images/img-ava.png',
        'assets/images/avatar_1.png',
        'assets/images/avatar_2.png',
        'assets/images/avatar_3.png',
      ];
      final usePhoto = rand.nextBool();
      return DepositCardData(
        userName: names[i % names.length],
        description: descriptions[i % descriptions.length],
        amount: '${_formatAmount(amount)} đ',
        rate: '${rate.toStringAsFixed(1)}%',
        term: terms[i % terms.length],
        badgeText: rand.nextDouble() < 0.4 ? badges[i % badges.length] : null,
        avatarColor: avatarColors[i % avatarColors.length],
        avatarImage: usePhoto ? avatarImages[i % avatarImages.length] : null,
        isFeatured: false,
      );
    });
  }

  static String _formatAmount(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _scrollController = ScrollController()..addListener(_onScroll);
    _setupAnimations();
    _entryCtrl.forward();
  }

  void _onScroll() {
    // Show/hide jump to top
    final show = _scrollController.position.pixels > 300;
    if (show != _showJumpTop) {
      setState(() => _showJumpTop = show);
    }

    if (_selectedTab != 1) return;
    if (_isLoadingMore) return;
    if (_loadedCount >= _allCards.length) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    setState(() => _isLoadingMore = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _loadedCount = (_loadedCount + _pageSize).clamp(0, _allCards.length);
      _isLoadingMore = false;
    });
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
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _slideAnims = List.generate(_sections, (i) {
      final s = (i * 0.15).clamp(0.0, 0.7);
      final e = (s + 0.30).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _entryCtrl.reset();
    _entryCtrl.forward();
    setState(() {
      _loadedCount = _pageSize;
    });
  }

  void _onTabChanged(int index) {
    if (index == _selectedTab) return;
    setState(() {
      _selectedTab = index;
      _isTabLoading = true;
      if (index == 1) {
        _loadedCount = _pageSize;
      }
    });
    // Show skeleton briefly, then reveal data
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isTabLoading = false);
    });
  }

  void _onViewAll() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    _onTabChanged(1);
  }

  Widget _fade(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  List<DepositCardData> get _allVisibleCards {
    return _allCards.take(_loadedCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background gradient image
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
              controller: _scrollController,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fade(0, const TopHeader()),
                      const SizedBox(height: 28),
                      _fade(
                        1,
                        GreetingSection(
                          onSearchTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PostListingScreen(
                                  data: const DepositCardData(
                                    userName: 'Hoang Phu Ngoc Tuong',
                                    description: 'Sổ tiết kiệm của tôi',
                                    amount: '300,000,000 đ',
                                    rate: '7.3%',
                                    term: '12 tháng',
                                  ),
                                ),
                              ),
                            );
                          },
                          onPostTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PostListingScreen(
                                  data: const DepositCardData(
                                    userName: 'Hoang Phu Ngoc Tuong',
                                    description: 'Sổ tiết kiệm của tôi',
                                    amount: '300,000,000 đ',
                                    rate: '7.3%',
                                    term: '12 tháng',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
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
                            _fade(2, const PromoBanner()),
                            FilterTabs(
                              onTabChanged: _onTabChanged,
                              selectedIndex: _selectedTab,
                              onSearchTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SearchScreen(
                                      allCards: [
                                        ..._featuredCards,
                                        ..._generateAllCards(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            _fade(
                              4,
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _isTabLoading
                                    ? _buildSkeletonList()
                                    : (_selectedTab == 0
                                          ? _buildFeaturedList()
                                          : _buildAllList()),
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

          // Sticky tab bar overlay — appears when scrolled past natural position
          if (_showJumpTop)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.contentBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 8),
                  child: FilterTabs(
                    onTabChanged: _onTabChanged,
                    selectedIndex: _selectedTab,
                  ),
                ),
              ),
            ),

          // Jump to top button — Figma: 40×40 lime circle #C6F84C, drop shadows
          if (_showJumpTop)
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6F84C), // lime
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14191F25), // ~8% opacity
                        blurRadius: 15,
                        offset: Offset(0, 10),
                        spreadRadius: -3,
                      ),
                      BoxShadow(
                        color: Color(0x0F191F25), // ~6% opacity
                        blurRadius: 6,
                        offset: Offset(0, 4),
                        spreadRadius: -3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      children: [
        for (int i = 0; i < 4; i++) const SkeletonCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeaturedList() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          ..._featuredCards.asMap().entries.map(
            (e) => DepositCard(
              data: e.value,
              showDivider: e.key < _featuredCards.length - 1,
            ),
          ),
          const SizedBox(height: 24),
          ViewAllButton(onTap: _onViewAll),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAllList() {
    final cards = _allVisibleCards;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          ...cards.asMap().entries.map(
            (e) => DepositCard(
              data: e.value,
              showDivider: e.key < cards.length - 1 || _isLoadingMore,
            ),
          ),
          if (_isLoadingMore) ...[
            for (int i = 0; i < 3; i++) const SkeletonCard(),
          ],
          if (_loadedCount < _allCards.length && !_isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Cuộn xuống để xem thêm',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            ),
          if (_loadedCount >= _allCards.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Center(
                child: Text(
                  'Hãy quay lại thường xuyên để\nsăn thêm tài sản lãi cao nhé!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: const Color(0xFF7A8DA3),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
