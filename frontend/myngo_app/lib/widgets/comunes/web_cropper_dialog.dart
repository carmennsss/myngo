import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class WebCropperDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final bool withCircleUi;
  final double aspectRatio;

  const WebCropperDialog({
    super.key,
    required this.imageBytes,
    this.withCircleUi = false,
    this.aspectRatio = 1,
  });

  @override
  State<WebCropperDialog> createState() => _WebCropperDialogState();
}

class _WebCropperDialogState extends State<WebCropperDialog> {
  final _controller = CropController();
  final _completer = Completer<Uint8List?>();
  bool _processing = false;

  @override
  void dispose() {
    if (!_completer.isCompleted) _completer.complete(null);
    super.dispose();
  }

  Future<void> _confirmCrop() async {
    if (_processing) return;
    setState(() => _processing = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    if (result is CropSuccess) {
      Navigator.of(context).pop(result.croppedImage);
    } else {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child:               Text(
                widget.withCircleUi ? tr('cropperTitle') : tr('cropperBannerTitle'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4440),
                ),
              ),
            ),
            const Divider(),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 400,
                child: Crop(
                  image: widget.imageBytes,
                  controller: _controller,
                  onCropped: _onCropped,
                  withCircleUi: widget.withCircleUi,
                  aspectRatio: widget.aspectRatio,
                  interactive: true,
                  baseColor: Colors.black,
                  maskColor: Colors.black54,
                  radius: widget.withCircleUi ? 999 : 8,
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: 0.85,
                    aspectRatio: widget.aspectRatio,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _processing ? null : () => Navigator.of(context).pop(null),
                    child: Text(
                      tr('commonCancel'),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _processing ? null : _confirmCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC35E34),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(tr('cropperConfirm'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
