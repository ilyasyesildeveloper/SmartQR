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
  MobileScannerController? _controller;

  String? _lastScannedCode;
  Timer? _dwellTimer;
  Timer? _graceTimer;
  bool _isProcessing = false;
  double _dwellProgress = 0.0;
  bool _torchOn = false;
  DateTime? _dwellStartTime;

  static const int dwellMs = 1000;
  static const Duration gracePeriod = Duration(milliseconds: 400);

  // Scan window (ekran koordinatları, build sırasında hesaplanır)
  Rect? _scanWindow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initScanWindow();
  }

  void _initScanWindow() {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2 - 40;

    final newScanWindow = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    if (_scanWindow != newScanWindow) {
      _scanWindow = newScanWindow;
      // Controller'ı scanWindow ile oluştur
      _controller?.dispose();
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.unrestricted,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _graceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _startGracePeriod();
      return;
    }

    // scanWindow zaten native seviyede filtreleme yapıyor
    // Geçerli barcodeları al
    final validBarcodes = barcodes.where(
      (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
    ).toList();

    if (validBarcodes.isEmpty) {
      _startGracePeriod();
      return;
    }

    // Birden fazla varsa corners ile merkeze en yakınını seç
    String? code;
    if (validBarcodes.length == 1) {
      code = validBarcodes.first.rawValue;
    } else if (_scanWindow != null) {
      final centerX = _scanWindow!.center.dx;
      final centerY = _scanWindow!.center.dy;
      
      Barcode? closest;
      double minDist = double.infinity;

      for (final barcode in validBarcodes) {
        if (barcode.corners != null && barcode.corners!.length >= 4) {
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
      }
      code = closest?.rawValue ?? validBarcodes.first.rawValue;
    } else {
      code = validBarcodes.first.rawValue;
    }

    if (code == null || code.isEmpty) return;

    _graceTimer?.cancel();

    if (code == _lastScannedCode) {
      // Aynı kod — dwell progress güncelle
      if (_dwellStartTime != null) {
        final elapsed = DateTime.now().difference(_dwellStartTime!).inMilliseconds;
        final progress = (elapsed / dwellMs).clamp(0.0, 1.0);
        if (mounted) setState(() => _dwellProgress = progress);
        if (elapsed >= dwellMs) {
          _dwellTimer?.cancel();
          _processCode(code);
        }
      }
      return;
    }

    // Yeni kod — dwell sıfırla
    _lastScannedCode = code;
    _dwellStartTime = DateTime.now();
    _dwellTimer?.cancel();
    setState(() => _dwellProgress = 0.0);

    _dwellTimer = Timer(Duration(milliseconds: dwellMs + 100), () {
      if (_lastScannedCode == code && !_isProcessing) {
        _processCode(code!);
      }
    });
  }

  void _startGracePeriod() {
    _graceTimer?.cancel();
    _graceTimer = Timer(gracePeriod, () {
      _dwellTimer?.cancel();
      if (mounted) {
        setState(() {
          _lastScannedCode = null;
          _dwellProgress = 0.0;
          _dwellStartTime = null;
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
        _dwellStartTime = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.get('product_not_found')}: $code'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _scanWindow == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view — scanWindow ile native filtreleme!
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
            scanWindow: _scanWindow!, // ← NATIVE ALAN SINIRLAMASI
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
              _controller?.toggleTorch();
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

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height - radius)
        ..quadraticBezierTo(size.width, size.height, size.width - radius, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(cornerLength, size.height)
        ..lineTo(radius, size.height)
        ..quadraticBezierTo(0, size.height, 0, size.height - radius)
        ..lineTo(0, size.height - cornerLength),
      paint,
    );

    // Progress arc
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
