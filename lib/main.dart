import 'package:flutter/material.dart';

import 'package:test_qr/home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba de Escáner QR',
      theme: ThemeData(useMaterial3: true),
      home: const QRScanPage(),
    );
  }
}
