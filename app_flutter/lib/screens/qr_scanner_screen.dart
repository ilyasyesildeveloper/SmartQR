import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted, // Her frame'de tara (center-matching için şart)
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  String? _lastScannedCode;
  Timer? _dwellTimer;
  Timer? _graceTimer;
  bool _isProcessing = false;
  double _dwellProgress = 0.0;
  Timer? _progressTimer;
  bool _torchOn = false;
  DateTime? _dwellStartTime;

  static const int dwellMs = 1000; // 1.0 saniye
  static const Duration gracePeriod = Duration(milliseconds: 400); // El titremesi toleransı

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _graceTimer?.cancel();
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _startGracePeriod();
      return;
    }

    // CENTER-MATCHING: Merkeze en yakın QR kodu seç
    final validBarcodes = barcodes.where(
      (b) => b.rawValue != null && b.rawValue!.isNotEmpty && b.corners != null && b.corners!.length >= 4,
    ).toList();

    if (validBarcodes.isEmpty) {
      _startGracePeriod();
      return;
    }

    // Ekran merkezi (tarama alanı)
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2 - 40;

    // En yakın QR'ı bul
    Barcode? closest;
    double minDist = double.infinity;

    for (final barcode in validBarcodes) {
      final corners = barcode.corners!;
      double bx = 0, by = 0;
      for (final corner in corners) {
        bx += corner.dx;
        by += corner.dy;
      }
      bx /= corners.length;
      by /= corners.length;

      final dist = (bx - centerX) * (bx - centerX) + (by - centerY) * (by - centerY);
      if (dist < minDist) {
        minDist = dist;
        closest = barcode;
      }
    }

    final code = closest?.rawValue;
    if (code == null || code.isEmpty) return;

    // Grace period iptal — kod var
    _graceTimer?.cancel();

    if (code == _lastScannedCode) {
      // Aynı kod — dwell devam ediyor, progress güncelle
      if (_dwellStartTime != null) {
        final elapsed = DateTime.now().difference(_dwellStartTime!).inMilliseconds;
        final progress = (elapsed / dwellMs).clamp(0.0, 1.0);
        if (mounted) setState(() => _dwellProgress = progress);
        if (elapsed >= dwellMs) {
          _dwellTimer?.cancel();
          _progressTimer?.cancel();
          _processCode(code);
        }
      }
      return;
    }

    // Yeni kod — dwell sıfırla
    _lastScannedCode = code;
    _dwellStartTime = DateTime.now();
    _startDwellTimer(code);
  }

  void _startDwellTimer(String code) {
    _dwellTimer?.cancel();
    _progressTimer?.cancel();

    setState(() {
      _dwellProgress = 0.0;
    });

    // Fallback timer — unrestricted mode handles progress in _onDetect
    // but this timer ensures processCode fires even if detection stops
    _dwellTimer = Timer(Duration(milliseconds: dwellMs + 100), () {
      if (_lastScannedCode == code && !_isProcessing) {
        _processCode(code);
      }
    });
  }

  void _startGracePeriod() {
    _graceTimer?.cancel();
    _graceTimer = Timer(gracePeriod, () {
      // Code lost for too long, reset
      _dwellTimer?.cancel();
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _lastScannedCode = null;
          _dwellProgress = 0.0;
        });
      }
    });
  }

  Future<void> _processCode(String code) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    final provider = context.read<ProductProvider>();
    final product = await provider.findByQrCode(code);

    if (!mounted) return;

    if (product != null) {
      Navigator.pop(context, product);
    } else {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
        _dwellProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün bulunamadı: $code'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with cutout
          _buildOverlay(),

          // Top bar
          _buildTopBar(),

          // Bottom bar with flashlight
          _buildBottomBar(),

          // Processing indicator
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;

        return Stack(
          children: [
            // Semi-transparent overlay
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scan frame corners
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: CustomPaint(
                  painter: _ScanFramePainter(
                    progress: _dwellProgress,
                    color: _dwellProgress > 0
                        ? AppTheme.accentGold
                        : AppTheme.burgundyLight,
                  ),
                ),
              ),
            ),

            // Dwell time indicator text
            if (_dwellProgress > 0)
              Positioned(
                left: left,
                top: top + scanAreaSize + 16,
                width: scanAreaSize,
                child: Text(
                  '${AppLocalizations.get('focusing')} ${(_dwellProgress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Material(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
            Text(
              AppLocalizations.get('scan_title'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              _controller.toggleTorch();
              setState(() {
                _torchOn = !_torchOn;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: _torchOn ? AppTheme.accentGold : Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('searching_product'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanFramePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const radius = 20.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height - radius)
        ..quadraticBezierTo(size.width, size.height, size.width - radius, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cornerLength, size.height)
        ..lineTo(radius, size.height)
        ..quadraticBezierTo(0, size.height, 0, size.height - radius)
        ..lineTo(0, size.height - cornerLength),
      paint,
    );

    // Progress indicator around the frame
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = AppTheme.accentGold
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawArc(rect, -1.5708, progress * 6.2832, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
