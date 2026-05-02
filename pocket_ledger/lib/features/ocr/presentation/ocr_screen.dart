import 'package:flutter/material.dart';

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: const Center(child: Text('OCR — Coming Soon')),
    );
  }
}
