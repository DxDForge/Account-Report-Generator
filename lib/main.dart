import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const BellaCiaoApp());
}

class BellaCiaoApp extends StatelessWidget {
  const BellaCiaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bella Ciao PDF Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DailyReportScreen(),
    );
  }
}

class CustomerReview {
  String customerName;
  String item;
  int rating;
  String comment;
  String sentiment;

  CustomerReview({
    this.customerName = '',
    this.item = '',
    this.rating = 5,
    this.comment = '',
    this.sentiment = 'Positive',
  });
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Date
  DateTime _selectedDate = DateTime.now();

  // Account fields
  final _openingCashController = TextEditingController(text: '0');
  final _openingBkashController = TextEditingController(text: '0');
  final _cashSalesController = TextEditingController(text: '0');
  final _bkashSalesController = TextEditingController(text: '0');
  final _cashExpensesController = TextEditingController(text: '0');
  final _bkashExpensesController = TextEditingController(text: '0');
  final _salesTargetController = TextEditingController(text: '4000');
  final _focusController = TextEditingController();
  final _action1Controller = TextEditingController();
  final _action2Controller = TextEditingController();
  final _action3Controller = TextEditingController();
  final _impactController = TextEditingController();
  final _notesController = TextEditingController();

  // Reviews
  List<CustomerReview> _reviews = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _openingCashController.dispose();
    _openingBkashController.dispose();
    _cashSalesController.dispose();
    _bkashSalesController.dispose();
    _cashExpensesController.dispose();
    _bkashExpensesController.dispose();
    _salesTargetController.dispose();
    _focusController.dispose();
    _action1Controller.dispose();
    _action2Controller.dispose();
    _action3Controller.dispose();
    _impactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) => double.tryParse(value) ?? 0;

  // Calculated values
  double get totalOpening => _parseDouble(_openingCashController.text) + _parseDouble(_openingBkashController.text);
  double get totalSales => _parseDouble(_cashSalesController.text) + _parseDouble(_bkashSalesController.text);
  double get totalExpenses => _parseDouble(_cashExpensesController.text) + _parseDouble(_bkashExpensesController.text);
  double get closingCash => _parseDouble(_openingCashController.text) + _parseDouble(_cashSalesController.text) - _parseDouble(_cashExpensesController.text);
  double get closingBkash => _parseDouble(_openingBkashController.text) + _parseDouble(_bkashSalesController.text) - _parseDouble(_bkashExpensesController.text);
  double get totalClosing => closingCash + closingBkash;
  double get salesTarget => _parseDouble(_salesTargetController.text);
  double get variance => totalSales - salesTarget;
  double get achievementRate => salesTarget > 0 ? (totalSales / salesTarget) * 100 : 0;
  bool get targetAchieved => totalSales >= salesTarget;

  void _addReview() {
    setState(() {
      _reviews.add(CustomerReview());
    });
  }

  void _removeReview(int index) {
    setState(() {
      _reviews.removeAt(index);
    });
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BELLA CIAO - DAILY ACCOUNT REPORT',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Report Date: ${DateFormat('d-MMM-yyyy').format(_selectedDate)}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Financial Summary
              _buildPDFSection('FINANCIAL SUMMARY'),
              pw.SizedBox(height: 8),
              _buildPDFSubsection('Opening Balance'),
              _buildPDFRow('Cash', _openingCashController.text),
              _buildPDFRow('bKash', _openingBkashController.text),
              _buildPDFRow('Total Opening', totalOpening.toStringAsFixed(0), bold: true),
              pw.SizedBox(height: 8),

              _buildPDFSubsection('Today\'s Sales'),
              _buildPDFRow('Cash Sales', _cashSalesController.text),
              _buildPDFRow('bKash Sales', _bkashSalesController.text),
              _buildPDFRow('Total Sales', totalSales.toStringAsFixed(0), bold: true),
              pw.SizedBox(height: 8),

              _buildPDFSubsection('Expenses'),
              _buildPDFRow('Cash Expenses', _cashExpensesController.text),
              _buildPDFRow('bKash Expenses', _bkashExpensesController.text),
              _buildPDFRow('Total Expenses', totalExpenses.toStringAsFixed(0), bold: true),
              pw.SizedBox(height: 8),

              _buildPDFSubsection('Closing Balance'),
              _buildPDFRow('Cash', closingCash.toStringAsFixed(0)),
              _buildPDFRow('BKash', closingBkash.toStringAsFixed(0)),
              _buildPDFRow('Total Closing', totalClosing.toStringAsFixed(0), bold: true),
              pw.SizedBox(height: 12),

              // Target Performance
              _buildPDFSection('TARGET PERFORMANCE'),
              pw.SizedBox(height: 8),
              _buildPDFRow('Daily Sales Target', salesTarget.toStringAsFixed(0)),
              _buildPDFRow('Sales Achieved', totalSales.toStringAsFixed(0)),
              _buildPDFRow('Achievement Rate', '${achievementRate.toStringAsFixed(1)}%'),
              _buildPDFRow('Status', targetAchieved ? '✓ Target Achieved' : '✗ Target Not Achieved'),
              _buildPDFRow('Variance', variance.toStringAsFixed(0)),
              pw.SizedBox(height: 12),

              // 1% Improvement
              _buildPDFSection('1% DAILY IMPROVEMENT INITIATIVE'),
              pw.SizedBox(height: 8),
              pw.Text('Today\'s Focus: ${_focusController.text}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text('Actions Implemented:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              if (_action1Controller.text.isNotEmpty) pw.Text('1. ${_action1Controller.text}', style: const pw.TextStyle(fontSize: 10)),
              if (_action2Controller.text.isNotEmpty) pw.Text('2. ${_action2Controller.text}', style: const pw.TextStyle(fontSize: 10)),
              if (_action3Controller.text.isNotEmpty) pw.Text('3. ${_action3Controller.text}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text('Expected Impact: ${_impactController.text}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),

              // Additional Notes
              if (_notesController.text.isNotEmpty) ...[
                _buildPDFSection('ADDITIONAL NOTES'),
                pw.SizedBox(height: 8),
                pw.Text(_notesController.text, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 12),
              ],

              // Customer Reviews
              if (_reviews.isNotEmpty) ...[
                _buildPDFSection('CUSTOMER REVIEWS'),
                pw.SizedBox(height: 8),
                ..._reviews.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final review = entry.value;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${idx + 1}. ${review.customerName} - ${review.item}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '   Rating: ${'★' * review.rating}${'☆' * (5 - review.rating)} | ${review.sentiment}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text('   ${review.comment}', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                    ],
                  );
                }),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Total Reviews: ${_reviews.length} | Avg Rating: ${_reviews.isEmpty ? 0 : (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length).toStringAsFixed(1)}★',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Report Prepared For: Bella Ciao Partners', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Next Report: ${DateFormat('d-MMM-yyyy').format(_selectedDate.add(const Duration(days: 1)))}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Show preview and save
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bella_Ciao_Report_${DateFormat('dd-MM-yyyy').format(_selectedDate)}.pdf',
    );
  }

  pw.Widget _buildPDFSection(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildPDFSubsection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildPDFRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
          pw.Text('$value tk', style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bella Ciao Daily Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _generatePDF();
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Picker
              Card(
                color: Theme.of(context).primaryColor,
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Report Date', style: TextStyle(color: Colors.white70)),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.calendar_today, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildSection('Opening Balance'),
              _buildNumberField('Opening Cash', _openingCashController),
              _buildNumberField('Opening bKash', _openingBkashController),
              _buildCalculatedRow('Total Opening', totalOpening),

              _buildSection('Today\'s Sales'),
              _buildNumberField('Cash Sales', _cashSalesController),
              _buildNumberField('bKash Sales', _bkashSalesController),
              _buildCalculatedRow('Total Sales', totalSales),

              _buildSection('Expenses'),
              _buildNumberField('Cash Expenses', _cashExpensesController),
              _buildNumberField('bKash Expenses', _bkashExpensesController),
              _buildCalculatedRow('Total Expenses', totalExpenses),

              _buildSection('Closing Balance'),
              _buildCalculatedRow('Closing Cash', closingCash, color: Colors.green),
              _buildCalculatedRow('Closing bKash', closingBkash, color: Colors.green),
              _buildCalculatedRow('Total Closing', totalClosing, color: Colors.green, bold: true),

              _buildSection('Sales Target'),
              _buildNumberField('Daily Sales Target', _salesTargetController),
              _buildCalculatedRow('Achievement Rate', achievementRate, suffix: '%', color: targetAchieved ? Colors.green : Colors.red),
              Card(
                color: (targetAchieved ? Colors.green : Colors.red).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      targetAchieved ? '✓ Target Achieved' : '✗ Target Not Achieved',
                      style: TextStyle(
                        color: targetAchieved ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              _buildSection('1% Daily Improvement'),
              _buildTextField('Today\'s Focus', _focusController),
              const SizedBox(height: 8),
              const Text('Actions Implemented:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildTextField('Action 1', _action1Controller, required: false),
              _buildTextField('Action 2', _action2Controller, required: false),
              _buildTextField('Action 3', _action3Controller, required: false),
              _buildTextField('Expected Impact', _impactController, maxLines: 2),

              _buildSection('Additional Notes'),
              _buildTextField('Notes', _notesController, maxLines: 3, required: false),

              _buildSection('Customer Reviews'),
              ..._reviews.asMap().entries.map((entry) {
                final idx = entry.key;
                final review = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Review ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _removeReview(idx),
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: review.customerName,
                          decoration: const InputDecoration(labelText: 'Customer Name'),
                          onChanged: (v) => review.customerName = v,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: review.item,
                          decoration: const InputDecoration(labelText: 'Item/Menu'),
                          onChanged: (v) => review.item = v,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Rating: '),
                            ...List.generate(5, (i) {
                              return IconButton(
                                icon: Icon(
                                  i < review.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                ),
                                onPressed: () => setState(() => review.rating = i + 1),
                              );
                            }),
                          ],
                        ),
                        TextFormField(
                          initialValue: review.comment,
                          decoration: const InputDecoration(labelText: 'Comment'),
                          maxLines: 2,
                          onChanged: (v) => review.comment = v,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: review.sentiment,
                          decoration: const InputDecoration(labelText: 'Sentiment'),
                          items: ['Positive', 'Neutral', 'Negative'].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (v) => setState(() => review.sentiment = v!),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addReview,
                icon: const Icon(Icons.add),
                label: const Text('Add Customer Review'),
              ),
              const SizedBox(height: 24),

              // Generate PDF Button
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _generatePDF();
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('GENERATE PDF REPORT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 100), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '৳ ',
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (double.tryParse(v) == null) return 'Invalid number';
          return null;
        },
        onChanged: (v) => setState(() {}), // Trigger rebuild for calculations
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildCalculatedRow(String label, double value, {String suffix = '', Color? color, bool bold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            '৳${value.toStringAsFixed(0)}$suffix',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: bold ? 18 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
