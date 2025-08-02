import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:test_qr/model.dart';
import 'package:test_qr/picker.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  // Inicialización única y definitiva
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _torchEnabled = false;
  String _qrResult = 'Apunta al QR…';
  bool isScanned = false;
  bool? _isRedeban;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _resetScanner() {
    controller.start();
    setState(() {
      _qrResult = 'Apunta al QR…';
      isScanned = false;
      _isRedeban = null;
    });
  }

  Future<String?> scanQrFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final BarcodeCapture? capture = await controller.analyzeImage(picked.path);
    if (capture == null || capture.barcodes.isEmpty) return null;

    return capture.barcodes.first.rawValue;
  }

  void _processPayload(String code) {
    try {
      final parsed = EmvcoQrPayloadModel.fromPayload(code);
      setState(() {
        _qrResult = '''
          Formato: ${parsed.payloadFormat}
          Tipo: ${parsed.initiationMethod}
          Comercio: ${parsed.merchantName}
          Ciudad: ${parsed.merchantCity}
          Monto: ${parsed.transactionAmount}
          Moneda: ${parsed.currencyCode}
          CRC: ${parsed.crc}
          ''';
        _isRedeban = true;
        isScanned = true;
      });
    } catch (e) {
      setState(() {
        _qrResult = 'Error al procesar el QR:\n$e';
        _isRedeban = false;
        isScanned = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isRedeban == null
          ? Colors.white
          : (_isRedeban == true ? Colors.green[200] : Colors.red[200]),
      appBar: AppBar(
        title: const Text('Prueba aislada lector de QR'),
        actions: [
          IconButton(
            icon: Icon(
                _torchEnabled ? Icons.flashlight_on : Icons.flashlight_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() => _torchEnabled = !_torchEnabled);
            },
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Leer QR desde galería',
            onPressed: () async {
              scanQrFromDesktop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isScanned)
            Expanded(
              flex: 4,
              child: MobileScanner(
                controller: controller,
                onDetect: (capture) {
                  final code = capture.barcodes.first.rawValue;
                  if (code != null && mounted) {
                    controller.stop();
                    _processPayload(code);
                  }
                },
              ),
            ),
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Resultado del QR:\n$_qrResult',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetScanner,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
