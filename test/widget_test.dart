import 'package:flutter_test/flutter_test.dart';
import 'package:test_qr/model.dart';

void main() {
  group('EmvcoQrPayloadModel.fromPayload', () {
    test('parses un QR estático sin subtags', () {
      const payload =
          '000201115203531530317054060012345802CO5907MiTienda6006Cucuta6304ABCD';
      final model = EmvcoQrPayloadModel.fromPayload(payload);
      expect(model.payloadFormat, '01');
      expect(model.initiationMethod, 'Estático con valor');
      expect(model.currencyCode, '170');
      expect(model.transactionAmount, 1234.0);
      expect(model.countryCode, 'CO');
      expect(model.merchantCity, 'Cucuta');
      expect(model.crc, 'ABCD');
    });

    test('identifica QR dinámico con monto y subtags en 26', () {
      const payload = '0002010126...'; // incluye Tag 26 template
      final model = EmvcoQrPayloadModel.fromPayload(payload);
      expect(model.initiationMethod, 'Dinámico');
      expect(model.additionalFields['26_subtags'], isA<Map<String, String>>());
    });

    test('falla si el payload está mal formado o length no coincide', () {
      expect(() => EmvcoQrPayloadModel.fromPayload('XX'),
          throwsA(isA<FormatException>()));
    });
  });
}
