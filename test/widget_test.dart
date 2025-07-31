import 'package:flutter_test/flutter_test.dart';
import 'package:test_qr/model.dart';

void main() {
  group('EmvcoQrPayloadModel.fromPayload', () {
    test('parsea QR estático con monto (payload Colombia válido)', () {
      const payload =
          '000201115203531530317054060012345802CO5907MiTienda6006Cucuta6304ABCD';
      final model = EmvcoQrPayloadModel.fromPayload(payload);

      expect(model.payloadFormat, '01');
      expect(model.initiationMethod, 'Estático con valor');
      expect(model.merchantCategoryCode, '531');
      expect(model.currencyCode, '170');
      expect(model.transactionAmount, 1234.0);
      expect(model.countryCode, 'CO');
      expect(model.merchantName, 'MiTienda');
      expect(model.merchantCity, 'Cucuta');
      expect(model.crc, 'ABCD');

      // Revisa que additionalFields contenga los tags originales
      expect(model.additionalFields['54'], '001234');
      expect(model.additionalFields.containsKey('26'), false);
      expect(model.additionalFields.containsKey('26_subtags'), false);
    });

    test('parsea QR dinámico con subtags en Tag 26', () {
      // Tag 26 con subtags 00="AB12", 02="CD"
      const payload = '00020112' +
          '520353015305170540600090' +
          '5802CO' +
          '5907MiTienda' +
          '6006Bogota' +
          '26' +
          '08' +
          '0004AB120102CD' +
          '63' +
          '04' +
          'EEEE';
      final model = EmvcoQrPayloadModel.fromPayload(payload);

      expect(model.initiationMethod, 'Dinámico');
      expect(model.transactionAmount, 900.0);

      final subtags = model.additionalFields['26_subtags'];
      expect(subtags, isA<Map<String, String>>());
      expect((subtags as Map<String, String>)['00'], 'AB12');
      expect(subtags['02'], 'CD');
    });

    test('lanza FormatException si falta monto (Tag 54)', () {
      // payload sin tag 54
      const payload =
          '00020111520353153031705802CO5907MiTienda6006Cucuta6304FFFF';
      expect(() => EmvcoQrPayloadModel.fromPayload(payload),
          throwsA(isA<FormatException>()));
    });

    test('lanza FormatException si length no es numérico', () {
      const payload = '0002XX2A'; // longitud "XX"
      expect(() => EmvcoQrPayloadModel.fromPayload(payload),
          throwsA(isA<FormatException>()));
    });

    test('lanza FormatException si valor excede longitud del payload', () {
      const payload = '00020102' // tag 00 len02
          '01' // valor "01"
          '01' // tag 01
          '05' // len=5 pero no hay más caracteres
          'ABC';
      expect(() => EmvcoQrPayloadModel.fromPayload(payload),
          throwsA(isA<FormatException>()));
    });
  });
}
