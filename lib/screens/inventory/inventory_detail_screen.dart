import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../services/inventory_service.dart';
import '../../widgets/signature_pad_widget.dart';
import 'inventory_room_detail_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../../services/storage_service.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String inventoryId;

  const InventoryDetailScreen({Key? key, required this.inventoryId}) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  final StorageService _storageService = StorageService();
  InventoryModel? _inventory;
  bool _isLoading = true;
  bool _isSigning = false;
  bool _isGeneratingPdf = false;

  final Map<String, TextEditingController> _controllers = {
    'electricityMeterNumber': TextEditingController(),
    'electricityDayIndex': TextEditingController(),
    'electricityNightIndex': TextEditingController(),
    'waterMeterNumber': TextEditingController(),
    'waterIndex': TextEditingController(),
    'heatingMeterNumber': TextEditingController(),
    'heatingKwhIndex': TextEditingController(),
    'keysApartment': TextEditingController(),
    'keysMailbox': TextEditingController(),
    'keysCellar': TextEditingController(),
    'accessCards': TextEditingController(),
    'parkingRemotes': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final inventory = await _inventoryService.getInventoryById(widget.inventoryId);
      setState(() {
        _inventory = inventory;
        _populateControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _populateControllers() {
    if (_inventory == null) return;
    _controllers['electricityMeterNumber']!.text = _inventory!.electricityMeterNumber ?? '';
    _controllers['electricityDayIndex']!.text = _inventory!.electricityDayIndex?.toString() ?? '';
    _controllers['electricityNightIndex']!.text = _inventory!.electricityNightIndex?.toString() ?? '';
    _controllers['waterMeterNumber']!.text = _inventory!.waterMeterNumber ?? '';
    _controllers['waterIndex']!.text = _inventory!.waterIndex?.toString() ?? '';
    _controllers['heatingMeterNumber']!.text = _inventory!.heatingMeterNumber ?? '';
    _controllers['heatingKwhIndex']!.text = _inventory!.heatingKwhIndex?.toString() ?? '';
    _controllers['keysApartment']!.text = _inventory!.keysApartment.toString();
    _controllers['keysMailbox']!.text = _inventory!.keysMailbox.toString();
    _controllers['keysCellar']!.text = _inventory!.keysCellar.toString();
    _controllers['accessCards']!.text = _inventory!.accessCards.toString();
    _controllers['parkingRemotes']!.text = _inventory!.parkingRemotes.toString();
  }

  Future<void> _saveInventory() async {
    if (_inventory == null) return;

    try {
      final updatedInventory = InventoryModel(
        id: _inventory!.id,
        contractId: _inventory!.contractId,
        type: _inventory!.type,
        inventoryDate: _inventory!.inventoryDate,
        electricityMeterNumber: _controllers['electricityMeterNumber']!.text.isNotEmpty
            ? _controllers['electricityMeterNumber']!.text
            : null,
        electricityDayIndex: _controllers['electricityDayIndex']!.text.isNotEmpty
            ? double.tryParse(_controllers['electricityDayIndex']!.text)
            : null,
        electricityNightIndex: _controllers['electricityNightIndex']!.text.isNotEmpty
            ? double.tryParse(_controllers['electricityNightIndex']!.text)
            : null,
        waterMeterNumber: _controllers['waterMeterNumber']!.text.isNotEmpty
            ? _controllers['waterMeterNumber']!.text
            : null,
        waterIndex: _controllers['waterIndex']!.text.isNotEmpty
            ? double.tryParse(_controllers['waterIndex']!.text)
            : null,
        heatingMeterNumber: _controllers['heatingMeterNumber']!.text.isNotEmpty
            ? _controllers['heatingMeterNumber']!.text
            : null,
        heatingKwhIndex: _controllers['heatingKwhIndex']!.text.isNotEmpty
            ? double.tryParse(_controllers['heatingKwhIndex']!.text)
            : null,
        heatingM3Index: _inventory!.heatingM3Index,
        keysApartment: int.tryParse(_controllers['keysApartment']!.text) ?? 0,
        keysMailbox: int.tryParse(_controllers['keysMailbox']!.text) ?? 0,
        keysCellar: int.tryParse(_controllers['keysCellar']!.text) ?? 0,
        accessCards: int.tryParse(_controllers['accessCards']!.text) ?? 0,
        parkingRemotes: int.tryParse(_controllers['parkingRemotes']!.text) ?? 0,
        status: _inventory!.status,
        ownerSignedAt: _inventory!.ownerSignedAt,
        tenantSignedAt: _inventory!.tenantSignedAt,
        ownerSignatureData: _inventory!.ownerSignatureData,
        tenantSignatureData: _inventory!.tenantSignatureData,
        pdfUrl: _inventory!.pdfUrl,
        roomEntries: _inventory!.roomEntries,
        createdAt: _inventory!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _inventoryService.updateInventory(widget.inventoryId, updatedInventory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('État des lieux enregistré')),
        );
      }
      _loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  Future<void> _signInventory(String signatureData, bool isOwner) async {
    setState(() => _isSigning = true);
    try {
      if (isOwner) {
        await _inventoryService.signInventoryByOwner(widget.inventoryId, signatureData);
      } else {
        await _inventoryService.signInventoryByTenant(widget.inventoryId, signatureData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('État des lieux signé avec succès')),
        );
      }
      _loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la signature: $e')),
        );
      }
    } finally {
      setState(() => _isSigning = false);
    }
  }
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }
  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/inventories/${widget.inventoryId}/generate-pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF généré: ${data['pdfUrl']}')),
          );
        }
        _loadInventory();
      } else {
        // extraction du message d'erreur
        String errorMessage = 'Erreur lors de la génération du PDF';

        try {
          final err = jsonDecode(response.body);
          if (err['message'] != null) {
            errorMessage = err['message'];
          } else {
            errorMessage = response.body; // fallback : texte brut
          }
        } catch (_) {
          errorMessage = response.body; // non JSON
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  void _showSignatureDialog(bool isOwner) {
    showDialog(
      context: context,
      builder: (context) => SignaturePadWidget(
        title: isOwner ? 'Signature du Propriétaire' : 'Signature du Locataire',
        onSignatureSaved: (signatureData) {
          _signInventory(signatureData, isOwner);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('État des Lieux')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_inventory == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('État des Lieux')),
        body: const Center(child: Text('État des lieux introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_inventory!.type == 'ENTRY' ? 'État des lieux d\'entrée' : 'État des lieux de sortie'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInventory,
          ),
          if (_inventory!.status == 'SIGNED' && _inventory!.pdfUrl == null)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isGeneratingPdf ? null : _generatePdf,
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
                    const Text(
                      'Relevés de Compteurs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controllers['electricityMeterNumber'],
                      decoration: const InputDecoration(labelText: 'N° compteur électricité'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers['electricityDayIndex'],
                            decoration: const InputDecoration(labelText: 'Index jour (kWh)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controllers['electricityNightIndex'],
                            decoration: const InputDecoration(labelText: 'Index nuit (kWh)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controllers['waterMeterNumber'],
                      decoration: const InputDecoration(labelText: 'N° compteur eau'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers['waterIndex'],
                      decoration: const InputDecoration(labelText: 'Index eau'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controllers['heatingMeterNumber'],
                      decoration: const InputDecoration(labelText: 'N° compteur chauffage'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers['heatingKwhIndex'],
                      decoration: const InputDecoration(labelText: 'Index chauffage (kWh)'),
                      keyboardType: TextInputType.number,
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
                    const Text(
                      'Clés Remises',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controllers['keysApartment'],
                      decoration: const InputDecoration(labelText: 'Clés appartement'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _controllers['keysMailbox'],
                      decoration: const InputDecoration(labelText: 'Clés boîte aux lettres'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _controllers['keysCellar'],
                      decoration: const InputDecoration(labelText: 'Clés cave'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _controllers['accessCards'],
                      decoration: const InputDecoration(labelText: 'Cartes d\'accès'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _controllers['parkingRemotes'],
                      decoration: const InputDecoration(labelText: 'Télécommandes parking'),
                      keyboardType: TextInputType.number,
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
                      children: [
                        Icon(Icons.meeting_room_rounded, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Pièces',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cliquez sur une pièce pour ajouter une description et des photos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_inventory!.roomEntries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aucune pièce enregistrée',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      ..._inventory!.roomEntries.map((entry) {
                        final hasPhotos = entry.photos != null && entry.photos!.isNotEmpty;
                        final hasDescription = entry.description != null && entry.description!.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: hasDescription || hasPhotos
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              child: Icon(
                                hasDescription || hasPhotos
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: hasDescription || hasPhotos
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              entry.sectionName ?? 'Pièce',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDescription)
                                  Text(
                                    entry.description!.length > 50
                                        ? '${entry.description!.substring(0, 50)}...'
                                        : entry.description!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  )
                                else
                                  Text(
                                    'Pas de description',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                  ),
                                if (hasPhotos)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.photo, size: 14, color: Colors.blue[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${entry.photos!.length} photo(s)',
                                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InventoryRoomDetailScreen(
                                    inventoryId: widget.inventoryId,
                                    roomEntry: entry,
                                    onUpdated: _loadInventory,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
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
                    const Text(
                      'Signatures',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                _inventory!.ownerSignedAt != null
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: _inventory!.ownerSignedAt != null
                                    ? Colors.green
                                    : Colors.orange,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text('Propriétaire', style: TextStyle(fontWeight: FontWeight.bold)),
                              if (_inventory!.ownerSignedAt == null)
                                ElevatedButton(
                                  onPressed: _isSigning ? null : () => _showSignatureDialog(true),
                                  child: const Text('Signer'),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                _inventory!.tenantSignedAt != null
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: _inventory!.tenantSignedAt != null
                                    ? Colors.green
                                    : Colors.orange,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text('Locataire', style: TextStyle(fontWeight: FontWeight.bold)),
                              if (_inventory!.tenantSignedAt == null)
                                ElevatedButton(
                                  onPressed: _isSigning ? null : () => _showSignatureDialog(false),
                                  child: const Text('Signer'),
                                ),
                            ],
                          ),
                        ),
                      ],
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
