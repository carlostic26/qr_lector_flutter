// Se usa un modelo de datos para representar el payload del QR.
// Se usa un parser secuencial EMVCo (tag → length → value).
// Se usa campos obligatorios principales (00, 01, 52, 58, 59, 60, 53, 54, 63).
// Se incluye soporte para subtags en el26, que es un template.
// Se guardan todos los campos en additionalFields → muy útil para depuración.
// El toString es para debug.

//Formato EMVCo = siempre [TAG][LENGTH][VALUE].
//web para generar payloads:

class EmvcoQrPayloadModel {
  final String payloadFormat; // Tag 00
  final String initiationMethod; // Tag 01
  final String merchantCategoryCode; // Tag 52
  final String countryCode; // Tag 58
  final String merchantName; // Tag 59
  final String merchantCity; // Tag 60
  final String currencyCode; // Tag 53
  final double transactionAmount; // Tag 54
  final String crc; // Tag 63
  final Map<String, dynamic> additionalFields; // campos extra (debug)

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
    final parsed = <String, String>{};
    int index = 0;

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

    // función para parsear templates
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

    final acquirerNetworkInfo =
        parsed.containsKey('49') ? parseTemplate(parsed['49']!) : {};

    // Validar que sea Redeban
    final gui = acquirerNetworkInfo['00'];
    final networkId = acquirerNetworkInfo['01'];

    if (gui != 'CO.COM.RBM.RED' && networkId != 'RBM') {
      throw const FormatException("QR inválido (no es de Redeban)");
    } else {
      //es Redeban, QR correcto
      //TODO: Llamar al validate para saber a que llave pertenece (tipo alias de tal persona, etc)
    }

    // Interpretar tipo de QR
    String initiationType(String? code, String? amount) {
      if (code == '12') return 'Dinámico';
      if (code == '11' && (double.tryParse(amount ?? '') ?? 0) > 0) {
        return 'Estático con valor';
      }
      return 'Estático';
    }

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
        if (acquirerNetworkInfo.isNotEmpty) '49_subtags': acquirerNetworkInfo,
      },
    );
  }
}
