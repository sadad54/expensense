import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/scanned_receipt.dart';

typedef TokenProvider = Future<String?> Function();

class ReceiptApiException implements Exception {
  final int? statusCode;
  final String message;
  final Duration? retryAfter;

  const ReceiptApiException(this.message, {this.statusCode, this.retryAfter});

  @override
  String toString() => message;
}

/// Client for the ExpenSense receipt API.
///
/// OCR runs on the server, so the OCR key never ships inside the app. Every
/// request carries the signed-in user's Firebase ID token.
class ReceiptApi {
  final Uri baseUrl;
  final http.Client _client;
  final TokenProvider _token;
  final Duration timeout;

  ReceiptApi({
    required this.baseUrl,
    http.Client? client,
    TokenProvider? tokenProvider,
    this.timeout = const Duration(seconds: 45),
  })  : _client = client ?? http.Client(),
        _token = tokenProvider ?? _firebaseIdToken;

  static Future<String?> _firebaseIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? null : await user.getIdToken();
  }

  factory ReceiptApi.fromEnv() {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw const ReceiptApiException('API_BASE_URL is not set in assets/.env');
    }
    return ReceiptApi(baseUrl: Uri.parse(url));
  }

  Future<ScannedReceipt> scan(File image) async {
    return scanBytes(await image.readAsBytes(), filename: image.uri.pathSegments.last);
  }

  Future<ScannedReceipt> scanBytes(List<int> bytes, {String filename = 'receipt.jpg'}) async {
    final token = await _token();
    if (token == null) {
      throw const ReceiptApiException('Please sign in again.', statusCode: 401);
    }
    final request = http.MultipartRequest('POST', baseUrl.resolve('/v1/receipts/scan'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: filename, contentType: MediaType('image', 'jpeg')));
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout));
    } on TimeoutException {
      throw const ReceiptApiException('The server took too long. Try again.');
    } on SocketException {
      throw const ReceiptApiException('No connection to the server. Check your internet.');
    } on http.ClientException {
      throw const ReceiptApiException('No connection to the server. Check your internet.');
    }
    return _decode(response);
  }

  ScannedReceipt _decode(http.Response response) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ReceiptApiException('Unexpected server response.', statusCode: response.statusCode);
    }
    if (response.statusCode == 200) return ScannedReceipt.fromJson(body);

    final raw = body['detail'];
    final detail = raw is String && raw.isNotEmpty ? raw : 'something went wrong.';
    final retry = int.tryParse(response.headers['retry-after'] ?? '');
    throw ReceiptApiException(
      switch (response.statusCode) {
        401 => 'Please sign in again.',
        429 => 'Too many scans in a row. Try again in ${retry ?? 60} seconds.',
        _ => detail[0].toUpperCase() + detail.substring(1),
      },
      statusCode: response.statusCode,
      retryAfter: retry == null ? null : Duration(seconds: retry),
    );
  }
}
