import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});
  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  // Controlador del escáner configurado solo para detectar QR
  final MobileScannerController controller =
      MobileScannerController(formats: [BarcodeFormat.qrCode]);

  // Estado de la linterna
  bool _torchEnabled = false;

  // Texto inicial para mostrar resultado
  String _qrResult = 'Apunta al QR…';

  @override
  void dispose() {
    controller.dispose(); // Libera recursos del escáner al cerrar el widget
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
                _torchEnabled ? Icons.flashlight_on : Icons.flashlight_off),
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
                // Se ejecuta cada vez que se detecta un código
                final code = capture.barcodes.first.rawValue;
                if (code != null && mounted) {
                  // pausar escáner tras detectar para no leer varias veces seguidas :contentReference[oaicite:1]{index=1}
                  controller.stop();
                  setState(() {
                    _qrResult = code;
                  });
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Resultado del QR: $_qrResult',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
