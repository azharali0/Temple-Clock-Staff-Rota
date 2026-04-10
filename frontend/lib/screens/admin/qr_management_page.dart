import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../services/qr_service.dart';
import '../../widgets/shared_widgets.dart';

class QrManagementPage extends StatefulWidget {
  const QrManagementPage({super.key});

  @override
  State<QrManagementPage> createState() => _QrManagementPageState();
}

class _QrManagementPageState extends State<QrManagementPage> {
  bool _loading = true;
  DailyQR? _activeQR;
  List<DailyQR> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final qrService = Provider.of<QrService>(context, listen: false);
      DailyQR? active;
      try {
        active = await qrService.getActiveQR();
      } catch (_) {
        active = null; // No active QR yet
      }
      final history = await qrService.getQRHistory();
      if (mounted) {
        setState(() {
          _activeQR = active;
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppSnackBar(context, 'Failed to load QR data: $e', isError: true);
      }
    }
  }

  Future<void> _generateNewQR() async {
    final labelCtrl = TextEditingController(
      text: 'QR – ${DateFormat('d MMM yyyy').format(DateTime.now())}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.teal, size: 24),
            SizedBox(width: 8),
            Text('Generate New QR Code',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activeQR != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This will expire the current active QR code. Old printouts will stop working.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'e.g. Monday QR',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final qrService = Provider.of<QrService>(context, listen: false);
      await qrService.generateDailyQR(label: labelCtrl.text.trim());
      if (mounted) {
        showAppSnackBar(context, 'New QR code generated!');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _expireQR(DailyQR qr) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Expire QR Code',
      message: 'Expire "${qr.label}"? Staff will no longer be able to use it.',
      confirmLabel: 'Expire',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final qrService = Provider.of<QrService>(context, listen: false);
      await qrService.expireQR(qr.id);
      if (mounted) {
        showAppSnackBar(context, 'QR code expired');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _printQR(DailyQR qr) async {
    final doc = pw.Document();
    final df = DateFormat('EEEE, d MMM yyyy');
    final qrPayload = '{"type":"careshift-daily","token":"${qr.token}"}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Temple Clock', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
                pw.SizedBox(height: 10),
                pw.Text('Staff Clock-In / Clock-Out', style: pw.TextStyle(fontSize: 24, color: PdfColors.grey700)),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                  ),
                  child: pw.BarcodeWidget(
                    color: PdfColor.fromHex('#0F2C59'),
                    barcode: pw.Barcode.qrCode(),
                    data: qrPayload,
                    width: 300,
                    height: 300,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(qr.label, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Generated on ${df.format(qr.createdAt.toLocal())}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                pw.SizedBox(height: 40),
                pw.Text('Please use the Temple Clock Staff App to scan this code.', style: const pw.TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Temple-Clock-QR-${qr.label}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('QR Management',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy)),
                        Text(
                          'Generate and manage daily QR codes for staff clock-in / clock-out',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _generateNewQR,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isDesktop ? 'Generate New QR' : 'New QR',
                        style: const TextStyle(fontFamily: 'Outfit')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active QR Card
              _buildActiveQRCard(isDesktop),
              const SizedBox(height: 24),

              // History
              const Text('QR History',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: AppColors.teal))
              else if (_history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No QR codes generated yet',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              else
                ..._history.map(_buildHistoryTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveQRCard(bool isDesktop) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    if (_activeQR == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.qr_code_2_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No Active QR Code',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
            const SizedBox(height: 6),
            Text('Generate a new QR code for staff to scan when clocking in or out.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _generateNewQR,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Generate QR Code'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    final qr = _activeQR!;
    final df = DateFormat('d MMM yyyy  •  HH:mm');
    // This is the payload the QR image encodes — the token itself
    final qrPayload = '{"type":"careshift-daily","token":"${qr.token}"}';

    if (isDesktop) {
      // Side-by-side layout
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR image
            _qrImageBlock(qrPayload),
            const SizedBox(width: 32),
            // Details
            Expanded(child: _qrDetailsBlock(qr, df)),
          ],
        ),
      );
    }

    // Mobile: stacked layout
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _qrImageBlock(qrPayload),
          const SizedBox(height: 20),
          _qrDetailsBlock(qr, df),
        ],
      ),
    );
  }

  Widget _qrImageBlock(String qrPayload) {
    final screenW = MediaQuery.of(context).size.width;
    final qrSize = screenW < 400 ? 160.0 : (screenW < 700 ? 190.0 : 220.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: QrImageView(
        data: qrPayload,
        version: QrVersions.auto,
        size: qrSize,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF0F2C59),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF0F2C59),
        ),
      ),
    );
  }

  Widget _qrDetailsBlock(DailyQR qr, DateFormat df) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.teal),
                  SizedBox(width: 4),
                  Text('ACTIVE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(qr.label,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 6),
        Text('Generated: ${df.format(qr.createdAt.toLocal())}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        if (qr.generatedByName.isNotEmpty)
          Text('By: ${qr.generatedByName}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        const Text(
          'Print this QR code and hang it in your office.\nStaff must scan it to clock in or clock out.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _printQR(qr),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Print / PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _generateNewQR,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Replace QR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _expireQR(qr),
              icon: const Icon(Icons.block, size: 16),
              label: const Text('Expire'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTile(DailyQR qr) {
    final df = DateFormat('d MMM yyyy  •  HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: qr.isActive
              ? AppColors.teal.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: qr.isActive
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 20,
              color: qr.isActive ? AppColors.teal : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(qr.label,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(df.format(qr.createdAt.toLocal()),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: qr.isActive
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              qr.isActive ? 'Active' : 'Expired',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: qr.isActive ? AppColors.teal : Colors.grey.shade500,
              ),
            ),
          ),
          if (qr.isActive) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _expireQR(qr),
              icon: const Icon(Icons.block, size: 16, color: AppColors.error),
              tooltip: 'Expire this QR',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
