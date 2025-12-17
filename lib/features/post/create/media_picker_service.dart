import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  /// CAMERA — single image
  Future<XFile?> pickFromCamera() async {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  /// GALLERY — multiple images
  Future<List<XFile>> pickFromGallery() async {
    return _picker.pickMultiImage(imageQuality: 85);
  }
}
