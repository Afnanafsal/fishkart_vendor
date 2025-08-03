import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PDFInvoiceGenerator {
  static Future<void> generateAndDownloadInvoice({
    required Map<String, dynamic> order,
    required Map<String, dynamic>? product,
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? address,
    required String docRefId,
    required String userName,
  }) async {
    try {
      await _requestStoragePermission();
      final pdf = pw.Document();
      // Load a font that supports the rupee symbol (e.g., Poppins)
      final fontData = await rootBundle.load(
        'assets/fonts/poppins/Poppins-Regular.ttf',
      );
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            // Prepare product list (single or multiple)
            List<Map<String, dynamic>> products = [];
            if (order['items'] != null && order['items'] is List) {
              // Multi-product order
              products = List<Map<String, dynamic>>.from(order['items']).map((
                item,
              ) {
                var priceRaw =
                    item['price'] ??
                    item['unit_price'] ??
                    item['discount_price'] ??
                    item['original_price'] ??
                    product?['discount_price'] ??
                    product?['original_price'] ??
                    product?['price'] ??
                    order['price'] ??
                    0;
                double price;
                if (priceRaw is num) {
                  price = priceRaw.toDouble();
                } else if (priceRaw is String) {
                  price = double.tryParse(priceRaw) ?? 0;
                } else {
                  price = 0;
                }
                return {
                  ...item,
                  'price': price,
                  'title': item['title'] ?? product?['title'] ?? 'Product',
                  'quantity': item['quantity'] ?? order['quantity'] ?? 1,
                };
              }).toList();
            } else if (product != null) {
              // Single product order
              var priceRaw =
                  (product['discount_price'] != null &&
                      product['discount_price'] != 0)
                  ? product['discount_price']
                  : (product['original_price'] != null &&
                        product['original_price'] != 0)
                  ? product['original_price']
                  : (product['price'] != null && product['price'] != 0)
                  ? product['price']
                  : (order['price'] ?? 0);
              double price;
              if (priceRaw is num) {
                price = priceRaw.toDouble();
              } else if (priceRaw is String) {
                price = double.tryParse(priceRaw) ?? 0;
              } else {
                price = 0;
              }
              products = [
                {
                  'title': product['title'] ?? 'Product',
                  'price': price,
                  'quantity': order['quantity'] ?? 1,
                },
              ];
            }
            double total = 0;
            for (var p in products) {
              // Fix price fetching for both string and num, and fallback to 0
              double price = 0;
              if (p['price'] is num) {
                price = (p['price'] as num).toDouble();
              } else if (p['price'] != null) {
                price = double.tryParse(p['price'].toString()) ?? 0;
              }
              double qty = 1;
              if (p['quantity'] is num) {
                qty = (p['quantity'] as num).toDouble();
              } else if (p['quantity'] != null) {
                qty = double.tryParse(p['quantity'].toString()) ?? 1;
              }
              total += price * qty;
            }
            return pw.Container(
              color: PdfColor.fromInt(0xFFF5F5F5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: <pw.Widget>[
                  // Modern Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 28,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF222222),
                      borderRadius: const pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(32),
                        bottomRight: pw.Radius.circular(32),
                      ),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromInt(0x22000000),
                          blurRadius: 12,
                          offset: PdfPoint(0, 4),
                        ),
                      ],
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'FishKart',
                              style: pw.TextStyle(
                                fontSize: 32,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFFFFFFFF),
                                letterSpacing: 1.5,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Premium Seafood Solutions',
                              style: pw.TextStyle(
                                fontSize: 13,
                                color: PdfColor.fromInt(0xFFCCCCCC),
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFFFFFFF),
                            borderRadius: pw.BorderRadius.circular(20),
                            boxShadow: [
                              pw.BoxShadow(
                                color: PdfColor.fromInt(0x11000000),
                                blurRadius: 6,
                                offset: PdfPoint(0, 2),
                              ),
                            ],
                          ),
                          child: pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF222222),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  // Order & Customer Info
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Order ID:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFF222222),
                              ),
                            ),
                            pw.Text(
                              docRefId,
                              style: pw.TextStyle(fontSize: 12),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Date:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFF222222),
                              ),
                            ),
                            pw.Text(
                              '${order['order_date'] ?? DateTime.now().toString().substring(0, 16)}',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Status:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFF222222),
                              ),
                            ),
                            pw.Text(
                              '${order['status'] ?? 'Processing'}',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Customer:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFF222222),
                              ),
                            ),
                            pw.Text(
                              _getCustomerName(user, userName),
                              style: pw.TextStyle(fontSize: 12),
                            ),
                            if (address != null &&
                                (address['address_line']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false))
                              pw.Text(
                                address['address_line'],
                                style: pw.TextStyle(fontSize: 12),
                              ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Payment:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFF222222),
                              ),
                            ),
                            pw.Text(
                              '${order['payment'] ?? ''}',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  // Product Table
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32),
                    child: pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColor.fromInt(0xFFE0E0E0),
                        width: 1,
                      ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(4),
                        1: const pw.FlexColumnWidth(2),
                        2: const pw.FlexColumnWidth(2),
                        3: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFF0F0F0),
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Product',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Qty',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Unit Price',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Total',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...products.map((p) {
                          double price = 0;
                          if (p['price'] is num) {
                            price = (p['price'] as num).toDouble();
                          } else if (p['price'] != null) {
                            price = double.tryParse(p['price'].toString()) ?? 0;
                          }
                          double qty = 1;
                          if (p['quantity'] is num) {
                            qty = (p['quantity'] as num).toDouble();
                          } else if (p['quantity'] != null) {
                            qty =
                                double.tryParse(p['quantity'].toString()) ?? 1;
                          }
                          return pw.TableRow(
                            children: <pw.Widget>[
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  p['title']?.toString() ?? '-',
                                  style: pw.TextStyle(fontSize: 12, font: ttf),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  qty.toStringAsFixed(0),
                                  style: pw.TextStyle(fontSize: 12, font: ttf),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '₹${price.toStringAsFixed(2)}',
                                  style: pw.TextStyle(fontSize: 12, font: ttf),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '₹${(price * qty).toStringAsFixed(2)}',
                                  style: pw.TextStyle(fontSize: 12, font: ttf),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  // Grand Total
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFF222222),
                            borderRadius: pw.BorderRadius.circular(16),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'GRAND TOTAL',
                                style: pw.TextStyle(
                                  fontSize: 15,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFFFFFFFF),
                                  letterSpacing: 1,
                                  font: ttf,
                                ),
                              ),
                              pw.SizedBox(width: 18),
                              pw.Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFFF9AC07),
                                  font: ttf,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  // Footer
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFEFEFEF),
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(24),
                        topRight: pw.Radius.circular(24),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for your order!',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF222222),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Fresh Seafood • Premium Quality • Reliable Service',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF757575),
                            fontStyle: pw.FontStyle.italic,
                            font: ttf,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'Invoice generated on ${DateTime.now().toString().substring(0, 16)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromInt(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await _savePDF(pdf, docRefId);
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
  }

  static Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  static Future<void> _savePDF(pw.Document pdf, String orderId) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }
      if (directory != null) {
        final fileName =
            'FishKart_Invoice_${orderId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        debugPrint('PDF saved to: ${file.path}');
        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
    }
  }

  static String _getCustomerName(Map<String, dynamic>? user, String userName) {
    if (user != null) {
      final displayName = user['display_name']?.toString();
      final name = user['name']?.toString();
      if (displayName?.isNotEmpty == true) return displayName!;
      if (name?.isNotEmpty == true) return name!;
    }
    return userName != 'Customer' ? userName : 'Valued Customer';
  }

  // _calculateTotal removed (no longer used)
}
