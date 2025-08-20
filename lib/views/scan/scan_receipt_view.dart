import 'dart:convert';
import 'dart:io';
import 'package:exp_ocr/util/category_hybrid_matcher.dart';
import 'package:exp_ocr/util/receipt_parser.dart';
import 'package:exp_ocr/util/transaction_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:exp_ocr/viewmodels/tax_category_notifier.dart';

Future<File> preprocessImage(File file) async {
  final bytes = await file.readAsBytes();
  final originalImage = img.decodeImage(bytes);
  if (originalImage == null) return file;
  final grayscale = img.grayscale(originalImage);
  final resized = img.copyResize(
    grayscale,
    width: 1024,
  ); // Optional but recommended
  final highContrast = img.adjustColor(resized, contrast: 1.2);

  final processedBytes = img.encodeJpg(highContrast);

  final directory = file.parent;
  final fileName = file.path.split(Platform.pathSeparator).last;
  final newPath =
      '${directory.path}/${fileName.split('.').first}_processed.jpg';

  final processedFile = File(newPath);
  await processedFile.writeAsBytes(processedBytes);
  return processedFile;
}

// Ensure the image file is smaller than the OCR API limit (1 MB)
// by adaptively lowering JPEG quality and, if needed, scaling down.
Future<File> _compressUnderLimit(
  File file, {
  int maxBytes = 1000 * 1024,
}) async {
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return file;

  img.Image image = img.bakeOrientation(decoded);
  int quality = 85;
  int currentWidth = image.width;

  List<int> jpg = img.encodeJpg(image, quality: quality);

  while (jpg.length > maxBytes) {
    if (quality > 55) {
      quality -= 10;
    } else {
      // Reduce dimensions when quality is already low
      currentWidth = (currentWidth * 0.85).floor();
      if (currentWidth < 800) break; // safety bound
      final scale = currentWidth / image.width;
      image = img.copyResize(
        image,
        width: currentWidth,
        height: (image.height * scale).floor(),
      );
      quality = 80; // bump quality a bit after resizing
    }
    jpg = img.encodeJpg(image, quality: quality);
  }

  final out = await file.rename('${file.path}.tmp');
  final newFile = File(file.path);
  await newFile.writeAsBytes(jpg, flush: true);
  // best effort cleanup
  if (await out.exists()) {
    try {
      await out.delete();
    } catch (_) {}
  }
  return newFile;
}

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  File? _image;
  String _extractedText = '';
  bool _loading = false;
  String _statusMessage = '';

  final ImagePicker _picker = ImagePicker();
  final String ocrApiKey = dotenv.env['OCR_API_KEY'] ?? '';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _extractedText = '';
          _statusMessage = 'Processing image...';
        });
        final preprocessed = await preprocessImage(_image!);
        final bounded = await _compressUnderLimit(preprocessed);
        await _uploadImageToOCRSpace(bounded);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking image: $e';
        _loading = false;
      });
    }
  }

  Future<void> _uploadImageToOCRSpace(File imageFile) async {
    setState(() {
      _loading = true;
      _statusMessage = 'Uploading to OCR and parsing...';
    });

    final uri = Uri.parse("https://api.ocr.space/parse/image");
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['apikey'] = ocrApiKey
          ..fields['language'] = 'eng'
          ..fields['isOverlayRequired'] = 'false'
          ..fields['OCREngine'] = '2'
          ..fields['scale'] = 'true'
          ..fields['isTable'] = 'true'
          ..fields['detectOrientation'] = 'true'
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    try {
      final response = await request.send();
      var result = await http.Response.fromStream(response);

      print('🛰️ OCR Response Code: ${result.statusCode}');
      print('📥 OCR Raw Body: ${result.body}');

      // If still too large, compress further and retry once
      final bodyLower = result.body.toLowerCase();
      final isTooBig =
          result.statusCode == 413 ||
          bodyLower.contains('file size limit') ||
          bodyLower.contains('file too large') ||
          bodyLower.contains('exceeds the maximum permissible file size');
      if (isTooBig) {
        setState(() {
          _statusMessage = 'Optimizing image size...';
        });
        final tighter = await _compressUnderLimit(
          imageFile,
          maxBytes: 900 * 1024,
        );
        final retryReq =
            http.MultipartRequest('POST', uri)
              ..fields['apikey'] = ocrApiKey
              ..fields['language'] = 'eng'
              ..fields['isOverlayRequired'] = 'false'
              ..fields['OCREngine'] = '2'
              ..fields['scale'] = 'true'
              ..fields['isTable'] = 'true'
              ..fields['detectOrientation'] = 'true'
              ..files.add(
                await http.MultipartFile.fromPath('file', tighter.path),
              );
        final retryStream = await retryReq.send();
        final retryResult = await http.Response.fromStream(retryStream);
        print('🛰️ OCR Retry Response Code: ${retryResult.statusCode}');
        print('📥 OCR Retry Raw Body: ${retryResult.body}');
        final retryJson = json.decode(retryResult.body);
        if (retryJson['IsErroredOnProcessing'] == false &&
            retryJson['ParsedResults'] != null &&
            retryJson['ParsedResults'].isNotEmpty) {
          final parsedText = retryJson['ParsedResults'][0]['ParsedText'] ?? '';
          final parsedDetails = extractDataFromReceipt(parsedText.trim());
          String transactionCategoryName = hybridCategoryMatch(
            parsedText.trim(),
          );
          if (transactionCategoryName == "Uncategorized") {
            final pickedCategory = await _showTransactionCategoryPicker(
              context,
            );
            if (pickedCategory != null) {
              transactionCategoryName = pickedCategory;
            } else {
              setState(() {
                _extractedText = 'Raw Text:\n${parsedText.trim()}';
                _statusMessage = '⚠️ Transaction Uncategorized.';
                _loading = false;
              });
              return;
            }
          }
          final amount =
              double.tryParse(
                parsedDetails['amount'].toString().replaceAll(
                  RegExp(r'[^0-9.]'),
                  '',
                ),
              ) ??
              0.0;
          setState(() {
            _extractedText =
                'Vendor: ${parsedDetails['vendor']}\nAmount: \$${amount.toStringAsFixed(2)}\nDate: ${parsedDetails['date']}\nCategory: $transactionCategoryName\n---\nRaw Text:\n${parsedText.trim()}';
            _statusMessage = '✅ Scan successful!';
          });
          if (transactionCategoryName != "Uncategorized" && amount > 0) {
            await saveTransactionAndUpdateBudget(
              context: context,
              categoryName: transactionCategoryName,
              amount: amount,
              rawText: parsedText.trim(),
              timestamp:
                  DateTime.tryParse(parsedDetails['date'] ?? '') ??
                  DateTime.now(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✅ \$${amount.toStringAsFixed(2)} logged under '$transactionCategoryName'",
                ),
              ),
            );
            if (_isIncomeTaxRelevant(transactionCategoryName)) {
              Provider.of<TaxCategoryNotifier>(
                context,
                listen: false,
              ).refresh();
            }
          }
          return;
        } else {
          // fall through to normal error handling with retry payload
          result = retryResult;
        }
      }

      final jsonData = json.decode(result.body);

      if (jsonData['IsErroredOnProcessing'] == false &&
          jsonData['ParsedResults'] != null &&
          jsonData['ParsedResults'].isNotEmpty) {
        final parsedText = jsonData['ParsedResults'][0]['ParsedText'] ?? '';
        final parsedDetails = extractDataFromReceipt(parsedText.trim());

        String transactionCategoryName = hybridCategoryMatch(parsedText.trim());

        if (transactionCategoryName == "Uncategorized") {
          final pickedCategory = await _showTransactionCategoryPicker(context);
          if (pickedCategory != null) {
            transactionCategoryName = pickedCategory;
          } else {
            setState(() {
              _extractedText = 'Raw Text:\n${parsedText.trim()}';
              _statusMessage = '⚠️ Transaction Uncategorized.';
              _loading = false;
            });
            return;
          }
        }

        final amount =
            double.tryParse(
              parsedDetails['amount'].toString().replaceAll(
                RegExp(r'[^0-9.]'),
                '',
              ),
            ) ??
            0.0;

        setState(() {
          _extractedText = '''
Vendor: ${parsedDetails['vendor']}
Amount: \$${amount.toStringAsFixed(2)}
Date: ${parsedDetails['date']}
Category: $transactionCategoryName
---
Raw Text:
${parsedText.trim()}
''';
          _statusMessage = '✅ Scan successful!';
        });

        if (transactionCategoryName != "Uncategorized" && amount > 0) {
          await saveTransactionAndUpdateBudget(
            context: context,
            categoryName: transactionCategoryName,
            amount: amount,
            rawText: parsedText.trim(),
            timestamp:
                DateTime.tryParse(parsedDetails['date'] ?? '') ??
                DateTime.now(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "✅ \$${amount.toStringAsFixed(2)} logged under '$transactionCategoryName'",
              ),
            ),
          );
          if (_isIncomeTaxRelevant(transactionCategoryName)) {
            Provider.of<TaxCategoryNotifier>(context, listen: false).refresh();
          }
        }
      } else {
        setState(() {
          _statusMessage = '❌ OCR failed to extract text.';
          _extractedText = 'Raw Response:\n${result.body}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error processing receipt: $e';
        _extractedText = '⚠️ Check your internet connection or image format.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  //   Future<void> _uploadImageToOCRSpace(File imageFile) async {
  //     setState(() {
  //       _loading = true;
  //       _statusMessage = 'Uploading to OCR and parsing...';
  //     });

  //     final uri = Uri.parse("https://api.ocr.space/parse/image");
  //     final request =
  //         http.MultipartRequest('POST', uri)
  //           ..headers['apikey'] = ocrApiKey
  //           ..fields['language'] = 'eng'
  //           ..fields['isOverlayRequired'] = 'false'
  //           ..fields['OCREngine'] = '2'
  //           ..fields['scale'] = 'true'
  //           ..fields['isTable'] = 'true'
  //           ..fields['detectOrientation'] = 'true'
  //           ..files.add(
  //             await http.MultipartFile.fromPath('file', imageFile.path),
  //           );

  //     try {
  //       final response = await request.send();
  //       final result = await http.Response.fromStream(response);
  //       final jsonData = json.decode(result.body);

  //       if (jsonData['IsErroredOnProcessing'] == false &&
  //           jsonData['ParsedResults'] != null &&
  //           jsonData['ParsedResults'].isNotEmpty) {
  //         final parsedText = jsonData['ParsedResults'][0]['ParsedText'] ?? '';
  //         final parsedDetails = extractDataFromReceipt(parsedText.trim());

  //         String transactionCategoryName = hybridCategoryMatch(parsedText.trim());

  //         if (transactionCategoryName == "Uncategorized") {
  //           final pickedCategory = await _showTransactionCategoryPicker(context);
  //           if (pickedCategory != null) {
  //             transactionCategoryName = pickedCategory;
  //           } else {
  //             setState(() {
  //               _extractedText = 'Raw Text:\n${parsedText.trim()}';
  //               _statusMessage = '⚠️ Transaction Uncategorized.';
  //               _loading = false;
  //             });
  //             return;
  //           }
  //         }

  //         final amount =
  //             double.tryParse(
  //               parsedDetails['amount'].toString().replaceAll(
  //                 RegExp(r'[^0-9.]'),
  //                 '',
  //               ),
  //             ) ??
  //             0.0;

  //         setState(() {
  //           _extractedText = '''
  // Vendor: ${parsedDetails['vendor']}
  // Amount: \$${amount.toStringAsFixed(2)}
  // Date: ${parsedDetails['date']}
  // Category: $transactionCategoryName
  // ---
  // Raw Text:
  // ${parsedText.trim()}
  // ''';
  //           _statusMessage = 'Scan successful!';
  //         });

  //         if (transactionCategoryName != "Uncategorized" && amount > 0) {
  //           await saveTransactionAndUpdateBudget(
  //             context: context,
  //             categoryName: transactionCategoryName,
  //             amount: amount,
  //             rawText: parsedText.trim(),
  //             timestamp:
  //                 DateTime.tryParse(parsedDetails['date'] ?? '') ??
  //                 DateTime.now(),
  //           );

  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(
  //               content: Text(
  //                 "✅ \$${amount.toStringAsFixed(2)} logged under '$transactionCategoryName'",
  //               ),
  //             ),
  //           );
  //         }
  //       } else {
  //         setState(() => _statusMessage = '❌ OCR failed to extract text.');
  //       }
  //     } catch (e) {
  //       setState(() => _statusMessage = '❌ Error processing receipt: $e');
  //     } finally {
  //       setState(() => _loading = false);
  //     }
  //   }

  Future<String?> _showTransactionCategoryPicker(BuildContext context) async {
    const List<String> transactionCategories = [
      "Food & Groceries",
      "Dining & Takeout",
      "Transportation",
      "Utilities",
      "Housing & Rent",
      "Health & Personal Care",
      "Entertainment & Subscriptions",
      "Shopping & Miscellaneous",
      "Other Expense",
    ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Transaction Category",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListView(
                shrinkWrap: true,
                children:
                    transactionCategories
                        .map(
                          (cat) => ListTile(
                            leading: Icon(
                              Icons.label_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(cat),
                            onTap: () => Navigator.of(context).pop(cat),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Receipt")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_image != null && _image!.existsSync())
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, fit: BoxFit.contain),
                  ),
                )
              else if (_image != null)
                const Text(
                  "⚠️ Failed to load image preview.",
                  style: TextStyle(color: Colors.redAccent),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Center(
                    child: Text(
                      "Image preview will appear here",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _loading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _loading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),

              SizedBox(
                height: 260,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _extractedText.isNotEmpty
                          ? SingleChildScrollView(
                            child: Text(
                              _extractedText,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          )
                          : const Center(
                            child: Text(
                              "Scanned details will appear here.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isIncomeTaxRelevant(String category) {
  return [
    "Food & Groceries",
    "Dining & Takeout",
    "Transportation",
    "Utilities",
    "Housing & Rent",
    "Health & Personal Care",
    "Entertainment & Subscriptions",
    "Shopping & Miscellaneous",
  ].contains(category);
}
