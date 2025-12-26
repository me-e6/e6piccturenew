/* import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'create_post_service.dart';
import 'image_crop_service.dart';

/// ============================================================================
/// CREATE POST CONTROLLER
/// ============================================================================
/// Manages state for post creation with enhanced image editing.
/// 
/// FEATURES:
/// - ✅ Multi-image selection (gallery + camera)
/// - ✅ Image reordering (drag to rearrange)
/// - ✅ Image cropping (per-image)
/// - ✅ Image deletion (before posting)
/// - ✅ Watermark support (QR + branding)
/// - ✅ Upload progress tracking
/// ============================================================================
class CreatePostController extends ChangeNotifier {
  final CreatePostService _service;
  final ImageCropService _cropService;
  final ImagePicker _picker;

  /// List of selected image paths
  final List<String> _selectedImages;/*  */
  
  /// Original paths (before cropping) for undo
  final Map<int, String> _originalPaths = {};

  bool _isUploading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------
  CreatePostController({
    List<String>? initialImagePaths,
    CreatePostService? service,
    ImageCropService? cropService,
    ImagePicker? picker,
  })  : _selectedImages = List<String>.from(initialImagePaths ?? []),
        _service = service ?? CreatePostService(),
        _cropService = cropService ?? ImageCropService(),
        _picker = picker ?? ImagePicker();

  // --------------------------------------------------------------------------
  // GETTERS
  // --------------------------------------------------------------------------
  
  /// Current selected images (read-only)
  List<String> get selectedImages => List.unmodifiable(_selectedImages);
  
  /// Number of selected images
  int get imageCount => _selectedImages.length;
  
  /// Whether images are selected
  bool get hasImages => _selectedImages.isNotEmpty;
  
  /// Upload in progress
  bool get isUploading => _isUploading;
  
  /// Processing (cropping, etc.)
  bool get isProcessing => _isProcessing;
  
  /// Any operation in progress
  bool get isBusy => _isUploading || _isProcessing;
  
  /// Current error message
  String? get errorMessage => _errorMessage;
  
  /// Upload progress (0.0 - 1.0)
  double get uploadProgress => _uploadProgress;

  // --------------------------------------------------------------------------
  // PICK IMAGES (Gallery)
  // --------------------------------------------------------------------------
  /// Opens gallery to pick multiple images.
  Future<void> pickImages() async {
    if (isBusy) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
      );

      if (files.isEmpty) {
        debugPrint('📷 [CreatePostController] User cancelled picker');
        return;
      }

      // Validate and add files
      for (final file in files) {
        if (file.path.isNotEmpty && File(file.path).existsSync()) {
          _selectedImages.add(file.path);
        }
      }

      debugPrint('📷 [CreatePostController] Added ${files.length} images');
      
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error picking images: $e');
      _errorMessage = 'Failed to pick images';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // PICK FROM CAMERA
  // --------------------------------------------------------------------------
  /// Opens camera to take a photo.
  Future<void> pickFromCamera() async {
    if (isBusy) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
      );

      if (photo == null) {
        debugPrint('📷 [CreatePostController] User cancelled camera');
        return;
      }

      if (photo.path.isNotEmpty && File(photo.path).existsSync()) {
        _selectedImages.add(photo.path);
        debugPrint('📷 [CreatePostController] Added camera photo');
      }
      
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error taking photo: $e');
      _errorMessage = 'Failed to take photo';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // ADD MORE IMAGES
  // --------------------------------------------------------------------------
  /// Shows bottom sheet to add more images (gallery or camera).
  Future<void> addMoreImages(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result == 'gallery') {
      await pickImages();
    } else if (result == 'camera') {
      await pickFromCamera();
    }
  }

  // --------------------------------------------------------------------------
  // CROP IMAGE
  // --------------------------------------------------------------------------
  /// Opens the cropper for a specific image.
  Future<void> cropImage(int index, BuildContext context) async {
    if (isBusy || index < 0 || index >= _selectedImages.length) return;

    try {
      _isProcessing = true;
      notifyListeners();

      final originalPath = _selectedImages[index];
      
      // Store original for potential undo
      _originalPaths[index] = originalPath;

      final croppedPath = await _cropService.cropForPost(
        imagePath: originalPath,
        context: context,
      );

      if (croppedPath != null && croppedPath.isNotEmpty) {
        _selectedImages[index] = croppedPath;
        debugPrint('✂️ [CreatePostController] Image $index cropped');
      }
      
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error cropping image: $e');
      _errorMessage = 'Failed to crop image';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // REORDER IMAGES
  // --------------------------------------------------------------------------
  /// Moves an image from one position to another.
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _selectedImages.length) return;
    if (newIndex < 0 || newIndex > _selectedImages.length) return;
    if (oldIndex == newIndex) return;

    // Adjust index if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _selectedImages.removeAt(oldIndex);
    _selectedImages.insert(newIndex, item);

    debugPrint('🔀 [CreatePostController] Reordered: $oldIndex → $newIndex');
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // REMOVE IMAGE
  // --------------------------------------------------------------------------
  /// Removes an image at the given index.
  void removeImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;

    _selectedImages.removeAt(index);
    _originalPaths.remove(index);

    debugPrint('🗑️ [CreatePostController] Removed image at index $index');
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // CLEAR ALL IMAGES
  // --------------------------------------------------------------------------
  /// Removes all selected images.
  void clearAllImages() {
    _selectedImages.clear();
    _originalPaths.clear();
    _errorMessage = null;

    debugPrint('🗑️ [CreatePostController] Cleared all images');
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // UNDO CROP
  // --------------------------------------------------------------------------
  /// Restores the original (uncropped) image at the given index.
  void undoCrop(int index) {
    final originalPath = _originalPaths[index];
    if (originalPath != null && File(originalPath).existsSync()) {
      _selectedImages[index] = originalPath;
      _originalPaths.remove(index);
      
      debugPrint('↩️ [CreatePostController] Undid crop for image $index');
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // CREATE POST
  // --------------------------------------------------------------------------
  /// Uploads images and creates the post.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> createPost() async {
    if (_isUploading) {
      debugPrint('⚠️ [CreatePostController] Upload already in progress');
      return false;
    }

    if (_selectedImages.isEmpty) {
      _errorMessage = 'No images selected';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate files exist
      final imageFiles = <File>[];
      for (final path in _selectedImages) {
        final file = File(path);
        if (file.existsSync()) {
          imageFiles.add(file);
        } else {
          debugPrint('⚠️ [CreatePostController] File not found: $path');
        }
      }

      if (imageFiles.isEmpty) {
        _errorMessage = 'No valid image files found';
        return false;
      }

      // Update progress
      _uploadProgress = 0.1;
      notifyListeners();

      // Create post (service handles watermarking)
      await _service.createImagePost(images: imageFiles);

      // Success!
      _uploadProgress = 1.0;
      _selectedImages.clear();
      _originalPaths.clear();
      _errorMessage = null;

      debugPrint('✅ [CreatePostController] Post created successfully');
      return true;

    } catch (e) {
      debugPrint('❌ [CreatePostController] Error creating post: $e');
      _errorMessage = 'Failed to create post: $e';
      return false;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // DISPOSAL
  // --------------------------------------------------------------------------
  @override
  void dispose() {
    _selectedImages.clear();
    _originalPaths.clear();
    super.dispose();
  }
}
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'create_post_service.dart';
import 'image_crop_service.dart';

/// ============================================================================
/// CREATE POST CONTROLLER
/// ============================================================================
/// Manages state for post creation with enhanced image editing.
///
/// FEATURES:
/// - ✅ Multi-image selection (gallery + camera)
/// - ✅ Image reordering (drag to rearrange)
/// - ✅ Image cropping (per-image)
/// - ✅ Image deletion (before posting)
/// - ✅ Watermark support (QR + branding)
/// - ✅ Upload progress tracking
/// ============================================================================
class CreatePostController extends ChangeNotifier {
  final CreatePostService _service;
  final ImageCropService _cropService;
  final ImagePicker _picker;

  /// List of selected image paths
  final List<String> _selectedImages;

  /// Original paths (before cropping) for undo
  final Map<int, String> _originalPaths = {};

  bool _isUploading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------
  CreatePostController({
    List<String>? initialImagePaths,
    CreatePostService? service,
    ImageCropService? cropService,
    ImagePicker? picker,
  }) : _selectedImages = List<String>.from(initialImagePaths ?? []),
       _service = service ?? CreatePostService(),
       _cropService = cropService ?? ImageCropService(),
       _picker = picker ?? ImagePicker();

  // --------------------------------------------------------------------------
  // GETTERS
  // --------------------------------------------------------------------------

  /// Current selected images (read-only)
  List<String> get selectedImages => List.unmodifiable(_selectedImages);

  /// Number of selected images
  int get imageCount => _selectedImages.length;

  /// Whether images are selected
  bool get hasImages => _selectedImages.isNotEmpty;

  /// Upload in progress
  bool get isUploading => _isUploading;

  /// Processing (cropping, etc.)
  bool get isProcessing => _isProcessing;

  /// Any operation in progress
  bool get isBusy => _isUploading || _isProcessing;

  /// Current error message
  String? get errorMessage => _errorMessage;

  /// Upload progress (0.0 - 1.0)
  double get uploadProgress => _uploadProgress;

  // --------------------------------------------------------------------------
  // PICK IMAGES (Gallery)
  // --------------------------------------------------------------------------
  /// Opens gallery to pick multiple images.
  Future<void> pickImages() async {
    if (isBusy) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      _safeNotify();

      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
      );

      if (files.isEmpty) {
        debugPrint('📷 [CreatePostController] User cancelled picker');
        return;
      }

      // Validate and add files
      for (final file in files) {
        if (file.path.isNotEmpty && File(file.path).existsSync()) {
          _selectedImages.add(file.path);
        }
      }

      debugPrint('📷 [CreatePostController] Added ${files.length} images');
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error picking images: $e');
      _errorMessage = 'Failed to pick images';
    } finally {
      _isProcessing = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // PICK FROM CAMERA
  // --------------------------------------------------------------------------
  /// Opens camera to take a photo.
  Future<void> pickFromCamera() async {
    if (isBusy) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      _safeNotify();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
      );

      if (photo == null) {
        debugPrint('📷 [CreatePostController] User cancelled camera');
        return;
      }

      if (photo.path.isNotEmpty && File(photo.path).existsSync()) {
        _selectedImages.add(photo.path);
        debugPrint('📷 [CreatePostController] Added camera photo');
      }
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error taking photo: $e');
      _errorMessage = 'Failed to take photo';
    } finally {
      _isProcessing = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // ADD MORE IMAGES
  // --------------------------------------------------------------------------
  /// Shows bottom sheet to add more images (gallery or camera).
  Future<void> addMoreImages(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  Theme.of(ctx).colorScheme.onSurfaceVariant.red,
                  Theme.of(ctx).colorScheme.onSurfaceVariant.green,
                  Theme.of(ctx).colorScheme.onSurfaceVariant.blue,
                  0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result == 'gallery') {
      await pickImages();
    } else if (result == 'camera') {
      await pickFromCamera();
    }
  }

  // --------------------------------------------------------------------------
  // CROP IMAGE
  // --------------------------------------------------------------------------
  /// Opens the cropper for a specific image.
  Future<void> cropImage(int index, BuildContext context) async {
    if (isBusy || index < 0 || index >= _selectedImages.length) return;

    try {
      _isProcessing = true;
      _safeNotify();

      final originalPath = _selectedImages[index];

      // Store original for potential undo
      _originalPaths[index] = originalPath;

      final croppedPath = await _cropService.cropForPost(
        imagePath: originalPath,
        context: context,
      );

      if (croppedPath != null && croppedPath.isNotEmpty) {
        _selectedImages[index] = croppedPath;
        debugPrint('✂️ [CreatePostController] Image $index cropped');
      }
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error cropping image: $e');
      _errorMessage = 'Failed to crop image';
    } finally {
      _isProcessing = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // REORDER IMAGES
  // --------------------------------------------------------------------------
  /// Moves an image from one position to another.
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _selectedImages.length) return;
    if (newIndex < 0 || newIndex > _selectedImages.length) return;
    if (oldIndex == newIndex) return;

    // Adjust index if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _selectedImages.removeAt(oldIndex);
    _selectedImages.insert(newIndex, item);

    debugPrint('🔀 [CreatePostController] Reordered: $oldIndex → $newIndex');
    _safeNotify();
  }

  // --------------------------------------------------------------------------
  // REMOVE IMAGE
  // --------------------------------------------------------------------------
  /// Removes an image at the given index.
  void removeImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;

    _selectedImages.removeAt(index);
    _originalPaths.remove(index);

    debugPrint('🗑️ [CreatePostController] Removed image at index $index');
    _safeNotify();
  }

  // --------------------------------------------------------------------------
  // CLEAR ALL IMAGES
  // --------------------------------------------------------------------------
  /// Removes all selected images.
  void clearAllImages() {
    _selectedImages.clear();
    _originalPaths.clear();
    _errorMessage = null;

    debugPrint('🗑️ [CreatePostController] Cleared all images');
    _safeNotify();
  }

  // --------------------------------------------------------------------------
  // UNDO CROP
  // --------------------------------------------------------------------------
  /// Restores the original (uncropped) image at the given index.
  void undoCrop(int index) {
    final originalPath = _originalPaths[index];
    if (originalPath != null && File(originalPath).existsSync()) {
      _selectedImages[index] = originalPath;
      _originalPaths.remove(index);

      debugPrint('↩️ [CreatePostController] Undid crop for image $index');
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // CREATE POST
  // --------------------------------------------------------------------------
  /// Uploads images and creates the post.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> createPost() async {
    if (_isUploading) {
      debugPrint('⚠️ [CreatePostController] Upload already in progress');
      return false;
    }

    if (_selectedImages.isEmpty) {
      _errorMessage = 'No images selected';
      _safeNotify();
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    _safeNotify();

    try {
      // Validate files exist
      final imageFiles = <File>[];
      for (final path in _selectedImages) {
        final file = File(path);
        if (file.existsSync()) {
          imageFiles.add(file);
        } else {
          debugPrint('⚠️ [CreatePostController] File not found: $path');
        }
      }

      if (imageFiles.isEmpty) {
        _errorMessage = 'No valid image files found';
        return false;
      }

      // Update progress
      _uploadProgress = 0.1;
      _safeNotify();

      // Create post (service handles watermarking)
      await _service.createImagePost(images: imageFiles);

      // Success!
      _uploadProgress = 1.0;
      _selectedImages.clear();
      _originalPaths.clear();
      _errorMessage = null;

      debugPrint('✅ [CreatePostController] Post created successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [CreatePostController] Error creating post: $e');
      _errorMessage = 'Failed to create post: $e';
      return false;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // SAFE NOTIFY (prevents "used after disposed" error)
  // --------------------------------------------------------------------------
  bool _isDisposed = false;

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // DISPOSAL
  // --------------------------------------------------------------------------
  @override
  void dispose() {
    _isDisposed = true;
    _selectedImages.clear();
    _originalPaths.clear();
    super.dispose();
  }
}
