import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:exp_ocr/util/receipt_parser.dart';

Future<File> preprocessImage(File file) async {
  final bytes = await file.readAsBytes();
  final originalImage = img.decodeImage(bytes);
  final grayscale = img.grayscale(originalImage!);
  final highContrast = img.adjustColor(grayscale, contrast: 1.2);
  final processedBytes = img.encodeJpg(highContrast);
  final processedFile = await File(file.path).writeAsBytes(processedBytes);
  return processedFile;
}

class ScanReceiptScreen extends StatefulWidget {
  @override
  _ScanReceiptScreenState createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  File? _image;
  String _extractedText = '';
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();
  final String ocrApiKey = 'K82571272088957'; // ✅ Your OCR.Space API key

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _extractedText = '';
      });
      _uploadImageToOCRSpace(_image!);
    }
  }

  Future<void> _uploadImageToOCRSpace(File imageFile) async {
    setState(() => _loading = true);
    final ImagePicker _picker = ImagePicker();
    File? _image;

    Future<void> pickAndProcessImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        _image = File(pickedFile.path);
        final preprocessed = await preprocessImage(_image!);
        await _uploadImageToOCRSpace(preprocessed);
      } else {
        print('No image selected.');
      }
    }

    final uri = Uri.parse("https://api.ocr.space/parse/image");
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['apikey'] = ocrApiKey
          ..fields['language'] = 'eng'
          ..fields['isOverlayRequired'] = 'false'
          ..fields['OCREngine'] =
              '2' // Better accuracy
          ..fields['scale'] =
              'true' // Enhance small fonts
          ..fields['isTable'] =
              'true' // Handle receipt layout
          ..fields['detectOrientation'] =
              'true' // Auto-rotate fix
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    try {
      final response = await request.send();
      final result = await http.Response.fromStream(response);

      final jsonData = json.decode(result.body);
      if (jsonData['IsErroredOnProcessing'] == false) {
        final parsedText = jsonData['ParsedResults'][0]['ParsedText'];
        final parsedDetails = extractDataFromReceipt(parsedText.trim());
        print("Parsed Data: $parsedDetails");

        setState(() {
          _extractedText = '''
Vendor: ${parsedDetails['vendor']}
Amount: ${parsedDetails['amount']}
Date: ${parsedDetails['date']}
Category: ${parsedDetails['category']}
---
Raw Text:
${parsedText.trim()}
''';
        });
        ;
      } else {
        setState(
          () => _extractedText = 'OCR failed: ${jsonData['ErrorMessage']}',
        );
      }
    } catch (e) {
      setState(() => _extractedText = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImagePicker _picker = ImagePicker();
    File? _image;

    Future<void> pickAndProcessImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        _image = File(pickedFile.path);
        final preprocessed = await preprocessImage(_image!);
        await _uploadImageToOCRSpace(preprocessed);
      } else {
        print('No image selected.');
      }
    }

    ElevatedButton(onPressed: pickAndProcessImage, child: Text('Scan Receipt'));
    return Scaffold(
      appBar: AppBar(title: Text("Scan Receipt")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 200),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text("Gallery"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _loading
                ? CircularProgressIndicator()
                : Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _extractedText.isEmpty
                          ? "Scanned text will appear here"
                          : _extractedText,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
