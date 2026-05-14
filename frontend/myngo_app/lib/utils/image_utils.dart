import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/comunes/web_cropper_dialog.dart';

const Color _primaryColor = Color(0xFFC35E34);
const Color _toolbarColor = Color(0xFFC35E34);
const Color _toolbarWidgetColor = Colors.white;

Future<XFile?> recortarImagenCirculo(XFile imagen, {BuildContext? context}) async {
  if (kIsWeb) {
    return _recortarEnWeb(imagen, context, circle: true, aspectRatio: 1);
  }
  try {
    final uiSettings = [
      AndroidUiSettings(
        toolbarTitle: 'Ajustar foto',
        toolbarColor: _toolbarColor,
        toolbarWidgetColor: _toolbarWidgetColor,
        backgroundColor: Colors.black,
        activeControlsWidgetColor: _primaryColor,
        cropFrameColor: _primaryColor,
        cropGridColor: _primaryColor.withOpacity(0.5),
        hideBottomControls: true,
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
        cropStyle: CropStyle.circle,
      ),
      IOSUiSettings(
        title: 'Ajustar foto',
        doneButtonTitle: 'Listo',
        cancelButtonTitle: 'Cancelar',
        cropStyle: CropStyle.circle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ];

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagen.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: uiSettings,
    );

    if (croppedFile == null) return null;
    return XFile(croppedFile.path);
  } catch (e) {
    debugPrint('[ERROR image_cropper] $e');
    return null;
  }
}

Future<XFile?> recortarImagenRectangular(XFile imagen, {BuildContext? context, double aspectRatioX = 16, double aspectRatioY = 9}) async {
  if (kIsWeb) {
    return _recortarEnWeb(imagen, context, circle: false, aspectRatio: aspectRatioX / aspectRatioY);
  }
  try {
    final uiSettings = [
      AndroidUiSettings(
        toolbarTitle: 'Ajustar banner',
        toolbarColor: _toolbarColor,
        toolbarWidgetColor: _toolbarWidgetColor,
        backgroundColor: Colors.black,
        activeControlsWidgetColor: _primaryColor,
        cropFrameColor: _primaryColor,
        cropGridColor: _primaryColor.withOpacity(0.5),
        hideBottomControls: false,
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.original,
        cropStyle: CropStyle.rectangle,
      ),
      IOSUiSettings(
        title: 'Ajustar banner',
        doneButtonTitle: 'Listo',
        cancelButtonTitle: 'Cancelar',
        cropStyle: CropStyle.rectangle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ];

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagen.path,
      aspectRatio: CropAspectRatio(ratioX: aspectRatioX, ratioY: aspectRatioY),
      compressQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
      uiSettings: uiSettings,
    );

    if (croppedFile == null) return null;
    return XFile(croppedFile.path);
  } catch (e) {
    debugPrint('[ERROR image_cropper rectangular] $e');
    return null;
  }
}

Future<XFile?> _recortarEnWeb(XFile imagen, BuildContext? context, {required bool circle, required double aspectRatio}) async {
  if (context == null) return imagen;
  try {
    final bytes = await imagen.readAsBytes();
    final cropped = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WebCropperDialog(
        imageBytes: bytes,
        withCircleUi: circle,
        aspectRatio: aspectRatio,
      ),
    );
    if (cropped == null) return null;
    return XFile.fromData(Uint8List.fromList(cropped), name: 'cropped_image.jpg');
  } catch (e) {
    debugPrint('[ERROR web_cropper] $e');
    return null;
  }
}
