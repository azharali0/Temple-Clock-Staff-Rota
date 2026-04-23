// lib/screens/admin/client_management_page.dart

import "dart:convert";
import "dart:typed_data";
import "dart:ui" as ui;
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:http/http.dart" as http;
import "package:provider/provider.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart";
import "package:qr_flutter/qr_flutter.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/constants.dart";
import "../../core/responsive.dart";
import "../../models/user_model.dart";
import "../../widgets/shared_widgets.dart";

class ClientProperty {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String qrToken;

  ClientProperty({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.qrToken,
  });

  factory ClientProperty.fromJson(Map<String, dynamic> json) {
    return ClientProperty(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Client',
      address: json['address']?.toString() ?? 'No address',
      lat: (json['coordinates'] != null && json['coordinates']['lat'] != null)
          ? (json['coordinates']['lat'] as num).toDouble()
          : 0.0,
      lng: (json['coordinates'] != null && json['coordinates']['lng'] != null)
          ? (json['coordinates']['lng'] as num).toDouble()
          : 0.0,
      qrToken: json['qrToken']?.toString() ?? '',
    );
  }
}

class ClientManagementPage extends StatefulWidget {
  const ClientManagementPage({super.key});

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  bool _isLoading = true;
  List<ClientProperty> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) return;

      final res = await http.get(
        Uri.parse("${AppConstants.apiBaseUrl}/clients"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded is List) {
          setState(() {
            _clients = decoded.map((x) => ClientProperty.fromJson(x)).toList();
          });
        } else {
          if (mounted) showAppSnackBar(context, "Invalid JSON structure received from server.", isError: true);
        }
      } else {
        if (mounted) showAppSnackBar(context, "Error fetching clients", isError: true);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Network Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addClient(String name, String address, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) return;

      final res = await http.post(
        Uri.parse("${AppConstants.apiBaseUrl}/clients"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": name,
          "address": address,
          "coordinates": {"lat": lat, "lng": lng}
        }),
      );

      if (res.statusCode == 201) {
        _fetchClients();
        if (mounted) showAppSnackBar(context, "Client \"$name\" added successfully!");
      } else {
        // Show the actual server error message
        String errMsg = "Failed to create client.";
        try {
          final errData = json.decode(res.body);
          if (errData['message'] != null) errMsg = errData['message'];
          if (errData['errors'] != null) {
            errMsg = (errData['errors'] as List).map((e) => e['msg']).join(', ');
          }
        } catch (_) {}
        if (mounted) showAppSnackBar(context, errMsg, isError: true);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Error: $e", isError: true);
    }
  }

  Future<Uint8List> _generatePdfBytes(ClientProperty client) async {
    final qrPayload = '{"type":"careshift-client-property","clientId":"${client.id}","token":"${client.qrToken}"}';
    final qrValidationResult = QrValidator.validate(
      data: qrPayload,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final qrCode = qrValidationResult.qrCode;
    final painter = QrPainter.withQr(
      qr: qrCode!,
      color: const Color(0xFF0F2C59),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );
    final picData = await painter.toImageData(2048, format: ui.ImageByteFormat.png);
    if (picData == null) throw Exception('Failed to render QR Code');
    final qrImageBytes = picData.buffer.asUint8List();

    // Use explicit built-in fonts to suppress the Helvetica Unicode warning
    final boldFont = pw.Font.helveticaBold();
    final regularFont = pw.Font.helvetica();

    // Sanitise client strings — remove any non-ASCII chars that Helvetica can't encode
    String safe(String s) => s.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');

    final doc = pw.Document();
    final imageProvider = pw.MemoryImage(qrImageBytes);
    final today = DateFormat('d MMMM yyyy').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Temple Clock Domiciliary Care',
                style: pw.TextStyle(font: boldFont, fontSize: 26, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Property Clock-In / Clock-Out Point',
                style: pw.TextStyle(font: regularFont, fontSize: 16, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 32),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue900, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Image(imageProvider, width: 320, height: 320),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                safe(client.name),
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                safe(client.address),
                style: pw.TextStyle(font: regularFont, fontSize: 15, color: PdfColors.grey800),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'GPS: ${client.lat.toStringAsFixed(5)}, ${client.lng.toStringAsFixed(5)}',
                style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.teal),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Text(
                'DO NOT REMOVE - Staff must scan upon arrival and departure.',
                style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.red600),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated: $today',
                style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _printQR(ClientProperty client) async {
    try {
      final pdfBytes = await _generatePdfBytes(client);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'TempleClock_Property_${client.name}.pdf',
      );
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to print: $e', isError: true);
    }
  }

  void _showAddClientDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Client Database", style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Client Name (e.g. Mrs Smith)"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: "Property Address"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latCtrl,
                        decoration: const InputDecoration(labelText: "Latitude"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => double.tryParse(v ?? '') == null ? "Invalid" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: lngCtrl,
                        decoration: const InputDecoration(labelText: "Longitude"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => double.tryParse(v ?? '') == null ? "Invalid" : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                _addClient(
                  nameCtrl.text,
                  addressCtrl.text,
                  double.parse(latCtrl.text),
                  double.parse(lngCtrl.text),
                );
              }
            },
            child: const Text("Add Property"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Domiciliary Properties", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add),
        label: const Text("Add Client Property"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_work_outlined, size: 64, color: AppColors.border),
                      const SizedBox(height: 16),
                      const Text("No client properties yet",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text("Tap \"Add Client Property\" to create your first domiciliary location.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _clients.length,
                  itemBuilder: (ctx, i) {
                    final c = _clients[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                              radius: 24,
                              child: const Icon(Icons.home, color: AppColors.teal),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          fontFamily: "Outfit",
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.navy)),
                                  const SizedBox(height: 4),
                                  Text(c.address,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "GPS: ${c.lat.toStringAsFixed(4)}, ${c.lng.toStringAsFixed(4)}",
                                      style: const TextStyle(fontSize: 11, color: AppColors.teal)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: "Print Property QR Code",
                              icon: const Icon(Icons.print, color: AppColors.navy),
                              onPressed: () => _printQR(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
