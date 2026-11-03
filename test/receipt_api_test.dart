import 'dart:convert';

import 'package:exp_ocr/services/receipt_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _okBody = {
  'merchant': 'TESCO STORES SDN BHD',
  'total': 12.3,
  'currency': 'MYR',
  'date': '2019-02-01',
  'category': {'name': 'Food & Groceries', 'source': 'merchant', 'confidence': 0.95},
  'line_items': [],
  'raw_text': 'TESCO',
  'needs_review': false,
};

ReceiptApi _api(MockClientStreamHandler handler, {String? token = 'id-token'}) => ReceiptApi(
      baseUrl: Uri.parse('https://api.test'),
      client: MockClient.streaming(handler),
      tokenProvider: () async => token,
    );

Future<http.StreamedResponse> _json(int status, Object body, {Map<String, String> headers = const {}}) async =>
    http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(body))), status,
        headers: {'content-type': 'application/json', ...headers});

void main() {
  test('sends the image with the Firebase ID token and decodes the receipt', () async {
    late http.BaseRequest seen;
    final api = _api((req, body) async {
      seen = req;
      await body.drain<void>();
      return _json(200, _okBody);
    });

    final r = await api.scanBytes([1, 2, 3]);

    expect(seen.method, 'POST');
    expect(seen.url.toString(), 'https://api.test/v1/receipts/scan');
    expect(seen.headers['Authorization'], 'Bearer id-token');
    expect(seen.headers['content-type'], startsWith('multipart/form-data'));
    expect(r.total, 12.3);
    expect(r.date, DateTime(2019, 2, 1));
  });

  test('never calls the API without a signed-in user', () async {
    var called = false;
    final api = _api((req, body) async {
      called = true;
      return _json(200, _okBody);
    }, token: null);

    await expectLater(
        api.scanBytes([1]), throwsA(isA<ReceiptApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(called, isFalse);
  });

  test('maps rate limiting to a friendly message with retry time', () async {
    final api =
        _api((req, body) async => _json(429, {'detail': 'scan limit reached'}, headers: {'retry-after': '42'}));

    await expectLater(
      api.scanBytes([1]),
      throwsA(isA<ReceiptApiException>()
          .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 42))
          .having((e) => e.message, 'message', contains('42 seconds'))),
    );
  });

  test('surfaces the server detail for OCR failures', () async {
    final api = _api((req, body) async => _json(502, {'detail': 'could not read the receipt, try a clearer photo'}));

    await expectLater(
      api.scanBytes([1]),
      throwsA(isA<ReceiptApiException>()
          .having((e) => e.message, 'message', 'Could not read the receipt, try a clearer photo')),
    );
  });

  test('handles a non-JSON error page', () async {
    final api = _api(
        (req, body) async => http.StreamedResponse(Stream.value(utf8.encode('<html>Bad gateway</html>')), 502));

    await expectLater(
        api.scanBytes([1]), throwsA(isA<ReceiptApiException>().having((e) => e.statusCode, 'status', 502)));
  });

  test('maps network failures', () async {
    final api = _api((req, body) async => throw http.ClientException('connection refused'));

    await expectLater(api.scanBytes([1]),
        throwsA(isA<ReceiptApiException>().having((e) => e.message, 'message', contains('No connection'))));
  });
}
