import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';
// Для веба
import 'dart:html' as html;

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // Кэш для шрифтов
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  // 🔤 Загрузка локальных шрифтов из assets
  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;

    try {
      print('🔄 Loading fonts from assets...');

      final regularData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

      _regularFont = pw.Font.ttf(regularData);
      _boldFont = pw.Font.ttf(boldData);

      print('✅ Fonts loaded successfully!');
    } catch (e) {
      print('❌ Error loading fonts: $e');
      rethrow;
    }
  }

  // 📄 Создание PDF документа как изображения (защита от копирования)
  Future<void> generateProtectedPdf({
    required String title,
    required String content,
    required String subtitle,
    required String actNumber,
    required String date,
    required String category,
  }) async {
    try {
      await _loadFonts();

      // Сначала создаём временный PDF с текстом
      final tempPdf = pw.Document();

      tempPdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: _regularFont!, bold: _boldFont!),
          build: (pw.Context context) => [
            _buildTitlePage(
              title: title,
              subtitle: subtitle,
              actNumber: actNumber,
              date: date,
              category: category,
            ),
            ..._buildContentPages(content),
          ],
        ),
      );

      // Конвертируем PDF в изображения
      final tempPdfBytes = await tempPdf.save();

      // Используем Printing для рендеринга страниц в изображения
      final images = Printing.raster(
        tempPdfBytes,
        dpi: 150, // Качество изображения
      );

      // Создаём финальный PDF из изображений
      final finalPdf = pw.Document();

      await for (final page in images) {
        final imageBytes = await page.toPng(); // Правильный метод
        final image = pw.MemoryImage(imageBytes);

        finalPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      // Сохраняем финальный PDF
      await _saveAndSharePdf(finalPdf, title);
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  // 📄 Титульная страница (БЕЗ ВОДЯНОГО ЗНАКА)
  pw.Widget _buildTitlePage({
    required String title,
    required String subtitle,
    required String actNumber,
    required String date,
    required String category,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        // Гербовая символика
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: PdfColors.blue50,
          ),
          child: pw.Center(
            child: pw.Text(
              'ҚАЗ',
              style: pw.TextStyle(
                fontSize: 16,
                font: _boldFont,
                color: PdfColors.blue700,
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 30),

        // Категория
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            category.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue700,
              font: _boldFont,
            ),
          ),
        ),

        pw.SizedBox(height: 20),

        // Заголовок
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 22,
            font: _boldFont,
            color: PdfColors.blue900,
          ),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 15),

        // Подзаголовок
        if (subtitle.isNotEmpty)
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
              font: _regularFont,
            ),
            textAlign: pw.TextAlign.center,
          ),

        pw.SizedBox(height: 25),

        // Информация о документе
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Номер документа:', actNumber),
              _buildInfoRow('Дата принятия:', date),
              _buildInfoRow('Статус:', 'Действующий'),
              _buildInfoRow('Источник:', 'AdiletZan.kz'),
              _buildInfoRow(
                'Дата генерации:',
                '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 30),

        // Предупреждение о защите
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.red200, width: 1),
          ),
          child: pw.Text(
            'ОФИЦИАЛЬНАЯ КОПИЯ. КОПИРОВАНИЕ И РАСПРОСТРАНЕНИЕ ЗАПРЕЩЕНО.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.red600,
              font: _boldFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 📝 Строка информации
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
                font: _boldFont,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey800,
                font: _regularFont,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📄 Страницы с содержанием
  List<pw.Widget> _buildContentPages(String content) {
    final lines = content.split('\n');
    final currentPageContent = <pw.Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        currentPageContent.add(pw.SizedBox(height: 12));
      } else if (line.trim().startsWith('РАЗДЕЛ') ||
          line.trim().startsWith('Глава') ||
          line.trim().startsWith('Статья')) {
        currentPageContent.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15, top: 10),
            child: pw.Text(
              line.trim(),
              style: pw.TextStyle(
                fontSize: 14,
                font: _boldFont,
                color: PdfColors.blue800,
              ),
            ),
          ),
        );
      } else if (line.trim().startsWith(RegExp(r'^[0-9]+\..*'))) {
        currentPageContent.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8, left: 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ',
                  style: pw.TextStyle(fontSize: 12, font: _regularFont),
                ),
                pw.Expanded(
                  child: pw.Text(
                    line.trim(),
                    style: pw.TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      font: _regularFont,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        currentPageContent.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              line.trim(),
              style: pw.TextStyle(
                fontSize: 12,
                height: 1.5,
                font: _regularFont,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        );
      }
    }

    return currentPageContent;
  }

  // 💾 Сохранение и открытие PDF
  Future<void> _saveAndSharePdf(pw.Document pdf, String title) async {
    try {
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // ДЛЯ ВЕБА
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '${_sanitizeFileName(title)}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        print('✅ PDF downloaded successfully on web');
      } else {
        // ДЛЯ МОБИЛЬНЫХ
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${_sanitizeFileName(title)}_$timestamp.pdf';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Нормативный акт: $title',
          text: 'Официальная копия нормативного акта из AdiletZan.kz',
        );
      }
    } catch (e) {
      print('Error saving/sharing PDF: $e');
      rethrow;
    }
  }

  // 🧹 Очистка имени файла
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9а-яА-ЯёЁ]'), '_');
  }
}
