import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// ── OcrResult ─────────────────────────────────────────────────────────────────

class OcrResult {
  final double? amount;
  final String? merchant;
  final String? date;
  final String rawText;

  const OcrResult({
    this.amount,
    this.merchant,
    this.date,
    required this.rawText,
  });

  bool get hasAmount => amount != null;
  bool get hasMerchant => merchant != null && merchant!.isNotEmpty;
  bool get hasDate => date != null && date!.isNotEmpty;
  bool get isEmpty => rawText.trim().isEmpty;
}

// ── OcrService ────────────────────────────────────────────────────────────────

/// OCR service that extracts amount, merchant and date from receipt images.
/// Uses [google_mlkit_text_recognition] for on-device text recognition and
/// [image_picker] for camera / gallery access.
class OcrService {
  final ImagePicker _picker = ImagePicker();

  // ── Amount patterns ──────────────────────────────────────────────────────

  // Matches: ₹ 1,234.56  |  Rs 1234.56  |  Rs. 1,234  |  INR 1234
  static final _amountPatterns = [
    // Rupee symbol immediately before the number
    RegExp(r'₹\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    // Rs. or Rs followed by number
    RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    // INR prefix
    RegExp(r'INR\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    // "Total" or "Amount" label on the same line as a number
    RegExp(
        r'(?:total|amount|grand\s+total|net\s+amount)\s*[:\-]?\s*(?:₹|Rs\.?|INR)?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false),
    // Bare number with optional decimals (fallback – only when no other match)
    RegExp(r'\b([0-9]{2,7}(?:\.[0-9]{1,2})?)\b'),
  ];

  // ── Date pattern ─────────────────────────────────────────────────────────

  static final _datePattern = RegExp(
    r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})\b',
  );

  // ── Lines that look like dates / times / numbers, not a merchant name ────

  static final _skipLinePattern = RegExp(
    r'^(?:\d|#|Invoice|Receipt|Bill|GST|GSTIN|PAN|UPI|Ref|Txn|Date|Time|Total|Amount|Balance|Change|Cash|Tax|CGST|SGST|IGST|Subtotal|Sub-total|Discount)',
    caseSensitive: false,
  );

  // ── Public API ───────────────────────────────────────────────────────────

  /// Opens the device camera and returns an [OcrResult] or `null` if the user
  /// cancels or an error occurs.
  Future<OcrResult?> scanFromCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) return null;

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    return _processImage(file);
  }

  /// Opens the gallery picker and returns an [OcrResult] or `null` if the user
  /// cancels or an error occurs.
  Future<OcrResult?> scanFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    return _processImage(file);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<OcrResult?> _processImage(XFile? file) async {
    if (file == null) return null;

    final inputImage = InputImage.fromFile(File(file.path));
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await recognizer.processImage(inputImage);
      return _parseText(recognized.text);
    } catch (_) {
      return null;
    } finally {
      recognizer.close();
    }
  }

  /// Parses raw OCR [text] and extracts the best-guess amount, merchant and
  /// date.
  OcrResult? _parseText(String text) {
    if (text.trim().isEmpty) {
      return OcrResult(rawText: text);
    }

    final amount = _extractAmount(text);
    final merchant = _extractMerchant(text);
    final date = _extractDate(text);

    return OcrResult(
      amount: amount,
      merchant: merchant,
      date: date,
      rawText: text,
    );
  }

  // ── Amount extraction ────────────────────────────────────────────────────

  double? _extractAmount(String text) {
    // Try each pattern in priority order; stop at the first concrete match
    // that doesn't use the bare-number fallback unless it's the only option.
    for (int i = 0; i < _amountPatterns.length - 1; i++) {
      final match = _amountPatterns[i].firstMatch(text);
      if (match != null) {
        final raw = match.group(1)?.replaceAll(',', '');
        final value = double.tryParse(raw ?? '');
        if (value != null && value > 0) return value;
      }
    }

    // Fallback: bare number pattern.  Prefer the *largest* number on the
    // assumption that it is the total.
    final matches = _amountPatterns.last.allMatches(text);
    double? best;
    for (final m in matches) {
      final raw = m.group(1)?.replaceAll(',', '');
      final value = double.tryParse(raw ?? '');
      if (value != null && (best == null || value > best)) {
        best = value;
      }
    }
    return best;
  }

  // ── Merchant extraction ──────────────────────────────────────────────────

  String? _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();

    // Walk lines from the top; the merchant / store name is usually among the
    // first few lines that do not look like a date, number or label.
    for (final line in lines.take(8)) {
      if (_skipLinePattern.hasMatch(line)) continue;
      // Skip lines that are almost entirely digits or punctuation.
      final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (letters.length < 3) continue;
      return _toTitleCase(line);
    }
    return null;
  }

  // ── Date extraction ──────────────────────────────────────────────────────

  String? _extractDate(String text) {
    final match = _datePattern.firstMatch(text);
    return match?.group(1);
  }

  // ── Utility ─────────────────────────────────────────────────────────────

  String _toTitleCase(String s) => s
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
