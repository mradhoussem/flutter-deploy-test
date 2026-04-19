import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PdfPackage {
  static Future<void> generateAndPrint(PackageModel package) async {
    final bytes = await _buildBytes(package);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'colis_${package.id}.pdf');
  }

  static Future<void> saveAndPrint(PackageModel package) async {
    final bytes = await _buildBytes(package);
    _downloadOnWeb(bytes, 'colis_${package.id}.pdf');
  }

  static Future<Uint8List> _buildBytes(PackageModel package) async {
    final ttfRegular = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final ByteData logoData = await rootBundle.load(ImagesFiles.logo);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final pdf = pw.Document(title: 'colis_${package.id}');

    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 7);
    final labelStyle = pw.TextStyle(font: ttfBold, fontSize: 4);
    final valueStyle = pw.TextStyle(font: ttfRegular, fontSize: 4);

    pw.TableRow buildRow(String label, String value) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4), child: pw.Text(label, style: labelStyle)),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4), child: pw.Text(value, style: valueStyle, softWrap: true)),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        header: (context) => pw.Column(children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Express Colis", style: titleStyle),
              pw.Image(logoImage, width: 60),
            ],
          ),
          pw.Divider(thickness: 0.5),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(thickness: 0.5),
          pw.Center(child: pw.Text("contact@express-colis.com", style: const pw.TextStyle(fontSize: 5))),
        ]),
        build: (pw.Context context) => [
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Column(
              children: [
                pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: package.id, width: 90, height: 90, drawText: false),
                pw.SizedBox(height: 4),
                pw.Text("ID: ${package.id}", style: pw.TextStyle(font: ttfBold, fontSize: 5)),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(3)},
            children: [
              buildRow("Prénom", package.firstName),
              buildRow("Nom", package.lastName),
              buildRow("Téléphone 1", package.phone1),
              if (package.phone2 != null && package.phone2!.isNotEmpty) buildRow("Téléphone 2", package.phone2!),
              buildRow("Gouvernorat", package.governorate.name),
              buildRow("Adresse", package.address),
              buildRow("Montant", "${package.amount.toStringAsFixed(3)} TND"),
              buildRow("Échange", package.isExchange ? "Oui" : "Non"),
              if (package.isExchange && package.packageDesignation != null) buildRow("Désignation", package.packageDesignation!),
              if (package.comment != null) buildRow("Commentaire", package.comment!),
              buildRow("Créé par", package.creatorUsername),
              buildRow("Créé le", "${package.createdAt.day.toString().padLeft(2, '0')}/${package.createdAt.month.toString().padLeft(2, '0')}/${package.createdAt.year}"),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static void _downloadOnWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute('download', filename)..click();
    html.Url.revokeObjectUrl(url);
  }
}