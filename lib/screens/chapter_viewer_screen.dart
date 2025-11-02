import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ChapterViewerScreen extends StatefulWidget {
  final String actId;
  final int sectionIndex;
  final String sectionTitle;
  final int totalSections;

  const ChapterViewerScreen({
    super.key,
    required this.actId,
    required this.sectionIndex,
    required this.sectionTitle,
    required this.totalSections,
  });

  @override
  State<ChapterViewerScreen> createState() => _ChapterViewerScreenState();
}

class _ChapterViewerScreenState extends State<ChapterViewerScreen> {
  final ApiService _apiService = ApiService.instance;
  Map<String, dynamic>? _sectionData;
  bool _isLoading = true;
  double _fontSize = 15.0;

  static const Color primaryBlue = Color(0xFF0066B3);
  static const Color darkBlue = Color(0xFF003D82);
  static const Color lightBlue = Color(0xFFE6F2FF);
  static const Color goldAccent = Color(0xFFFFB81C);

  @override
  void initState() {
    super.initState();
    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    final data = await _apiService.getSectionContent(
      widget.actId,
      widget.sectionIndex,
    );
    setState(() {
      _sectionData = data;
      _isLoading = false;
    });
  }

  void _navigateToSection(int newIndex) {
    if (newIndex >= 0 && newIndex < widget.totalSections) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterViewerScreen(
            actId: widget.actId,
            sectionIndex: newIndex,
            sectionTitle: 'Раздел ${newIndex + 1}',
            totalSections: widget.totalSections,
          ),
        ),
      );
    }
  }

  void _copyText() {
    if (_sectionData != null) {
      Clipboard.setData(ClipboardData(text: _sectionData!['content']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Текст главы скопирован'),
          backgroundColor: primaryBlue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sectionTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            if (_sectionData != null)
              Text(
                '${_sectionData!['articles']} статей',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBlue),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, goldAccent],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
        ),
      )
          : _sectionData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Глава не найдена',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Панель инструментов
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                // Размер шрифта
                const Text(
                  'Размер:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_fontSize > 12) {
                      setState(() => _fontSize -= 1);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: primaryBlue,
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_fontSize.toInt()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_fontSize < 24) {
                      setState(() => _fontSize += 1);
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: primaryBlue,
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                // Кнопка копирования
                OutlinedButton.icon(
                  onPressed: _copyText,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Копировать'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(color: primaryBlue),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Информация о главе
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  lightBlue.withOpacity(0.5),
                  Colors.white,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.sectionIndex + 1}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sectionData!['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.article,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Содержит ${_sectionData!['articles']} статей',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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

          // Содержание главы
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SelectableText(
                  _sectionData!['content'] ??
                      'Содержание главы недоступно',
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.7,
                    color: const Color(0xFF1F2937),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
            ),
          ),

          // Навигация между главами
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Предыдущая глава
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.sectionIndex > 0
                        ? () => _navigateToSection(
                        widget.sectionIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Предыдущая'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      disabledForegroundColor:
                      Colors.grey.withOpacity(0.38),
                      side: BorderSide(
                        color: widget.sectionIndex > 0
                            ? primaryBlue
                            : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Индикатор позиции
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.sectionIndex + 1} / ${widget.totalSections}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Следующая глава
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.sectionIndex <
                        widget.totalSections - 1
                        ? () => _navigateToSection(
                        widget.sectionIndex + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Следующая'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
}