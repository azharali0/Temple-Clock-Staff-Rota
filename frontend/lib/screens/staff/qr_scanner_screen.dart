import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants.dart';

/// Full-screen camera QR scanner for staff clock-in / clock-out.
/// Returns the raw QR string via Navigator.pop on successful scan.
class QrScannerScreen extends StatefulWidget {
  final bool isClockIn;
  const QrScannerScreen({super.key, required this.isClockIn});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);

    // Brief haptic-like visual feedback, then return value
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context, barcode.rawValue);
    });
  }

  void _showManualEntry() async {
    final codeCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter QR Code',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: codeCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'QR Code',
            hintText: 'Paste the code from the printed QR',
            prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, codeCtrl.text.trim()),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isClockIn ? 'Clock In' : 'Clock Out';
    final safeTop = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.65;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed ──
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Scan overlay ──
          _ScanOverlay(scanArea: scanArea, scanned: _hasScanned),

          // ── Top bar ──
          Positioned(
            top: safeTop + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                _circleButton(Icons.arrow_back_rounded, () {
                  Navigator.pop(context);
                }),
                const Spacer(),
                _circleButton(
                  _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                ),
              ],
            ),
          ),

          // ── Bottom info + manual entry ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 28, 24, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          color: AppColors.teal, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Scan QR to $label',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point your camera at the QR code printed by your admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Manual entry fallback
                  OutlinedButton.icon(
                    onPressed: _showManualEntry,
                    icon: const Icon(Icons.keyboard_rounded, size: 18),
                    label: const Text('Enter code manually'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── "Scanned!" overlay ──
          if (_hasScanned)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR Code Scanned!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Custom overlay that draws a translucent mask with a clear scan window.
class _ScanOverlay extends StatelessWidget {
  final double scanArea;
  final bool scanned;
  const _ScanOverlay({required this.scanArea, required this.scanned});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _OverlayPainter(scanArea: scanArea, scanned: scanned),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanArea;
  final bool scanned;
  _OverlayPainter({required this.scanArea, required this.scanned});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final rect = Rect.fromCenter(
        center: center, width: scanArea, height: scanArea);

    // Draw translucent background
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      bg,
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = scanned ? const Color(0xFF00BFA5) : Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cLen = 28.0;
    const r = 16.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cLen)
        ..lineTo(rect.left, rect.top + r)
        ..arcToPoint(Offset(rect.left + r, rect.top),
            radius: const Radius.circular(r))
        ..lineTo(rect.left + cLen, rect.top),
      cornerPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cLen, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + r),
            radius: const Radius.circular(r))
        ..lineTo(rect.right, rect.top + cLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cLen)
        ..lineTo(rect.left, rect.bottom - r)
        ..arcToPoint(Offset(rect.left + r, rect.bottom),
            radius: const Radius.circular(r))
        ..lineTo(rect.left + cLen, rect.bottom),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cLen, rect.bottom)
        ..lineTo(rect.right - r, rect.bottom)
        ..arcToPoint(Offset(rect.right, rect.bottom - r),
            radius: const Radius.circular(r))
        ..lineTo(rect.right, rect.bottom - cLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.scanned != scanned;
}
