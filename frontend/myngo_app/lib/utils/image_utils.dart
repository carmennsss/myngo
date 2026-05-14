import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

const Color _primaryColor = Color(0xFFC35E34);
const Color _toolbarColor = Color(0xFFC35E34);
const Color _toolbarWidgetColor = Colors.white;

Future<XFile?> recortarImagenCirculo(XFile imagen, {BuildContext? context}) async {
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
      if (context != null)
        WebUiSettings(
          context: context,
          size: const CropperSize(width: 500, height: 500),
          presentStyle: WebPresentStyle.dialog,
          modal: true,
          background: true,
          center: true,
          guides: true,
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
    return imagen;
  }
}

Future<XFile?> recortarImagenRectangular(XFile imagen, {BuildContext? context, double aspectRatioX = 16, double aspectRatioY = 9}) async {
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
      if (context != null)
        WebUiSettings(
          context: context,
          size: const CropperSize(width: 500, height: 500),
          presentStyle: WebPresentStyle.dialog,
          modal: true,
          background: true,
          center: true,
          guides: true,
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
    return imagen;
  }
}
