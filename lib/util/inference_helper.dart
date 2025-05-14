import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class InferenceHelper {
  late Interpreter interpreter;
  late List<String> labels;
  late Map<String, int> wordIndex;

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/tflite/model.tflite');

    // Load labels
    final labelsData = await rootBundle.loadString('assets/tflite/labels.txt');
    labels = labelsData.split('\n').map((e) => e.trim()).toList();

    // Load word index map
    final jsonString = await rootBundle.loadString('assets/tflite/word_index.json');
    wordIndex = Map<String, int>.from(json.decode(jsonString));
  }

  List<int> tokenize(String text, {int maxLen = 20}) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    List<int> tokens = [];

    for (var word in words) {
      tokens.add(wordIndex[word] ?? 0);
    }

    if (tokens.length > maxLen) {
      tokens = tokens.sublist(0, maxLen);
    } else {
      while (tokens.length < maxLen) {
        tokens.add(0);
      }
    }

    return tokens;
  }

  String predictCategory(String text) {
    final input = [tokenize(text)];
    var output = List.filled(labels.length, 0.0).reshape([1, labels.length]);

    interpreter.run(input, output);

    final prediction = output[0];
    final maxIndex = prediction.indexWhere((val) => val == prediction.reduce((a, b) => a > b ? a : b));
    return labels[maxIndex];
  }
}
