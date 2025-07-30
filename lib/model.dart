// Se usa un modelo de datos para representar el payload del QR.
// Se usa un parser secuencial EMVCo (tag → length → value).
// Se usa campos obligatorios principales (00, 01, 52, 58, 59, 60, 53, 54, 63).
// Se incluye soporte para subtags en el26, que es un template.
// Se guardan todos los campos en additionalFields → muy útil para depuración.
// El toString es para debug.

//Formato EMVCo = siempre [TAG][LENGTH][VALUE].
//web para generar payloads: https://www.omqrc.com/emvco-qr-code-generator

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

    // Mientras queden al menos 4 caracteres por leer:
    // (2 para el tag y 2 para la length).
    while (index + 4 <= payload.length) {
      final id = payload.substring(index, index + 2);
      index += 2;

      final len = int.parse(payload.substring(index, index + 2));
      index += 2;

      // Value: el contenido real del campo, cuya longitud depende de [len]
      final value = payload.substring(index, index + len);
      index += len;

      parsed[id] = value;
    }

    // Función auxiliar para parsear "templates":
    // Son valores que dentro de sí contienen subtags (ejemplo: Tag 26)
    Map<String, String> parseTemplate(String raw) {
      final map = <String, String>{};
      int idx = 0;

      // Misma lógica anterior, pero aplicada dentro del valor de un tag
      while (idx + 4 <= raw.length) {
        final subId = raw.substring(idx, idx + 2); // Subtag (2 caracteres)
        idx += 2;

        final subLen =
            int.parse(raw.substring(idx, idx + 2)); // Longitud del valor
        idx += 2;

        final subVal =
            raw.substring(idx, idx + subLen); // Valor real del subtag
        idx += subLen;

        map[subId] = subVal;
      }
      return map;
    }

    // el Tag 26 es un caso particular dentro de la especificación EMVCo
    // Ej: parsear el Tag 26 (Merchant Account Info) en caso de que exista
    final merchantAccountInfo =
        parsed.containsKey('26') ? parseTemplate(parsed['26']!) : {};

    // interpretar el tipo de QR según el Tag 01 y el monto (Tag 54)
    String initiationType(String? code, String? amount) {
      if (code == '12') return 'Dinámico'; // QR dinámico
      if (code == '11' && (double.tryParse(amount ?? '0') ?? 0) > 0) {
        return 'Estático con valor';
      }
      return 'Estático';
    }

    return EmvcoQrPayloadModel(
      payloadFormat: parsed['00'] ?? '',
      initiationMethod:
          initiationType(parsed['01'], parsed['54']), // Tag 01 + lógica
      merchantCategoryCode: parsed['52'] ?? '',
      countryCode: parsed['58'] ?? '',
      merchantName: parsed['59'] ?? '',
      merchantCity: parsed['60'] ?? '',
      currencyCode: parsed['53'] ?? '',
      transactionAmount: double.tryParse(parsed['54'] ?? '0') ?? 0.0,
      crc: parsed['63'] ?? '',
      additionalFields: {
        ...parsed, // Se incluyen todos los tags parseados
        if (merchantAccountInfo.isNotEmpty) '26_subtags': merchantAccountInfo,
        // Se guarda también los subtags del Tag 26 si existen
      },
    );
  }

  @override
  String toString() {
    return '''
    EmvcoQrPayloadModel(
      payloadFormat: $payloadFormat,
      initiationMethod: $initiationMethod,
      merchantCategoryCode: $merchantCategoryCode,
      countryCode: $countryCode,
      merchantName: $merchantName,
      merchantCity: $merchantCity,
      currencyCode: $currencyCode,
      transactionAmount: $transactionAmount,
      crc: $crc,
      additionalFields: $additionalFields,
    )''';
  }
}
