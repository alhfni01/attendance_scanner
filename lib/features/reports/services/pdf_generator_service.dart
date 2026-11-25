import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfGeneratorService {
  static Future<void> generateAndShareReport({
    required List records,
    required String dateStr,
  }) async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansArabic-Regular.ttf',
    );
    final arabicFont = pw.Font.ttf(fontData);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont),
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              'كشف حضور التدريب الميداني',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'التاريخ: $dateStr',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: arabicFont, fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'عدد الحضور: ${records.length}',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey400,
              width: 0.5,
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                children: [
                  _headerCell('#', arabicFont, rtl: false),
                  _headerCell('الاسم الكامل', arabicFont),
                  _headerCell('الرقم الجامعي', arabicFont),
                  _headerCell('التاريخ', arabicFont),
                  _headerCell('وقت المسح', arabicFont),
                ],
              ),
              ...List.generate(records.length, (index) {
                final record = records[index];

                return pw.TableRow(
                  children: [
                    _cell('${index + 1}', arabicFont, rtl: false),
                    _cell(record.fullName.toString(), arabicFont),
                    _cell(
                      record.universityId.toString(),
                      arabicFont,
                      rtl: false,
                    ),
                    _cell(
                      record.attendanceDate.toString(),
                      arabicFont,
                      rtl: false,
                    ),
                    _cell(
                      record.attendanceTime.toString(),
                      arabicFont,
                      rtl: false,
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تم إنشاء الكشف بواسطة تطبيق المسح',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'توقيع الدكتور المسؤول: __________________',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final safeDate = dateStr.replaceAll('/', '-');
    final fileName = 'Attendance_Report_$safeDate.pdf';
    final pdfBytes = await pdf.save();

    await SharePlus.instance.share(
      ShareParams(
        title: 'كشف حضور',
        text: 'كشف حضور يوم $dateStr - عدد الحضور: ${records.length}',
        files: [
          XFile.fromData(
            pdfBytes,
            mimeType: 'application/pdf',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        downloadFallbackEnabled: true,
      ),
    );
  }

  static pw.Widget _headerCell(
      String text,
      pw.Font font, {
        bool rtl = true,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _cell(
      String text,
      pw.Font font, {
        bool rtl = true,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
        ),
      ),
    );
  }
}