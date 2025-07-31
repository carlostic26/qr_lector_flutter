// Se usa un modelo de datos para representar el payload del QR.
// Se usa un parser secuencial EMVCo (tag → length → value).
// Se usa campos obligatorios principales (00, 01, 52, 58, 59, 60, 53, 54, 63).
// Se incluye soporte para subtags en el26, que es un template.
// Se guardan todos los campos en additionalFields → muy útil para depuración.
// El toString es para debug.

//Formato EMVCo = siempre [TAG][LENGTH][VALUE].
//web para generar payloads:

class EmvcoQrPayloadModel {
  final String
      payloadFormat; //Tag 00: versión del estándar EMVCo (siempre "01")
  final String
      initiationMethod; //Tag 01: indica si el QR es Estático, Dinámico o Estático con valor
  final String
      merchantCategoryCode; //Tag 52: código MCC (categoría de comercio según ISO 18245)
  final String
      countryCode; //Tag 58: país en formato ISO 3166-1 alfa-2 (ej: "CO")
  final String merchantName; //Tag 59: nombre del comercio
  final String merchantCity; //Tag 60: ciudad donde está registrado el comercio
  final String
      currencyCode; //Tag 53: moneda en formato ISO 4217 (ej: COP = 170)
  final double
      transactionAmount; //Tag 54: monto de la transacción (puede ser 0 en QR estáticos)
  final String crc; //Tag 63: CRC de validación (checksum del QR)
  final Map<String, dynamic>
      additionalFields; // Campos adicionales no mapeados directamente (incluye subtags como el Tag 26)

  EmvcoQrPayloadModel({
    required this.payloadFormat,
    required this.initiationMethod,
    required this.merchantCategoryCode,
    required this.countryCode,
    required this.merchantName,
    required this.merchantCity,
    required this.currencyCode,
    required this.transactionAmount,
    required this.crc,
    this.additionalFields = const {},
  });

  factory EmvcoQrPayloadModel.fromPayload(String payload) {
    // Map de guardado
    final parsed = <String, String>{};
    int index = 0;

    // Mientras queden al menos 4 caracteres por leer: (tag + length)
    while (index + 4 <= payload.length) {
      final id = payload.substring(index, index + 2);
      index += 2;

      final lenText = payload.substring(index, index + 2);
      final len = int.tryParse(lenText);
      if (len == null) {
        throw FormatException(
            '\nPayload: $payload\nLongitud inválida "$lenText" en posición $index para tag $id');
      }
      index += 2;

      if (index + len > payload.length) {
        throw FormatException(
            '\nPayload: $payload\nValor para tag $id excede longitud al final del payload');
      }

      final value = payload.substring(index, index + len);
      index += len;

      parsed[id] = value;
    }

    // Función auxiliar para parsear "templates": subtags dentro del valor (ej. Tag 26)
    Map<String, String> parseTemplate(String raw) {
      final map = <String, String>{};
      int idx = 0;
      while (idx + 4 <= raw.length) {
        final subId = raw.substring(idx, idx + 2);
        idx += 2;
        final subLen = int.tryParse(raw.substring(idx, idx + 2));
        if (subLen == null) {
          throw FormatException('Sub-length inválida para subtag $subId');
        }
        idx += 2;
        if (idx + subLen > raw.length) {
          throw FormatException('Valor subtag $subId excede longitud');
        }
        final subVal = raw.substring(idx, idx + subLen);
        idx += subLen;
        map[subId] = subVal;
      }
      return map;
    }

    final merchantAccountInfo =
        parsed.containsKey('26') ? parseTemplate(parsed['26']!) : {};

    // interpretar el tipo de QR según Tag 01 y el monto (Tag 54)
    String initiationType(String? code, String? amount) {
      if (code == '12') return 'Dinámico';
      if (code == '11' && (double.tryParse(amount ?? '') ?? 0) > 0) {
        return 'Estático con valor';
      }
      return 'Estático';
    }

    // Limpiar posibles caracteres no numéricos del monto
    final rawAmt = parsed['54'] ?? '';
    final cleanAmt = rawAmt.replaceAll(RegExp(r'[^0-9.]'), '');
    final amt = double.tryParse(cleanAmt) ?? 0.0;

    return EmvcoQrPayloadModel(
      payloadFormat: parsed['00'] ?? '',
      initiationMethod: initiationType(parsed['01'], parsed['54']),
      merchantCategoryCode: parsed['52'] ?? '',
      countryCode: parsed['58'] ?? '',
      merchantName: parsed['59'] ?? '',
      merchantCity: parsed['60'] ?? '',
      currencyCode: parsed['53'] ?? '',
      transactionAmount: amt,
      crc: parsed['63'] ?? '',
      additionalFields: {
        ...parsed,
        if (merchantAccountInfo.isNotEmpty) '26_subtags': merchantAccountInfo,
      },
    );
  }
}
