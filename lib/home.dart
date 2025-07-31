import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:test_qr/model.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController controller =
      MobileScannerController(formats: [BarcodeFormat.qrCode]);

  bool _torchEnabled = false;
  String _qrResult = 'Apunta al QR…';
  bool isScanned = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
      body: Column(
        children: [
          if (!isScanned) ...[
            Expanded(
              flex: 4,
              child: MobileScanner(
                controller: controller,
                onDetect: (capture) {
                  final code = capture.barcodes.first.rawValue;
                  if (code != null && mounted) {
                    controller.stop(); // Detiene tras escaneo exitoso
                    try {
                      final parsedQr = EmvcoQrPayloadModel.fromPayload(code);
                      setState(() {
                        _qrResult = '''
                        Formato: ${parsedQr.payloadFormat}
                        Tipo: ${parsedQr.initiationMethod}
                        Comercio: ${parsedQr.merchantName}
                        Ciudad: ${parsedQr.merchantCity}
                        Monto: ${parsedQr.transactionAmount}
                        Moneda: ${parsedQr.currencyCode}
                        CRC: ${parsedQr.crc}
                        ''';
                        isScanned = true;
                      });
                    } catch (e) {
                      setState(() {
                        _qrResult = 'Error al procesar el QR: $e';
                        isScanned = true;
                      });
                    }
                  }
                },
              ),
            ),
          ],
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
