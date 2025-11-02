import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // 📄 Создание PDF документа с водяным знаком и защитой
  Future<void> generateProtectedPdf({
    required String title,
    required String content,
    required String subtitle,
    required String actNumber,
    required String date,
    required String category,
  }) async {
    try {
      final pdf = pw.Document(
        title: title,
        subject: 'Нормативный акт РК',
        author: 'AdiletZan.kz',
        creator: 'AdiletZan.kz Official App',
      );

      // Создаем водяной знак
      final watermarkText = _createWatermarkWidget();

      // Добавляем страницы
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            // Титульная страница
            _buildTitlePage(
              title: title,
              subtitle: subtitle,
              actNumber: actNumber,
              date: date,
              category: category,
              watermark: watermarkText,
            ),
            // Содержание
            ..._buildContentPages(content, watermarkText),
          ],
        ),
      );

      // Сохраняем и открываем файл
      await _saveAndSharePdf(pdf, title);

    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  // 🎨 Создание виджета водяного знака
  pw.Widget _createWatermarkWidget() {
    return pw.Stack(
      children: [
        pw.Transform.rotate(
          angle: -0.5,
          child: pw.Opacity(
            opacity: 0.03,
            child: pw.Text(
              'AdiletZan.kz\nОфициальная копия',
              style: pw.TextStyle(
                fontSize: 60,
                color: PdfColors.blue800,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // 📄 Титульная страница
  pw.Widget _buildTitlePage({
    required String title,
    required String subtitle,
    required String actNumber,
    required String date,
    required String category,
    required pw.Widget watermark,
  }) {
    return pw.Stack(
      children: [
        // Водяной знак на заднем плане
        watermark,

        // Основной контент
        pw.Column(
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
                    fontWeight: pw.FontWeight.bold,
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
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Заголовок
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 15),

            // Подзаголовок
            if (subtitle.isNotEmpty)
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
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
                border: pw.Border.all(
                  color: PdfColors.grey300,
                  width: 1,
                ),
              ),
              child: pw.Column(
                children: [
                  _buildInfoRow('Номер документа:', actNumber),
                  _buildInfoRow('Дата принятия:', date),
                  _buildInfoRow('Статус:', 'Действующий'),
                  _buildInfoRow('Источник:', 'AdiletZan.kz'),
                  _buildInfoRow('Дата генерации:',
                      '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}'),
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
                border: pw.Border.all(
                  color: PdfColors.red200,
                  width: 1,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(
                    pw.IconData(0xe16d), // Замок иконка
                    size: 16,
                    color: PdfColors.red600,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      'ОФИЦИАЛЬНАЯ КОПИЯ. КОПИРОВАНИЕ И РАСПРОСТРАНЕНИЕ ЗАПРЕЩЕНО.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.red600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📄 Страницы с содержанием
  List<pw.Widget> _buildContentPages(String content, pw.Widget watermark) {
    final lines = content.split('\n');
    final contentPages = <pw.Widget>[];
    final currentPageContent = <pw.Widget>[];

    // Добавляем водяной знак на каждую страницу
    for (final line in lines) {
      if (line.trim().isEmpty) {
        currentPageContent.add(pw.SizedBox(height: 12));
      } else if (line.trim().startsWith('РАЗДЕЛ') ||
          line.trim().startsWith('Глава') ||
          line.trim().startsWith('Статья')) {
        // Заголовки разделов
        currentPageContent.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15, top: 10),
            child: pw.Text(
              line.trim(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
        );
      } else if (line.trim().startsWith(RegExp(r'^[0-9]+\..*'))) {
        // Нумерованные пункты
        currentPageContent.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8, left: 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Expanded(
                  child: pw.Text(
                    line.trim(),
                    style: const pw.TextStyle(
                      fontSize: 12,
                      height: 1.5,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Обычный текст
        currentPageContent.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              line.trim(),
              style: const pw.TextStyle(
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        );
      }
    }

    contentPages.add(
      pw.Stack(
        children: [
          watermark,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: currentPageContent,
          ),
        ],
      ),
    );

    return contentPages;
  }

  // 💾 Сохранение и открытие PDF
  Future<void> _saveAndSharePdf(pw.Document pdf, String title) async {
    try {
      // Получаем директорию для временных файлов
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_sanitizeFileName(title)}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      // Сохраняем PDF файл
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Делимся файлом
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Нормативный акт: $title',
        text: 'Официальная копия нормативного акта из AdiletZan.kz',
      );

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