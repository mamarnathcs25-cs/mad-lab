import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:medapp/models/prescription_result.dart';
import 'package:medapp/services/prescription_parser.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key, required this.image});

  final File image;

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final PrescriptionParser _parser = PrescriptionParser();

  bool _isLoading = true;
  PrescriptionResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final inputImage = InputImage.fromFile(widget.image);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      setState(() {
        _result = _parser.parse(recognizedText.text);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to scan prescription. Please try a clearer photo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription Results')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : result == null
                  ? const Center(child: Text('No scan result available'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SectionCard(
                          title: 'Suggested Medicines',
                          icon: Icons.medication_outlined,
                          child: result.medicineNames.isEmpty
                              ? const Text(
                                  'No medicine names confidently detected.')
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: result.medicineNames
                                      .map(
                                        (name) => Chip(
                                          label: Text(name),
                                          avatar: const Icon(
                                              Icons.local_hospital_outlined,
                                              size: 18),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Dosage Lines',
                          icon: Icons.notes_outlined,
                          child: result.dosageLines.isEmpty
                              ? const Text('No dosage text detected.')
                              : Column(
                                  children: result.dosageLines
                                      .map(
                                        (line) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                              Icons.check_circle_outline),
                                          title: Text(line),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Raw Extracted Text',
                          icon: Icons.text_snippet_outlined,
                          child: SelectableText(result.rawText.isEmpty
                              ? 'No text found.'
                              : result.rawText),
                        ),
                      ],
                    ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
