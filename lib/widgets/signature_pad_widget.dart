import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(String) onSignatureSaved;
  final String title;

  const SignaturePadWidget({
    Key? key,
    required this.onSignatureSaved,
    this.title = 'Signature',
  }) : super(key: key);

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  Future<void> _handleSave() async {
    final signatureImage = await _signaturePadKey.currentState!.toImage();
    final ByteData? data = await signatureImage.toByteData(format: ui.ImageByteFormat.png);

    if (data != null) {
      final Uint8List bytes = data.buffer.asUint8List();
      final String base64String = 'data:image/png;base64,${base64Encode(bytes)}';
      widget.onSignatureSaved(base64String);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleClear() {
    _signaturePadKey.currentState!.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final isLandscape = size.width > size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: size.height * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.draw,
                    color: Colors.white,
                    size: isSmallScreen ? 22 : 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Signature Pad
                      Container(
                        height: isLandscape
                            ? size.height * 0.4
                            : (isSmallScreen ? 200 : 280),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SfSignaturePad(
                            key: _signaturePadKey,
                            backgroundColor: Colors.white,
                            strokeColor: Colors.blue.shade900,
                            minimumStrokeWidth: 1.5,
                            maximumStrokeWidth: 3.5,
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          // Clear Button
                          OutlinedButton.icon(
                            onPressed: _handleClear,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Effacer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 24,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          // Save Button
                          ElevatedButton.icon(
                            onPressed: _handleSave,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Sauvegarder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 20 : 32,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          // Cancel Button
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Annuler'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 24,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}