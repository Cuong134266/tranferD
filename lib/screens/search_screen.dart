import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/deposit_card.dart';

// ─── Result group ─────────────────────────────────────────────────────────────
class _Group {
  final String label;
  final List<DepositCardData> cards;
  const _Group(this.label, this.cards);
}

enum _Tab { all, byRate, byTerm, byAmount, aboveMarket, byPerson }

const _tabLabels = {
  _Tab.all: 'Tất cả',
  _Tab.byRate: 'Lãi suất',
  _Tab.byTerm: 'Kỳ hạn',
  _Tab.byAmount: 'Số tiền',
  _Tab.aboveMarket: 'Hơn thị trường',
  _Tab.byPerson: 'Mọi người',
};

// ─── Screen ───────────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  final List<DepositCardData> allCards;
  const SearchScreen({super.key, required this.allCards});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  _Tab _activeTab = _Tab.all;
  List<_Group> _groups = [];
  bool _hasSearched = false;
  static const int _previewCount = 3;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final text = _ctrl.text.trim();
    setState(() {
      _hasSearched = text.isNotEmpty;
      _groups = text.isEmpty ? [] : _buildGroups(text, _activeTab);
    });
  }

  void _onTabChanged(_Tab tab) {
    setState(() {
      _activeTab = tab;
      _groups = _ctrl.text.trim().isEmpty
          ? []
          : _buildGroups(_ctrl.text.trim(), tab);
    });
  }

  List<_Group> _buildGroups(String text, _Tab tab) {
    final q = text.toLowerCase();
    final cards = widget.allCards;

    final byPerson = cards
        .where((c) => c.userName.toLowerCase().contains(q))
        .toList();
    final byRate = cards
        .where((c) => c.rate.toLowerCase().contains(q))
        .toList();
    final byTerm = cards
        .where((c) => c.term.toLowerCase().contains(q))
        .toList();
    // Số tiền: match raw number in amount string
    final byAmount = cards
        .where(
          (c) =>
              c.amount
                  .replaceAll(RegExp(r'[^0-9]'), '')
                  .contains(text.replaceAll(RegExp(r'[^0-9]'), '')) &&
              text.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty,
        )
        .toList();
    // Hơn thị trường: rate >= 8%
    const marketRate = 8.0;
    final aboveMarket =
        cards.where((c) {
          final r = double.tryParse(c.rate.replaceAll('%', '').trim()) ?? 0;
          return r >= marketRate;
        }).toList()..sort((a, b) {
          final ra = double.tryParse(a.rate.replaceAll('%', '').trim()) ?? 0;
          final rb = double.tryParse(b.rate.replaceAll('%', '').trim()) ?? 0;
          return rb.compareTo(ra);
        });

    switch (tab) {
      case _Tab.byPerson:
        return [if (byPerson.isNotEmpty) _Group('Mọi người', byPerson)];
      case _Tab.byRate:
        return [if (byRate.isNotEmpty) _Group('Theo lãi suất', byRate)];
      case _Tab.byTerm:
        return [if (byTerm.isNotEmpty) _Group('Theo kỳ hạn', byTerm)];
      case _Tab.byAmount:
        return [if (byAmount.isNotEmpty) _Group('Theo số tiền', byAmount)];
      case _Tab.aboveMarket:
        return [
          if (aboveMarket.isNotEmpty)
            _Group('Hơn thị trường (≥${marketRate}%)', aboveMarket),
        ];
      case _Tab.all:
        return [
          if (byPerson.isNotEmpty) _Group('Mọi người', byPerson),
          if (byRate.isNotEmpty) _Group('Theo lãi suất', byRate),
          if (byTerm.isNotEmpty) _Group('Theo kỳ hạn', byTerm),
          if (byAmount.isNotEmpty) _Group('Theo số tiền', byAmount),
          if (aboveMarket.isNotEmpty) _Group('Hơn thị trường', aboveMarket),
        ];
    }
  }

  // ── Featured cards (for default page) ────────────────────────────────────
  List<DepositCardData> get _featuredCards {
    final sorted = [...widget.allCards]
      ..sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        final ra = double.tryParse(a.rate.replaceAll('%', '').trim()) ?? 0;
        final rb = double.tryParse(b.rate.replaceAll('%', '').trim()) ?? 0;
        return rb.compareTo(ra);
      });
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabRow(),
            const Divider(height: 1, color: Color(0xFFECEFF3)),
            Expanded(
              child: _hasSearched ? _buildResults() : _buildDefaultPage(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF01250F),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFF7A8DA3),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: const Color(0xFF01250F),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tài sản...',
                        hintStyle: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: const Color(0xFF7A8DA3),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() {
                          _hasSearched = false;
                          _groups = [];
                        });
                        _focus.requestFocus();
                      },
                      child: const Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Color(0xFF7A8DA3),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category tabs ─────────────────────────────────────────────────────────
  Widget _buildTabRow() {
    return Container(
      color: Colors.white,
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _Tab.values.map((tab) {
          final isActive = _activeTab == tab;
          return GestureDetector(
            onTap: () => _onTabChanged(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF307A62) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF307A62)
                      : const Color(0xFFEAEBEB),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _tabLabels[tab]!,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF112727),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Default page (chưa gõ gì) ─────────────────────────────────────────────
  Widget _buildDefaultPage() {
    final hints = ['8%/năm', '12 tháng', 'Hơn mở mới', '6 tháng', '9%'];
    final top = _featuredCards;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Keyword chips
        Text(
          'Gợi ý từ khóa',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7A8DA3),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hints
              .map(
                (h) => GestureDetector(
                  onTap: () {
                    _ctrl.text = h;
                    _ctrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: h.length),
                    );
                    setState(() {
                      _hasSearched = true;
                      _groups = _buildGroups(h, _activeTab);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFECEFF3)),
                    ),
                    child: Text(
                      h,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: const Color(0xFF112727),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        // Featured section
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tài sản nổi bật',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF01250F),
              ),
            ),
            Text(
              'Xem tất cả',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF307A62),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (int i = 0; i < top.length; i++)
              DepositCard(data: top[i], showDivider: i < top.length - 1),
          ],
        ),
      ],
    );
  }

  // ── Search results ────────────────────────────────────────────────────────
  Widget _buildResults() {
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy kết quả',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A8DA3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thử từ khóa khác hoặc đổi danh mục',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _groups.length,
      itemBuilder: (_, i) => _buildGroup(_groups[i]),
    );
  }

  // ── Single group ──────────────────────────────────────────────────────────
  Widget _buildGroup(_Group g) {
    final preview = g.cards.take(_previewCount).toList();
    final extra = g.cards.length - _previewCount;
    final hasMore = extra > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                g.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF01250F),
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: () => _showAll(g),
                  child: Text(
                    'Xem tất cả',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF307A62),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Column(
          children: [
            for (int i = 0; i < preview.length; i++)
              DepositCard(
                data: preview[i],
                showDivider: i < preview.length - 1,
              ),
            if (hasMore)
              InkWell(
                onTap: () => _showAll(g),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFECEFF3))),
                  ),
                  child: Text(
                    'Xem thêm $extra kết quả',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF307A62),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showAll(_Group g) {
    final tabMap = {
      'Mọi người': _Tab.byPerson,
      'Theo lãi suất': _Tab.byRate,
      'Theo kỳ hạn': _Tab.byTerm,
      'Theo số tiền': _Tab.byAmount,
      'Hơn thị trường (≥8.0%)': _Tab.aboveMarket,
      'Hơn thị trường': _Tab.aboveMarket,
    };
    final tab = tabMap[g.label];
    if (tab != null) _onTabChanged(tab);
  }
}
