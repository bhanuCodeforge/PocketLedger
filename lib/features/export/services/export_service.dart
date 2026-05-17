import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Service responsible for exporting transaction/budget data to CSV, Excel,
/// and PDF formats, then optionally sharing them via the system share sheet.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── CSV ─────────────────────────────────────────────────────────────────────

  /// Converts [data] rows into a CSV file saved in the system temp directory.
  ///
  /// [data] must be a list of row maps; keys are used as column headers.
  /// Returns the absolute path to the saved file.
  Future<String> exportToCsv(
    List<Map<String, dynamic>> data,
    String filename,
  ) async {
    if (data.isEmpty) {
      throw ArgumentError('Cannot export empty data set.');
    }

    final headers = data.first.keys.toList();
    final rows = <List<dynamic>>[
      headers,
      ...data.map((row) => headers.map((h) => row[h] ?? '').toList()),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final path = await _tempPath('$filename.csv');
    await File(path).writeAsString(csv);
    return path;
  }

  // ── Excel ───────────────────────────────────────────────────────────────────

  /// Converts [data] rows into an XLSX file saved in the system temp directory.
  ///
  /// Returns the absolute path to the saved file.
  Future<String> exportToExcel(
    List<Map<String, dynamic>> data,
    String filename,
  ) async {
    if (data.isEmpty) {
      throw ArgumentError('Cannot export empty data set.');
    }

    final excel = Excel.createExcel();
    // Default sheet is created as 'Sheet1'
    final sheetName = filename.length > 31 ? filename.substring(0, 31) : filename;
    final sheet = excel[sheetName];

    // Remove the auto-created default sheet if it differs from our name
    if (excel.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    final headers = data.first.keys.toList();

    // Header row — styled
    final headerBg = ExcelColor.fromHexString('#2563EB');
    final headerFg = ExcelColor.fromHexString('#FFFFFF');
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: headerBg,
        fontColorHex: headerFg,
      );
    }

    // Data rows
    for (var rowIdx = 0; rowIdx < data.length; rowIdx++) {
      final row = data[rowIdx];
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx + 1),
        );
        final value = row[headers[col]];
        cell.value = _toCellValue(value);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) throw StateError('Excel encoding returned null.');

    final path = await _tempPath('$filename.xlsx');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  CellValue _toCellValue(dynamic value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value.toString());
  }

  // ── PDF ─────────────────────────────────────────────────────────────────────

  /// Generates a formatted PDF document from [data] rows.
  ///
  /// [title] appears as the document heading.
  /// [headers] defines the column order; keys must match [data] map keys.
  /// Returns the absolute path to the saved file.
  Future<String> exportToPdf({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    required String filename,
  }) async {
    final doc = pw.Document(
      title: title,
      author: 'PocketLedger',
      creator: 'PocketLedger',
    );

    // pdf package uses double RGB values 0.0–1.0
    const primaryColor = PdfColor(0.145, 0.388, 0.922); // #2563EB
    const mutedColor = PdfColor(0.580, 0.639, 0.722);   // #94A3B8
    const borderColor = PdfColor(0.796, 0.835, 0.882);  // #CBD5E1
    const rowEvenColor = PdfColor(0.945, 0.961, 0.973); // #F1F5F9

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildPdfHeader(title, primaryColor, mutedColor),
        footer: (context) => _buildPdfFooter(context, mutedColor),
        build: (context) {
          return [
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                color: borderColor,
                width: 0.5,
              ),
              columnWidths: _computeColumnWidths(headers),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryColor),
                  children: headers
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Data rows
                ...data.asMap().entries.map((entry) {
                  final isEven = entry.key.isEven;
                  final row = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? rowEvenColor : PdfColors.white,
                    ),
                    children: headers
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: pw.Text(
                              (row[h] ?? '').toString(),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();
    final path = await _tempPath('$filename.pdf');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  pw.Widget _buildPdfHeader(
    String title,
    PdfColor primaryColor,
    PdfColor mutedColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.Text(
              'PocketLedger',
              style: pw.TextStyle(fontSize: 10, color: mutedColor),
            ),
          ],
        ),
        pw.Divider(color: primaryColor, thickness: 1),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context, PdfColor mutedColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by PocketLedger',
          style: pw.TextStyle(fontSize: 8, color: mutedColor),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: mutedColor),
        ),
      ],
    );
  }

  Map<int, pw.TableColumnWidth> _computeColumnWidths(List<String> headers) {
    final width = pw.FlexColumnWidth();
    return {for (var i = 0; i < headers.length; i++) i: width};
  }

  // ── Share ───────────────────────────────────────────────────────────────────

  /// Shares a file at [filePath] via the platform share sheet.
  Future<void> shareFile(String filePath) async {
    final file = XFile(filePath);
    await SharePlus.instance.shareXFiles([file]);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<String> _tempPath(String filename) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$filename';
  }
}
