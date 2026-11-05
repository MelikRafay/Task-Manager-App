import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../utils/csv_builder.dart';
import '../utils/file_ops.dart';

class ExportService {
  static String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static Future<void> exportCsv(List<Task> tasks) async {
    // BOM so Excel opens UTF-8 correctly.
    final bytes = Uint8List.fromList(utf8.encode('﻿${buildCsv(tasks)}'));
    await saveBytes('tasks_${_stamp()}.csv', bytes, 'text/csv');
  }

  static Future<Uint8List> buildPdf(List<Task> tasks) async {
    final doc = pw.Document(title: 'My Tasks');
    final fmt = DateFormat('d MMM yyyy, h:mm a');

    pw.Widget cell(String text, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text('Task report',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (_) => [
          pw.Text(
              'Generated ${fmt.format(DateTime.now())}  -  ${tasks.length} task(s)',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(1.1),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  cell('Title / details', bold: true),
                  cell('Category', bold: true),
                  cell('Due', bold: true),
                  cell('Status', bold: true),
                  cell('Repeat', bold: true),
                  cell('Progress', bold: true),
                ],
              ),
              for (final t in tasks)
                pw.TableRow(
                  children: [
                    cell([
                      t.title,
                      if (t.description.isNotEmpty) t.description,
                      for (final s in t.subtasks)
                        '  [${s.done ? 'x' : ' '}] ${s.title}',
                    ].join('\n')),
                    cell(t.category),
                    cell(fmt.format(t.dueDate)),
                    cell(t.isCompleted ? 'Completed' : 'Pending'),
                    cell(t.repeatLabel),
                    cell('${(t.progress * 100).round()}%'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> exportPdf(List<Task> tasks) async {
    final bytes = await buildPdf(tasks);
    await Printing.sharePdf(bytes: bytes, filename: 'tasks_${_stamp()}.pdf');
  }

  /// Opens the default mail app with the task list as the message body.
  /// Returns false if no mail app could be opened.
  static Future<bool> sendEmail(List<Task> tasks, {String to = ''}) async {
    final subject = Uri.encodeComponent('My task list');
    final body = Uri.encodeComponent(buildPlainText(tasks));
    final uri = Uri.parse('mailto:$to?subject=$subject&body=$body');
    return launchUrl(uri);
  }
}
