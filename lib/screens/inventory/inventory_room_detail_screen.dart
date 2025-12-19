import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/inventory_model.dart';
import '../../services/inventory_service.dart';

class InventoryRoomDetailScreen extends StatefulWidget {
  final String inventoryId;
  final InventoryRoomEntryModel roomEntry;
  final Function onUpdated;

  const InventoryRoomDetailScreen({
    Key? key,
    required this.inventoryId,
    required this.roomEntry,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<InventoryRoomDetailScreen> createState() => _InventoryRoomDetailScreenState();
}

class _InventoryRoomDetailScreenState extends State<InventoryRoomDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  List<InventoryRoomPhotoModel> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.roomEntry.description ?? '';
    _photos = widget.roomEntry.photos ?? [];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDescription() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _inventoryService.updateRoomEntry(
        widget.inventoryId,
        widget.roomEntry.id,
        _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description enregistrée')),
        );
      }
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _inventoryService.uploadRoomPhoto(
        widget.inventoryId,
        widget.roomEntry.id,
        File(image.path),
      );

      Navigator.pop(context);

      final updatedPhotos = await _inventoryService.getRoomPhotos(
        widget.inventoryId,
        widget.roomEntry.id,
      );

      setState(() {
        _photos = updatedPhotos;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo ajoutée avec succès')),
        );
      }
      widget.onUpdated();
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _inventoryService.deleteRoomPhoto(
        widget.inventoryId,
        widget.roomEntry.id,
        photoId,
      );

      setState(() {
        _photos.removeWhere((photo) => photo.id == photoId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo supprimée')),
        );
      }
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomEntry.sectionName ?? 'Pièce'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveDescription,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Description de l\'état',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Décrivez l\'état de cette pièce...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo_library, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_photos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                   size: 64,
                                   color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          final photo = _photos[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: photo.photoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(4),
                                    minimumSize: const Size(28, 28),
                                  ),
                                  onPressed: () => _deletePhoto(photo.id),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
