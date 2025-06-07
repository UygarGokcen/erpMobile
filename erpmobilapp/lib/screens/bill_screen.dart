import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/order.dart';
import 'package:erpmobilapp/services/inventory_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class BillScreen extends StatelessWidget {
  final Order order;
  final Function onComplete;

  BillScreen({
    required this.order,
    required this.onComplete,
  });

  Future<void> _generateAndOpenPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Create PDF content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company Header
                pw.Header(
                  level: 0,
                  child: pw.Text('Founder ERP', style: pw.TextStyle(fontSize: 24)),
                ),
                pw.SizedBox(height: 20),

                // Company Information
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Company Information'),
                      pw.Text('Date: ${DateTime.now().toString().split('.')[0]}'),
                      pw.Text('Order ID: #${order.id}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Customer Information
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer Information'),
                      pw.Text('Name: ${order.customer.name}'),
                      if (order.customer.extraFields['Ülke'] != null)
                        pw.Text('Country: ${order.customer.extraFields['Ülke']}'),
                      if (order.customer.extraFields['Şehir'] != null)
                        pw.Text('City: ${order.customer.extraFields['Şehir']}'),
                      if (order.customer.extraFields['Telefon'] != null)
                        pw.Text('Phone: ${order.customer.extraFields['Telefon']}'),
                      if (order.customer.extraFields['E-posta'] != null)
                        pw.Text('Email: ${order.customer.extraFields['E-posta']}'),
                      if (order.customer.extraFields['Adres'] != null)
                        pw.Text('Address: ${order.customer.extraFields['Adres']}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Order Items
                pw.Table.fromTextArray(
                  headers: ['Item', 'Quantity', 'Price'],
                  data: order.items.map((item) => [
                    item.item.name,
                    item.quantity.toString(),
                    '\$${(item.item.price * item.quantity).toStringAsFixed(2)}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),

                // Total
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bill_${order.id}.pdf');
      
      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill saved as PDF'),
          duration: Duration(seconds: 2),
        ),
      );

      // Open the PDF using url_launcher
      final url = Uri.file(file.path);
      if (!await launchUrl(url)) {
        throw Exception('Could not open the file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _completeAndReturn(BuildContext context) async {
    try {
      // Update inventory after bill is shown
      for (var orderItem in order.items) {
        await InventoryService.updateItemQuantity(
          orderItem.item.id,
          -orderItem.quantity
        );
      }
      
      // Call the completion callback
      onComplete();
      
      // Pop until we reach the main screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing order: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow('Company', 'Founder ERP'),
                          _buildInfoRow('Date', DateTime.now().toString().split('.')[0]),
                          _buildInfoRow('Order ID', '#${order.id}'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Customer Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow('Name', order.customer.name),
                          if (order.customer.extraFields['Ülke'] != null)
                            _buildInfoRow('Country', order.customer.extraFields['Ülke']!),
                          if (order.customer.extraFields['Şehir'] != null)
                            _buildInfoRow('City', order.customer.extraFields['Şehir']!),
                          if (order.customer.extraFields['Telefon'] != null)
                            _buildInfoRow('Phone', order.customer.extraFields['Telefon']!),
                          if (order.customer.extraFields['E-posta'] != null)
                            _buildInfoRow('Email', order.customer.extraFields['E-posta']!),
                          if (order.customer.extraFields['Adres'] != null)
                            _buildInfoRow('Address', order.customer.extraFields['Adres']!),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Order Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Items',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            itemBuilder: (context, index) {
                              final item = order.items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(item.item.name),
                                    ),
                                    Expanded(
                                      child: Text('x${item.quantity}'),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '\$${(item.item.price * item.quantity).toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Divider(thickness: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${order.totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _generateAndOpenPDF(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Print',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _completeAndReturn(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Return',
                      style: TextStyle(fontSize: 18),
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

