import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'act_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  List<Map<String, dynamic>> _results = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _showHistory = true;
  String _selectedCategory = "Все категории";
  String _sortBy = "По релевантности";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Официальные цвета государственной символики РК
  static const Color primaryBlue = Color(0xFF00AFDB);
  static const Color darkBlue = Color(0xFF003D82);
  static const Color lightBlue = Color(0xFFE6F7FF);
  static const Color goldAccent = Color(0xFFFFCC00);
  static const Color govGreen = Color(0xFF10B981);
  static const Color govRed = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  final List<String> _categories = [
    "Все категории",
    "Конституция",
    "Конституционные акты",
    "Кодексы",
    "Законы",
    "Указы",
    "Постановления",
  ];

  final List<String> _sortOptions = [
    "По релевантности",
    "По дате (новые)",
    "По дате (старые)",
    "По популярности",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _controller.addListener(() {
      setState(() {
        _showHistory = _controller.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getDeclension(int count) {
    final remainder = count % 10;
    final remainder100 = count % 100;

    if (remainder100 >= 11 && remainder100 <= 19) {
      return 'документов';
    } else if (remainder == 1) {
      return 'документ';
    } else if (remainder >= 2 && remainder <= 4) {
      return 'документа';
    } else {
      return 'документов';
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'конституция':
      case 'конституционные акты':
        return Icons.account_balance;
      case 'кодексы':
        return Icons.gavel;
      case 'законы':
        return Icons.description;
      case 'указы':
        return Icons.verified;
      case 'постановления':
        return Icons.assignment;
      default:
        return Icons.article;
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }

    setState(() => _isLoading = true);
    _animationController.forward(from: 0);

    final data = await _apiService.searchActs(query);

    var filtered = _selectedCategory == "Все категории"
        ? data
        : data.where((act) => act['category'] == _selectedCategory).toList();

    filtered = _sortResults(filtered);

    setState(() {
      _results = filtered;
      _isLoading = false;
      _showHistory = false;
    });
  }

  List<Map<String, dynamic>> _sortResults(List<Map<String, dynamic>> results) {
    switch (_sortBy) {
      case "По дате (новые)":
        results.sort((a, b) => b['date'].compareTo(a['date']));
        break;
      case "По дате (старые)":
        results.sort((a, b) => a['date'].compareTo(b['date']));
        break;
      case "По популярности":
        results.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
        break;
      default:
        break;
    }
    return results;
  }

  void _selectFromHistory(String query) {
    _controller.text = query;
    _search();
  }

  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  void _navigateToDetail(String actId, String actTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActDetailScreen(
          actId: actId,
          actTitle: actTitle,
        ),
      ),
    );
  }

  String _formatViews(dynamic views) {
    if (views == null) return '0';
    final int count = int.tryParse(views.toString()) ?? 0;
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // Методы для работы с избранным
  Future<bool> _isFavorite(String actId) async {
    final storage = await StorageService.getInstance();
    final favorites = storage.getFavorites();
    return favorites.any((fav) => (fav['id'] ?? fav['title']) == actId);
  }

  Future<void> _toggleFavorite(Map<String, dynamic> act) async {
    final storage = await StorageService.getInstance();
    final actId = act['id'] ?? act['title'];
    final isFav = await _isFavorite(actId);

    if (isFav) {
      await storage.removeFavoriteById(actId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Удалено из избранного',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: govRed,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      await storage.addFavorite(act);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Добавлено в избранное',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: govGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    setState(() {}); // Обновить UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(innerBoxIsScrolled),
          ];
        },
        body: Column(
          children: [
            _buildSearchPanel(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _showHistory && _searchHistory.isNotEmpty
                  ? _buildHistoryView()
                  : _results.isEmpty && _controller.text.isNotEmpty
                  ? _buildEmptyState()
                  : _results.isEmpty
                  ? _buildInitialState()
                  : _buildResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: innerBoxIsScrolled ? 4 : 0,
      shadowColor: Colors.black.withOpacity(0.1),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF0099CC)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "ІЗДЕУ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Поиск",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, goldAccent, primaryBlue],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Поле поиска с градиентной рамкой
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.3), goldAccent.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _search(),
                style: const TextStyle(fontSize: 15, color: textPrimary),
                decoration: InputDecoration(
                  hintText: "Введите название, номер или ключевые слова...",
                  hintStyle: const TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.search,
                      color: primaryBlue,
                      size: 24,
                    ),
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: textSecondary),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _showHistory = true;
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Фильтры в новом стиле
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Категория',
                  icon: Icons.filter_list,
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                    if (_controller.text.isNotEmpty) {
                      _search();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Сортировка',
                  icon: Icons.sort,
                  value: _sortBy,
                  items: _sortOptions,
                  onChanged: (newValue) {
                    setState(() {
                      _sortBy = newValue!;
                    });
                    if (_results.isNotEmpty) {
                      setState(() {
                        _results = _sortResults(_results);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Кнопка поиска с градиентом
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, Color(0xFF0099CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "Найти документы",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: darkBlue, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 13,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.1), lightBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Поиск документов...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [goldAccent, goldAccent.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: goldAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'История поиска',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Очистить'),
                style: TextButton.styleFrom(
                  foregroundColor: govRed,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue.withOpacity(0.1), lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, color: primaryBlue, size: 24),
                  ),
                  title: Text(
                    query,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Нажмите для повторного поиска',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  onTap: () => _selectFromHistory(query),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue.withOpacity(0.1), lightBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 80,
                color: primaryBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Документы не найдены",
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Попробуйте изменить параметры поиска или используйте другие ключевые слова",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Совет: Используйте более общие термины",
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF0099CC)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "База НПА Республики Казахстан",
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Введите название документа, номер или ключевые слова для начала поиска",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickSearchChip("Конституция", Icons.account_balance),
                _buildQuickSearchChip("Кодексы", Icons.gavel),
                _buildQuickSearchChip("Законы", Icons.description),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchChip(String label, IconData icon) {
    return InkWell(
      onTap: () {
        _controller.text = label;
        _search();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
      Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [govGreen.withOpacity(0.1), lightBlue],
        ),
        border: Border(
          bottom: BorderSide(
            color: govGreen.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: govGreen,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: govGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Найдено: ${_results.length} ${_getDeclension(_results.length)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
        ],
      ),
    ),
    Expanded(
    child: FadeTransition(
    opacity: _fadeAnimation,
    child: ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _results.length,
    itemBuilder: (context, index) {
    final act = _results[index];
    return _buildActCard(act, index);
    },
    ),
    ),
    ),
      ],
    );
  }

  Widget _buildActCard(Map<String, dynamic> act, int index) {
    final actId = act['id'] ?? act['title'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(actId, act['title']),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.1),
                      lightBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForCategory(act['category']),
                  color: primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (act['subtitle'] != null && act['subtitle'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        act['subtitle'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue.withOpacity(0.1),
                                lightBlue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForCategory(act['category']),
                                size: 14,
                                color: primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                act['category'] ?? 'Документ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (act['date'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: goldAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  act['date'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (act['views'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: govGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: govGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatViews(act['views']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: govGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                govGreen,
                                govGreen.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: govGreen.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Действует",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Кнопка избранного
                        FutureBuilder<bool>(
                          future: _isFavorite(actId),
                          builder: (context, snapshot) {
                            final isFav = snapshot.data ?? false;
                            return IconButton(
                              onPressed: () => _toggleFavorite(act),
                              icon: Icon(
                                isFav ? Icons.bookmark : Icons.bookmark_border,
                                color: isFav ? goldAccent : textSecondary,
                              ),
                              tooltip: isFav ? 'Удалить из избранного' : 'Добавить в избранное',
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: primaryBlue,
                            size: 18,
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
      ),
    );
  }
}