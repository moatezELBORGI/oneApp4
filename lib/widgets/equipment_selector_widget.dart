import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/equipment_template_model.dart';
import '../services/equipment_template_service.dart';

class SelectedEquipment {
  final EquipmentTemplateModel template;
  final List<File> images;
  String? customName;

  SelectedEquipment({
    required this.template,
    this.images = const [],
    this.customName,
  });

  String get displayName => customName ?? template.name;
}

class EquipmentSelectorWidget extends StatefulWidget {
  final int roomTypeId;
  final Function(List<SelectedEquipment>) onEquipmentsChanged;
  final List<SelectedEquipment>? initialEquipments;

  const EquipmentSelectorWidget({
    Key? key,
    required this.roomTypeId,
    required this.onEquipmentsChanged,
    this.initialEquipments,
  }) : super(key: key);

  @override
  State<EquipmentSelectorWidget> createState() => _EquipmentSelectorWidgetState();
}

class _EquipmentSelectorWidgetState extends State<EquipmentSelectorWidget> {
  final EquipmentTemplateService _templateService = EquipmentTemplateService();
  final ImagePicker _imagePicker = ImagePicker();

  List<EquipmentTemplateModel> _availableTemplates = [];
  List<SelectedEquipment> _selectedEquipments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedEquipments = widget.initialEquipments ?? [];
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _templateService.getTemplatesByRoomType(widget.roomTypeId);
      setState(() {
        _availableTemplates = templates;
        _isLoading = false;
      });

      if (widget.initialEquipments == null || widget.initialEquipments!.isEmpty) {
        _autoSelectDefaultEquipments();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des équipements: $e')),
        );
      }
    }
  }

  void _autoSelectDefaultEquipments() {
    if (_availableTemplates.isEmpty) return;

    final defaultEquipmentNames = <String>[];

    final hasKitchenEquipment = _availableTemplates.any(
            (t) => t.name.toLowerCase().contains('four') ||
            t.name.toLowerCase().contains('réfrigérateur'));

    final hasBathroomEquipment = _availableTemplates.any(
            (t) => t.name.toLowerCase().contains('douche') ||
            t.name.toLowerCase().contains('lavabo'));

    if (hasKitchenEquipment) {
      defaultEquipmentNames.addAll([
        'four',
        'plaque de cuisson',
        'réfrigérateur',
        'évier',
        'hotte',
      ]);
    } else if (hasBathroomEquipment) {
      defaultEquipmentNames.addAll([
        'douche',
        'lavabo',
        'toilette',
        'miroir',
      ]);
    }

    final defaultEquipments = _availableTemplates
        .where((template) => defaultEquipmentNames.any(
            (name) => template.name.toLowerCase().contains(name.toLowerCase())))
        .take(4)
        .map((template) => SelectedEquipment(template: template, images: []))
        .toList();

    if (defaultEquipments.isNotEmpty) {
      setState(() {
        _selectedEquipments = defaultEquipments;
      });
      widget.onEquipmentsChanged(_selectedEquipments);
    }
  }

  List<EquipmentTemplateModel> get _filteredTemplates {
    if (_searchQuery.isEmpty) return _availableTemplates;
    return _availableTemplates.where((template) {
      return template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (template.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _addEquipment(EquipmentTemplateModel template) {
    final selectedEquipment = SelectedEquipment(
      template: template,
      images: [],
    );
    setState(() {
      _selectedEquipments.add(selectedEquipment);
      _searchQuery = '';
      _searchController.clear();
    });
    widget.onEquipmentsChanged(_selectedEquipments);
    Navigator.pop(context);
  }

  void _removeEquipment(int index) {
    setState(() {
      _selectedEquipments.removeAt(index);
    });
    widget.onEquipmentsChanged(_selectedEquipments);
  }

  Future<void> _pickImages(int equipmentIndex) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          final currentImages = List<File>.from(_selectedEquipments[equipmentIndex].images);
          currentImages.addAll(images.map((xfile) => File(xfile.path)));
          _selectedEquipments[equipmentIndex] = SelectedEquipment(
            template: _selectedEquipments[equipmentIndex].template,
            images: currentImages,
            customName: _selectedEquipments[equipmentIndex].customName,
          );
        });
        widget.onEquipmentsChanged(_selectedEquipments);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection des images: $e')),
      );
    }
  }

  void _removeImage(int equipmentIndex, int imageIndex) {
    setState(() {
      final currentImages = List<File>.from(_selectedEquipments[equipmentIndex].images);
      currentImages.removeAt(imageIndex);
      _selectedEquipments[equipmentIndex] = SelectedEquipment(
        template: _selectedEquipments[equipmentIndex].template,
        images: currentImages,
        customName: _selectedEquipments[equipmentIndex].customName,
      );
    });
    widget.onEquipmentsChanged(_selectedEquipments);
  }

  void _showEquipmentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sélectionner un équipement',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un équipement...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = _filteredTemplates[index];
                  final isAlreadySelected = _selectedEquipments
                      .any((eq) => eq.template.id == template.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(
                          Icons.home_repair_service,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      title: Text(
                        template.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: template.description != null
                          ? Text(
                        template.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                          : null,
                      trailing: isAlreadySelected
                          ? Icon(Icons.check_circle, color: Colors.green.shade600)
                          : const Icon(Icons.add_circle_outline),
                      onTap: isAlreadySelected
                          ? null
                          : () => _addEquipment(template),
                      enabled: !isAlreadySelected,
                    ),
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Équipements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showEquipmentPicker,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedEquipments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.home_repair_service_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun équipement ajouté',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez sur "Ajouter" pour sélectionner des équipements',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedEquipments.length,
            itemBuilder: (context, index) {
              final equipment = _selectedEquipments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.home_repair_service,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment.template.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (equipment.template.description != null)
                                  Text(
                                    equipment.template.description!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeEquipment(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImages(index),
                              icon: const Icon(Icons.add_photo_alternate),
                              label: Text(
                                equipment.images.isEmpty
                                    ? 'Ajouter des photos'
                                    : '${equipment.images.length} photo(s)',
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (equipment.images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: equipment.images.length,
                            itemBuilder: (context, imageIndex) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(equipment.images[imageIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index, imageIndex),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
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
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
