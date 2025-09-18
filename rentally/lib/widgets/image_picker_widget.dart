import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';

class ImagePickerWidget extends ConsumerWidget {
  final List<XFile> images;
  final Function(List<XFile>) onImagesChanged;
  final int maxImages;
  final String? title;
  final bool allowMultiple;

  const ImagePickerWidget({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 10,
    this.title,
    this.allowMultiple = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Image grid
        if (images.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return _buildImageItem(context, images[index], index);
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // Add image buttons
        if (images.length < maxImages) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showImageSourceDialog(context, ref),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(allowMultiple ? 'Add Photos' : 'Add Photo'),
                ),
              ),
              if (allowMultiple && images.length < maxImages - 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMultipleImages(ref),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImageItem(BuildContext context, XFile image, int index) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(image.path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera(ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(WidgetRef ref) async {
    final imageService = ref.read(imageServiceProvider);
    final image = await imageService.pickImageFromCamera();
    if (image != null) {
      final updatedImages = [...images, image];
      onImagesChanged(updatedImages);
    }
  }

  Future<void> _pickFromGallery(WidgetRef ref) async {
    final imageService = ref.read(imageServiceProvider);
    final image = await imageService.pickImageFromGallery();
    if (image != null) {
      final updatedImages = [...images, image];
      onImagesChanged(updatedImages);
    }
  }

  Future<void> _pickMultipleImages(WidgetRef ref) async {
    final imageService = ref.read(imageServiceProvider);
    final remainingSlots = maxImages - images.length;
    final newImages = await imageService.pickMultipleImages(
      maxImages: remainingSlots,
    );
    if (newImages != null && newImages.isNotEmpty) {
      final updatedImages = [...images, ...newImages];
      onImagesChanged(updatedImages);
    }
  }

  void _removeImage(int index) {
    final updatedImages = List<XFile>.from(images);
    updatedImages.removeAt(index);
    onImagesChanged(updatedImages);
  }
}

// Profile image picker widget for single image selection
class ProfileImagePicker extends ConsumerWidget {
  final XFile? image;
  final Function(XFile?) onImageChanged;
  final double size;

  const ProfileImagePicker({
    super.key,
    this.image,
    required this.onImageChanged,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showImageSourceDialog(context, ref),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: image != null
              ? Image.file(
                  File(image!.path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(theme);
                  },
                )
              : _buildPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: size * 0.3,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            'Add Photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    onImageChanged(null);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera(ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(WidgetRef ref) async {
    final imageService = ref.read(imageServiceProvider);
    final pickedImage = await imageService.pickImageFromCamera();
    if (pickedImage != null) {
      onImageChanged(pickedImage);
    }
  }

  Future<void> _pickFromGallery(WidgetRef ref) async {
    final imageService = ref.read(imageServiceProvider);
    final pickedImage = await imageService.pickImageFromGallery();
    if (pickedImage != null) {
      onImageChanged(pickedImage);
    }
  }
}
