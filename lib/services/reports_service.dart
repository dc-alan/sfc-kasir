import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../models/app_settings.dart';
import '../services/bluetooth_printer_service.dart';

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  final BluetoothPrinterService _printerService = BluetoothPrinterService();

  /// Generate PDF report for transactions
  Future<File> generateTransactionsPDF({
    required List<model.Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.total);
    final totalTransactions = transactions.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    settings.businessName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Laporan Penjualan per Transaksi',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Transaksi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('$totalTransactions'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Pendapatan',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(_formatCurrency(totalRevenue)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Rata-rata per Transaksi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _formatCurrency(
                          totalTransactions > 0
                              ? totalRevenue / totalTransactions
                              : 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Transactions table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('No. Transaksi', isHeader: true),
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Kasir', isHeader: true),
                    _buildTableCell('Metode Bayar', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                  ],
                ),
                // Data rows
                ...transactions.map(
                  (transaction) => pw.TableRow(
                    children: [
                      _buildTableCell(
                        transaction.id.substring(0, 8).toUpperCase(),
                      ),
                      _buildTableCell(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(transaction.createdAt),
                      ),
                      _buildTableCell(transaction.cashierId),
                      _buildTableCell(
                        _getPaymentMethodText(transaction.paymentMethod),
                      ),
                      _buildTableCell(_formatCurrency(transaction.total)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/laporan_transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate PDF report for products
  Future<File> generateProductsPDF({
    required List<model.Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();

    // Calculate product sales
    final Map<String, Map<String, dynamic>> productSales = {};

    for (var transaction in transactions) {
      for (var item in transaction.items) {
        final productName = item.product.name;
        if (productSales.containsKey(productName)) {
          productSales[productName]!['quantity'] += item.quantity;
          productSales[productName]!['total'] += item.totalPrice;
        } else {
          productSales[productName] = {
            'quantity': item.quantity,
            'price': item.unitPrice,
            'total': item.totalPrice,
          };
        }
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

    final totalQuantity = productSales.values.fold(
      0,
      (sum, p) => sum + (p['quantity'] as int),
    );
    final totalRevenue = productSales.values.fold(
      0.0,
      (sum, p) => sum + (p['total'] as double),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    settings.businessName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Laporan Penjualan per Produk',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Produk',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('${productSales.length}'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Qty Terjual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('$totalQuantity'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Pendapatan',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(_formatCurrency(totalRevenue)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Products table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Nama Produk', isHeader: true),
                    _buildTableCell('Qty', isHeader: true),
                    _buildTableCell('Harga Satuan', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                  ],
                ),
                // Data rows
                ...sortedProducts.map(
                  (entry) => pw.TableRow(
                    children: [
                      _buildTableCell(entry.key),
                      _buildTableCell('${entry.value['quantity']}'),
                      _buildTableCell(_formatCurrency(entry.value['price'])),
                      _buildTableCell(_formatCurrency(entry.value['total'])),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/laporan_produk_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate Excel report for transactions
  Future<File> generateTransactionsExcel({
    required List<model.Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required AppSettings settings,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Transaksi'];

    // Header
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      settings.businessName,
    );
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Laporan Penjualan per Transaksi',
    );
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
    );
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
    );

    // Table headers
    final headers = [
      'No. Transaksi',
      'Tanggal',
      'Kasir',
      'Pelanggan',
      'Metode Bayar',
      'Subtotal',
      'Diskon',
      'Pajak',
      'Total',
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Data rows
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final row = i + 7;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        transaction.id.substring(0, 8).toUpperCase(),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(
        DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        transaction.cashierId,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        transaction.customer?.name ?? '-',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(
        _getPaymentMethodText(transaction.paymentMethod),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = DoubleCellValue(
        transaction.subtotal,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = DoubleCellValue(
        transaction.discount,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = DoubleCellValue(
        transaction.tax,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = DoubleCellValue(
        transaction.total,
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/laporan_transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  /// Generate Excel report for products
  Future<File> generateProductsExcel({
    required List<model.Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required AppSettings settings,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Produk'];

    // Calculate product sales
    final Map<String, Map<String, dynamic>> productSales = {};

    for (var transaction in transactions) {
      for (var item in transaction.items) {
        final productName = item.product.name;
        if (productSales.containsKey(productName)) {
          productSales[productName]!['quantity'] += item.quantity;
          productSales[productName]!['total'] += item.totalPrice;
        } else {
          productSales[productName] = {
            'quantity': item.quantity,
            'price': item.unitPrice,
            'total': item.totalPrice,
          };
        }
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

    // Header
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      settings.businessName,
    );
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Laporan Penjualan per Produk',
    );
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
    );
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
    );

    // Table headers
    final headers = [
      'Nama Produk',
      'Qty Terjual',
      'Harga Satuan',
      'Total Pendapatan',
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Data rows
    for (int i = 0; i < sortedProducts.length; i++) {
      final entry = sortedProducts[i];
      final row = i + 7;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        entry.key,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = IntCellValue(
        entry.value['quantity'],
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = DoubleCellValue(
        entry.value['price'],
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = DoubleCellValue(
        entry.value['total'],
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/laporan_produk_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  /// Print transactions report to thermal printer
  Future<bool> printTransactionsReport({
    required List<model.Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required AppSettings settings,
  }) async {
    if (!_printerService.isConnected) {
      debugPrint('Printer not connected');
      return false;
    }

    try {
      // Create a dummy transaction to use the existing print infrastructure
      final dummyTransaction = model.Transaction(
        id: 'REPORT-${DateTime.now().millisecondsSinceEpoch}',
        items: [],
        subtotal: 0,
        discount: 0,
        tax: 0,
        total: 0,
        amountPaid: 0,
        change: 0,
        paymentMethod: model.PaymentMethod.cash,
        createdAt: DateTime.now(),
        cashierId: 'SYSTEM',
      );

      // Use the existing printReceipt method but with custom data
      return await _printCustomData(
        _generateTransactionsReportData(
          transactions,
          startDate,
          endDate,
          settings,
        ),
      );
    } catch (e) {
      debugPrint('Error printing transactions report: $e');
      return false;
    }
  }

  /// Print products report to thermal printer
  Future<bool> printProductsReport({
    required List<model.Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required AppSettings settings,
  }) async {
    if (!_printerService.isConnected) {
      debugPrint('Printer not connected');
      return false;
    }

    try {
      // Use the existing printReceipt method but with custom data
      return await _printCustomData(
        _generateProductsReportData(transactions, startDate, endDate, settings),
      );
    } catch (e) {
      debugPrint('Error printing products report: $e');
      return false;
    }
  }

  /// Helper method to print custom data using the printer service
  Future<bool> _printCustomData(Uint8List data) async {
    try {
      // Use the existing printRawData method from BluetoothPrinterService
      if (!_printerService.isConnected) {
        debugPrint('Printer not connected');
        return false;
      }

      debugPrint('Sending ${data.length} bytes to thermal printer');

      // Use the actual printRawData method from BluetoothPrinterService
      return await _printerService.printRawData(data);
    } catch (e) {
      debugPrint('Error in custom print: $e');
      return false;
    }
  }

  /// Generate thermal printer data for transactions report
  Uint8List _generateTransactionsReportData(
    List<model.Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
    AppSettings settings,
  ) {
    final List<int> bytes = [];
    const esc = 0x1B;
    const gs = 0x1D;

    // Initialize printer
    bytes.addAll([esc, 0x40]); // Initialize
    bytes.addAll([esc, 0x61, 0x01]); // Center alignment

    // Header
    bytes.addAll([esc, 0x21, 0x30]); // Double height and width
    bytes.addAll('LAPORAN TRANSAKSI'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    bytes.addAll([esc, 0x21, 0x20]); // Double height
    bytes.addAll(settings.businessName.toUpperCase().codeUnits);
    bytes.addAll([0x0A]);

    bytes.addAll([esc, 0x21, 0x00]); // Normal size
    final periodText =
        'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
    bytes.addAll(periodText.codeUnits);
    bytes.addAll([0x0A]);

    final printTime =
        'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
    bytes.addAll(printTime.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    // Summary
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('RINGKASAN'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([0x0A]);

    final totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.total);
    final totalTransactions = transactions.length;

    bytes.addAll('Total Transaksi: $totalTransactions'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll(
      'Total Pendapatan: ${_formatCurrency(totalRevenue)}'.codeUnits,
    );
    bytes.addAll([0x0A]);
    if (totalTransactions > 0) {
      bytes.addAll(
        'Rata-rata: ${_formatCurrency(totalRevenue / totalTransactions)}'
            .codeUnits,
      );
      bytes.addAll([0x0A]);
    }
    bytes.addAll([0x0A]);

    // Transactions list
    bytes.addAll('DETAIL TRANSAKSI'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('--------------------------------'.codeUnits);
    bytes.addAll([0x0A]);

    for (var transaction in transactions) {
      bytes.addAll(
        'ID: ${transaction.id.substring(0, 8).toUpperCase()}'.codeUnits,
      );
      bytes.addAll([0x0A]);
      bytes.addAll(
        DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt).codeUnits,
      );
      bytes.addAll([0x0A]);
      bytes.addAll('Kasir: ${transaction.cashierId}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('Total: ${_formatCurrency(transaction.total)}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([0x0A]);
    }

    // Footer
    // bytes.addAll([0x0A, 0x0A]);
    bytes.addAll([gs, 0x56, 0x42, 0x00]); // Partial cut

    return Uint8List.fromList(bytes);
  }

  /// Generate thermal printer data for products report
  Uint8List _generateProductsReportData(
    List<model.Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
    AppSettings settings,
  ) {
    final List<int> bytes = [];
    const esc = 0x1B;
    const gs = 0x1D;

    // Calculate product sales
    final Map<String, Map<String, dynamic>> productSales = {};

    for (var transaction in transactions) {
      for (var item in transaction.items) {
        final productName = item.product.name;
        if (productSales.containsKey(productName)) {
          productSales[productName]!['quantity'] += item.quantity;
          productSales[productName]!['total'] += item.totalPrice;
        } else {
          productSales[productName] = {
            'quantity': item.quantity,
            'price': item.unitPrice,
            'total': item.totalPrice,
          };
        }
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

    // Initialize printer
    bytes.addAll([esc, 0x40]); // Initialize
    bytes.addAll([esc, 0x61, 0x01]); // Center alignment

    // Header
    bytes.addAll([esc, 0x21, 0x30]); // Double height and width
    bytes.addAll('LAPORAN PRODUK'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    bytes.addAll([esc, 0x21, 0x20]); // Double height
    bytes.addAll(settings.businessName.toUpperCase().codeUnits);
    bytes.addAll([0x0A]);

    bytes.addAll([esc, 0x21, 0x00]); // Normal size
    final periodText =
        'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
    bytes.addAll(periodText.codeUnits);
    bytes.addAll([0x0A]);

    final printTime =
        'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
    bytes.addAll(printTime.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    // Summary
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('RINGKASAN'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([0x0A]);

    final totalQuantity = productSales.values.fold(
      0,
      (sum, p) => sum + (p['quantity'] as int),
    );
    final totalRevenue = productSales.values.fold(
      0.0,
      (sum, p) => sum + (p['total'] as double),
    );

    bytes.addAll('Total Produk: ${productSales.length}'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('Total Qty: $totalQuantity'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll(
      'Total Pendapatan: ${_formatCurrency(totalRevenue)}'.codeUnits,
    );
    bytes.addAll([0x0A, 0x0A]);

    // Products list
    bytes.addAll('DETAIL PRODUK'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('--------------------------------'.codeUnits);
    bytes.addAll([0x0A]);

    for (var entry in sortedProducts) {
      bytes.addAll(entry.key.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('Qty: ${entry.value['quantity']}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('Harga: ${_formatCurrency(entry.value['price'])}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('Total: ${_formatCurrency(entry.value['total'])}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([0x0A]);
    }

    // Footer
    bytes.addAll([0x0A, 0x0A]);
    bytes.addAll([gs, 0x56, 0x42, 0x00]); // Partial cut

    return Uint8List.fromList(bytes);
  }

  // Helper methods
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _getPaymentMethodText(model.PaymentMethod method) {
    switch (method) {
      case model.PaymentMethod.cash:
        return 'Tunai';
      case model.PaymentMethod.card:
        return 'Kartu';
      case model.PaymentMethod.digital:
        return 'Digital';
      case model.PaymentMethod.mixed:
        return 'Campuran';
    }
  }
}
