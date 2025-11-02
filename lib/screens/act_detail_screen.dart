import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'chapter_viewer_screen.dart';

class ActDetailScreen extends StatefulWidget {
  final String actId;
  final String actTitle;

  const ActDetailScreen({
    super.key,
    required this.actId,
    required this.actTitle,
  });

  @override
  State<ActDetailScreen> createState() => _ActDetailScreenState();
}

class _ActDetailScreenState extends State<ActDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _apiService = ApiService.instance;
  final PdfService _pdfService = PdfService();

  Map<String, dynamic>? _actData;
  bool _isLoading = true;
  bool _isBookmarked = false;
  bool _isGeneratingPdf = false;
  double _fontSize = 15.0;

  // Официальные цвета государственной символики РК
  static const Color primaryBlue = Color(0xFF00AFDB);
  static const Color darkBlue = Color(0xFF003D82);
  static const Color lightBlue = Color(0xFFE6F7FF);
  static const Color goldAccent = Color(0xFFFFCC00);
  static const Color govGreen = Color(0xFF10B981);
  static const Color govRed = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActData();
  }

  Future<void> _loadActData() async {
    try {
      final data = await _apiService.getActById(widget.actId);
      await _apiService.incrementViews(widget.actId);
      if (mounted) {
        setState(() {
          _actData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Ошибка загрузки данных: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareAct() {
    if (_actData != null) {
      Share.share(
        '${_actData!['title']}\n\n${_actData!['subtitle']}\n\nПросмотрено через ӘДІЛЕТ KZ',
        subject: _actData!['title'],
      );
    }
  }

  // 📄 ИСПРАВЛЕННАЯ ФУНКЦИЯ: Генерация PDF
  Future<void> _generatePdf() async {
    if (_actData == null) {
      _showErrorSnackBar('Данные документа недоступны');
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      // Вызываем PdfService напрямую вместо ApiService
      await _pdfService.generateProtectedPdf(
        title: _actData!['title'] ?? 'Без названия',
        content: _actData!['fullText'] ?? 'Текст документа недоступен',
        subtitle: _actData!['subtitle'] ?? '',
        actNumber: _actData!['number'] ?? 'Не указан',
        date: _actData!['date'] ?? 'Не указана',
        category: _actData!['category'] ?? 'Документ',
      );

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
                  child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PDF документ успешно создан и готов к отправке',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: govGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка генерации PDF: $e');
      if (mounted) {
        _showErrorSnackBar('Ошибка при создании PDF: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
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
              child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: govRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
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
              child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Текст успешно скопирован',
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

  void _navigateToChapter(int sectionIndex) {
    if (_actData != null) {
      final sections = _actData!['sections'] as List?;
      if (sections != null && sectionIndex < sections.length) {
        final section = sections[sectionIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterViewerScreen(
              actId: widget.actId,
              sectionIndex: sectionIndex,
              sectionTitle: section['title'] ?? 'Раздел ${sectionIndex + 1}',
              totalSections: sections.length,
            ),
          ),
        );
      }
    }
  }

  String _formatViews(dynamic views) {
    if (views == null) return '0';
    final int count = int.tryParse(views.toString()) ?? 0;
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
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
        body: _isLoading
            ? _buildLoadingState()
            : _actData == null
            ? _buildErrorState()
            : Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTextTab(),
                  _buildInfoTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: innerBoxIsScrolled ? 4 : 0,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
        color: innerBoxIsScrolled ? textPrimary : Colors.white,
      ),
      actions: [
        // Кнопка генерации PDF с индикатором загрузки
        if (_isGeneratingPdf)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  innerBoxIsScrolled ? primaryBlue : Colors.white,
                ),
              ),
            ),
          )
        else
          IconButton(
            onPressed: _actData != null ? _generatePdf : null,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Скачать PDF',
            color: innerBoxIsScrolled ? textPrimary : Colors.white,
          ),
        IconButton(
          onPressed: _shareAct,
          icon: const Icon(Icons.share),
          tooltip: 'Поделиться',
          color: innerBoxIsScrolled ? textPrimary : Colors.white,
        ),
        IconButton(
          onPressed: () {
            setState(() => _isBookmarked = !_isBookmarked);
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
                      child: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isBookmarked
                          ? 'Добавлено в избранное'
                          : 'Удалено из избранного',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                backgroundColor: _isBookmarked ? govGreen : govRed,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          ),
          tooltip: 'Избранное',
          color: innerBoxIsScrolled ? textPrimary : Colors.white,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, right: 56, bottom: 16),
        title: Text(
          widget.actTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: innerBoxIsScrolled ? textPrimary : Colors.white,
            shadows: innerBoxIsScrolled
                ? null
                : [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue,
                    Color(0xFF0099CC),
                    darkBlue,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: goldAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (_actData != null)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(_actData!['category']),
                            color: goldAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _actData!['category'] ?? 'Документ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryBlue,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.description, size: 20),
            text: 'Текст',
          ),
          Tab(
            icon: Icon(Icons.info_outline, size: 20),
            text: 'Информация',
          ),
          Tab(
            icon: Icon(Icons.history, size: 20),
            text: 'История',
          ),
        ],
      ),
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
            "Загрузка документа...",
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

  Widget _buildErrorState() {
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
                  colors: [govRed.withOpacity(0.1), govRed.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: govRed.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Документ не найден",
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "К сожалению, запрашиваемый документ не доступен",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Вернуться назад'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue.withOpacity(0.1), lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Размер шрифта',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_fontSize > 12) {
                              setState(() => _fontSize -= 1);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: primaryBlue,
                          iconSize: 22,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_fontSize.toInt()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_fontSize < 24) {
                              setState(() => _fontSize += 1);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: primaryBlue,
                          iconSize: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _copyText(_actData!['fullText'] ?? ''),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копировать весь текст'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primaryBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SelectableText(
                _actData!['fullText'] ?? 'Текст документа недоступен',
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.7,
                  color: textPrimary,
                  fontFamily: 'Georgia',
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Остальные методы остаются без изменений...
  // _buildInfoTab(), _buildHistoryTab(), _buildInfoRow(), _getCategoryIcon()

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, primaryBlue.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Общая информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Название', _actData!['title']),
                _buildInfoRow('Номер документа', _actData!['number'] ?? '—'),
                _buildInfoRow('Дата принятия', _actData!['date'] ?? '—'),
                _buildInfoRow('Издатель', _actData!['publisher'] ?? '—'),
                _buildInfoRow(
                  'Последнее обновление',
                  _actData!['lastUpdate'] ?? '—',
                ),
                _buildInfoRow('Категория', _actData!['category'] ?? '—'),
                _buildInfoRow(
                  'Статус',
                  _actData!['status'] ?? 'Действует',
                  isStatus: true,
                ),
                _buildInfoRow(
                  'Просмотров',
                  _formatViews(_actData!['views']),
                  isViews: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final revisions = _actData!['revisions'] as List? ?? [];

    if (revisions.isEmpty) {
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
                    colors: [
                      textSecondary.withOpacity(0.1),
                      textSecondary.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history,
                  size: 80,
                  color: textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'История изменений отсутствует',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: revisions.length,
      itemBuilder: (context, index) {
        final revision = revisions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                revision['date'] ?? '—',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                revision['description'] ?? 'Без описания',
                style: const TextStyle(
                  fontSize: 15,
                  color: textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        bool isStatus = false,
        bool isViews = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [govGreen, govGreen.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (isViews)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.1),
                    lightBlue.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility,
                    size: 16,
                    color: primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
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
}