import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Selector de archivos en Web/Desktop
import 'package:image/image.dart'
    as img; // Parseo de imagen JPG/PNG a matriz RGBA
import 'package:qr_code_vision/qr_code_vision.dart'; // QR‑reader puro Dart para Web/Desktop
import 'model.dart'; // Tu modelo EmvcoQrPayloadModel

//el metodo para mobile esta en home y es con el paquete mobile_scanner

/// Método para desktop/web: abrir galería, decodificar imagen como RGBA, buscar QR y procesar
Future<void> scanQrFromDesktop() async {
  try {
    // 1️⃣ Abrir selector de archivos (imagen desde disco / galería en desktop/web)
    final XFile? x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (x == null) {
      debugPrint('❌ Usuario canceló');
      return;
    }

    final bytes = await x.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('❌ No se pudo decodificar imagen');
      return;
    }

    final Uint8List rgba = image.getBytes(order: img.ChannelOrder.rgba);
    final int w = image.width, h = image.height;

    final qrcode = QrCode();
    qrcode.scanRgbaBytes(rgba, w, h); // SIN asignar retorno

    final String? txt = qrcode.content?.text;
    if (txt == null || txt.isEmpty) {
      debugPrint('⚠️ QR no detectado o texto vacío');
      return;
    }

    final payload = txt;
    try {
      final parsed = EmvcoQrPayloadModel.fromPayload(payload);
      debugPrint('✅ OK PAYLOAD: $payload');
      debugPrint(parsed.toString());
    } on FormatException catch (e) {
      debugPrint('❌ Payload inválido/No Redeban: $e');
    }
  } catch (e) {
    debugPrint('⚠️ Error en scanQrFromDesktop(): $e');
  }
}
