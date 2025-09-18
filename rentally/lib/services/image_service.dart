import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  Future<List<XFile>?> pickMultipleImages({int maxImages = 10}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      // Limit the number of images
      if (images.length > maxImages) {
        return images.take(maxImages).toList();
      }
      
      return images;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return null;
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      // Simulate image upload to server
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would upload to your server/cloud storage
      // and return the URL. For now, we'll return a mock URL
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://mock-storage.com/images/${timestamp}_${image.name}';
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<XFile> images) async {
    final List<String> uploadedUrls = [];
    
    for (final image in images) {
      final url = await uploadImage(image);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }
}

// Provider for ImageService
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

// State for managing selected images
class ImageState {
  final List<XFile> selectedImages;
  final List<String> uploadedUrls;
  final bool isUploading;
  final String? error;

  const ImageState({
    this.selectedImages = const [],
    this.uploadedUrls = const [],
    this.isUploading = false,
    this.error,
  });

  ImageState copyWith({
    List<XFile>? selectedImages,
    List<String>? uploadedUrls,
    bool? isUploading,
    String? error,
  }) {
    return ImageState(
      selectedImages: selectedImages ?? this.selectedImages,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
    );
  }
}

// StateNotifier for managing image operations
class ImageNotifier extends StateNotifier<ImageState> {
  final ImageService _imageService;

  ImageNotifier(this._imageService) : super(const ImageState());

  void addImage(XFile image) {
    state = state.copyWith(
      selectedImages: [...state.selectedImages, image],
      error: null,
    );
  }

  void addMultipleImages(List<XFile> images) {
    state = state.copyWith(
      selectedImages: [...state.selectedImages, ...images],
      error: null,
    );
  }

  void removeImage(int index) {
    final updatedImages = List<XFile>.from(state.selectedImages);
    updatedImages.removeAt(index);
    state = state.copyWith(selectedImages: updatedImages);
  }

  void clearImages() {
    state = state.copyWith(selectedImages: []);
  }

  Future<void> uploadImages() async {
    if (state.selectedImages.isEmpty) return;

    state = state.copyWith(isUploading: true, error: null);

    try {
      final urls = await _imageService.uploadMultipleImages(state.selectedImages);
      state = state.copyWith(
        uploadedUrls: [...state.uploadedUrls, ...urls],
        isUploading: false,
        selectedImages: [], // Clear selected images after upload
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload images: $e',
      );
    }
  }

  Future<void> pickFromGallery() async {
    final image = await _imageService.pickImageFromGallery();
    if (image != null) {
      addImage(image);
    }
  }

  Future<void> pickFromCamera() async {
    final image = await _imageService.pickImageFromCamera();
    if (image != null) {
      addImage(image);
    }
  }

  Future<void> pickMultipleFromGallery({int maxImages = 10}) async {
    final images = await _imageService.pickMultipleImages(maxImages: maxImages);
    if (images != null && images.isNotEmpty) {
      addMultipleImages(images);
    }
  }
}

// Provider for ImageNotifier
final imageProvider = StateNotifierProvider<ImageNotifier, ImageState>((ref) {
  final imageService = ref.read(imageServiceProvider);
  return ImageNotifier(imageService);
});
