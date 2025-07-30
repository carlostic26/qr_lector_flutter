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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba aislada lector de QR'),
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flashlight_on : Icons.flashlight_off,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                _torchEnabled = !_torchEnabled;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final code = capture.barcodes.first.rawValue;
                if (code != null && mounted) {
                  controller.stop(); // Detener después de leer un QR
                  try {
                    final parsedQr = EmvcoQrPayloadModel.fromPayload(code);

                    // Mostrar información clave del QR
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
                    });
                  } catch (e) {
                    // Si ocurre algún error al parsear
                    setState(() {
                      _qrResult = 'Error al procesar el QR: $e';
                    });
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Center(
                child: Text(
                  'Resultado del QR:\n$_qrResult',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
