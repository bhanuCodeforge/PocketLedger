import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../services/ocr_service.dart';

// ── OcrScreen ─────────────────────────────────────────────────────────────────

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _service = OcrService();

  bool _isScanning = false;
  OcrResult? _result;
  String? _imagePath;
  bool _rawExpanded = false;

  // ── Scanning ─────────────────────────────────────────────────────────────

  Future<void> _scanCamera() => _scan(() => _service.scanFromCamera());
  Future<void> _scanGallery() => _scan(() => _service.scanFromGallery());

  Future<void> _scan(Future<OcrResult?> Function() source) async {
    setState(() {
      _isScanning = true;
      _result = null;
      _imagePath = null;
      _rawExpanded = false;
    });

    try {
      final result = await source();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _result = result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _useResult() {
    if (_result == null) return;
    // Pass the OCR result as router extra to AddExpenseScreen.
    context.push('/expenses/add', extra: {
      'ocr_amount': _result!.amount,
      'ocr_note': _result!.merchant ?? '',
    });
  }

  void _reset() => setState(() {
        _result = null;
        _imagePath = null;
        _rawExpanded = false;
      });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: _isScanning
            ? const _ScanningIndicator()
            : _result == null
                ? _buildPickerView(theme)
                : _buildResultView(theme),
      ),
    );
  }

  // ── Picker view ───────────────────────────────────────────────────────────

  Widget _buildPickerView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan a receipt to auto-fill\nyour expense details.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          _SourceButton(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            color: AppColors.primary,
            onTap: _scanCamera,
          ),
          const SizedBox(height: 16),
          _SourceButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            color: AppColors.secondary,
            onTap: _scanGallery,
          ),
        ],
      ),
    );
  }

  // ── Result view ───────────────────────────────────────────────────────────

  Widget _buildResultView(ThemeData theme) {
    final result = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Optional image preview
          if (_imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_imagePath!),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 20),

          // Extracted fields card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Extracted Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const Divider(height: 24),
                  _FieldRow(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Amount',
                    value: result.hasAmount
                        ? '₹${result.amount!.toStringAsFixed(2)}'
                        : 'Not detected',
                    valueColor: result.hasAmount
                        ? AppColors.income
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  _FieldRow(
                    icon: Icons.store_rounded,
                    label: 'Merchant',
                    value: result.hasMerchant
                        ? result.merchant!
                        : 'Not detected',
                    valueColor: result.hasMerchant
                        ? null
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  _FieldRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value:
                        result.hasDate ? result.date! : 'Not detected',
                    valueColor: result.hasDate
                        ? null
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Raw text expandable
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.text_snippet_rounded),
              title: Text('Raw Text',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              initiallyExpanded: _rawExpanded,
              onExpansionChanged: (v) =>
                  setState(() => _rawExpanded = v),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SelectableText(
                    result.rawText.isEmpty
                        ? 'No text recognised.'
                        : result.rawText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Action buttons
          FilledButton.icon(
            onPressed: result.hasAmount ? _useResult : null,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Use This'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Scan Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Scanning receipt…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color:
                theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
