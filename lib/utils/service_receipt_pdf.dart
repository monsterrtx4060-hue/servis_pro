import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ServiceReceiptPdf {
  // Firma bilgileri (burayı kendi işletme bilgilerine göre düzenleyebilirsin)
  static const String companyName = 'Bilgin Teknik Servis';
  static const String companyPhone = '0534 931 42 88';
  static const String companyAddress = 'BURSA / Orhangazi';

  static Future<Uint8List> _buildPdf(Map<String, dynamic> service) async {
    final pdf = pw.Document();

    String val(dynamic v) => (v ?? '').toString();

    final customerName = val(service['name']);
    final phone = val(service['phone']);
    final address = val(service['address']);
    final reminderNote = val(service['reminder_note']);

    final product = val(service['product']);
    final problem = val(service['problem']);
    final plannedDate = val(
      service['planned_date_ui'] ?? service['planned_date'],
    );
    final createdDate = val(
      service['created_date_ui'] ?? service['created_date'],
    );
    final doneDescription = val(service['done_description']);
    final price = val(service['price']);

    final serviceId = val(service['id']);
    final receiptNo =
        'SF-${DateTime.now().year}-$serviceId-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Üst başlık
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Center(child: pw.Text(companyPhone)),
                    pw.Center(child: pw.Text(companyAddress)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'SERVİS FİŞİ',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text('Fiş No: $receiptNo'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Müşteri bilgileri
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Müşteri Bilgileri',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Ad Soyad: $customerName'),
                    pw.Text('Telefon: $phone'),
                    pw.Text('Adres: $address'),
                    if (reminderNote.isNotEmpty)
                      pw.Text('Hatırlatma Notu: $reminderNote'),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Servis bilgileri
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Servis Bilgileri',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Ürün: $product'),
                    pw.Text('Arıza: $problem'),
                    pw.Text('Planlanan Servis Tarihi: $plannedDate'),
                    pw.Text('Kayıt Tarihi: $createdDate'),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Yapılan işlem
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Yapılan İşlem',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      doneDescription.isEmpty
                          ? 'Henüz işlem girilmedi'
                          : doneDescription,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Ücret
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOPLAM ÜCRET',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      '$price ₺',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // İmzalar
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Müşteri İmza: __________________'),
                  pw.Text('Servis İmza: __________________'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printServiceReceipt(Map<String, dynamic> service) async {
    final bytes = await _buildPdf(service);

    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  static Future<void> shareServiceReceipt(Map<String, dynamic> service) async {
    final bytes = await _buildPdf(service);

    final fileName = 'servis_fisi_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
