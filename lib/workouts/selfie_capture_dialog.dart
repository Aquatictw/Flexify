import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/tokens.dart';

class SelfieCaptureDialog extends StatelessWidget {
  const SelfieCaptureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Capture Your Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Take a selfie to remember this workout!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: space16),
          FilledButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final XFile? pickedFile = await picker.pickImage(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.front,
              );
              if (context.mounted) {
                Navigator.pop(context, pickedFile?.path);
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          const SizedBox(height: space8),
          OutlinedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final XFile? pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (context.mounted) {
                Navigator.pop(context, pickedFile?.path);
              }
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

/// Shows selfie capture dialog and returns the image path or null
Future<String?> showSelfieCaptureDialog(BuildContext context) async {
  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const SelfieCaptureDialog(),
  );
}
