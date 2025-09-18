import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageUploadWidget extends StatefulWidget {
  final List<XFile> selectedImages;
  final Function(List<XFile>) onImagesChanged;
  final int maxImages;

  const ImageUploadWidget({
    super.key,
    required this.selectedImages,
    required this.onImagesChanged,
    this.maxImages = 10,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (widget.selectedImages.length + images.length > widget.maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum ${widget.maxImages} images allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final updatedImages = [...widget.selectedImages, ...images];
      widget.onImagesChanged(updatedImages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    final updatedImages = [...widget.selectedImages];
    updatedImages.removeAt(index);
    widget.onImagesChanged(updatedImages);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Tap to add photos',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Add high-quality photos to attract more guests',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.selectedImages.length) {
                return GestureDetector(
                  onTap: widget.selectedImages.length < widget.maxImages ? _pickImages : null,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.selectedImages.length < widget.maxImages 
                            ? Colors.grey.shade300 
                            : Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: widget.selectedImages.length < widget.maxImages 
                          ? Colors.white 
                          : Colors.grey.shade100,
                    ),
                    child: Icon(
                      Icons.add,
                      color: widget.selectedImages.length < widget.maxImages 
                          ? Colors.grey 
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              }
              
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.selectedImages[index].path),
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
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
                    if (index == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.selectedImages.length}/${widget.maxImages} photos selected',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        if (widget.selectedImages.isNotEmpty)
          const SizedBox(height: 4),
        if (widget.selectedImages.isNotEmpty)
          Text(
            'First image will be used as cover photo',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
      ],
    );
  }
}
