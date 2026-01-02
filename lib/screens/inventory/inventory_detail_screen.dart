import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
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

class _InventoryDetailScreenState extends State<InventoryDetailScreen> with SingleTickerProviderStateMixin {
  final InventoryService _inventoryService = InventoryService();
  final StorageService _storageService = StorageService();
  InventoryModel? _inventory;
  bool _isLoading = true;
  bool _isSigning = false;
  bool _isGeneratingPdf = false;
  late TabController _tabController;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          SnackBar(
            content: Text('Erreur: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('État des lieux enregistré'),
              ],
            ),
            backgroundColor: const Color(0xFF38A169),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.verified, color: Colors.white),
                SizedBox(width: 12),
                Text('État des lieux signé avec succès'),
              ],
            ),
            backgroundColor: const Color(0xFF38A169),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la signature: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.picture_as_pdf, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('PDF généré avec succès')),
                ],
              ),
              backgroundColor: const Color(0xFF38A169),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        _loadInventory();
      } else {
        String errorMessage = 'Erreur lors de la génération du PDF';
        try {
          final err = jsonDecode(response.body);
          if (err['message'] != null) {
            errorMessage = err['message'];
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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

  Widget _buildMetersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMeterCard(
            icon: Icons.electric_bolt_rounded,
            title: 'Électricité',
            color: const Color(0xFFFBBF24),
            children: [
              _buildStyledTextField(
                controller: _controllers['electricityMeterNumber']!,
                label: 'Numéro de compteur',
                icon: Icons.tag,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _controllers['electricityDayIndex']!,
                      label: 'Index jour (kWh)',
                      icon: Icons.wb_sunny,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _controllers['electricityNightIndex']!,
                      label: 'Index nuit (kWh)',
                      icon: Icons.nightlight_round,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMeterCard(
            icon: Icons.water_drop_rounded,
            title: 'Eau',
            color: const Color(0xFF3B82F6),
            children: [
              _buildStyledTextField(
                controller: _controllers['waterMeterNumber']!,
                label: 'Numéro de compteur',
                icon: Icons.tag,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _controllers['waterIndex']!,
                label: 'Index eau (m³)',
                icon: Icons.speed,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMeterCard(
            icon: Icons.thermostat_rounded,
            title: 'Chauffage',
            color: const Color(0xFFEF4444),
            children: [
              _buildStyledTextField(
                controller: _controllers['heatingMeterNumber']!,
                label: 'Numéro de compteur',
                icon: Icons.tag,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _controllers['heatingKwhIndex']!,
                label: 'Index chauffage (kWh)',
                icon: Icons.speed,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildKeyCard(
            icon: Icons.key_rounded,
            label: 'Clés appartement',
            controller: _controllers['keysApartment'],
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildKeyCard(
            icon: Icons.mail_rounded,
            label: 'Clés boîte aux lettres',
            controller: _controllers['keysMailbox'],
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildKeyCard(
            icon: Icons.warehouse_rounded,
            label: 'Clés cave',
            controller: _controllers['keysCellar'],
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          _buildKeyCard(
            icon: Icons.badge_rounded,
            label: 'Cartes d\'accès',
            controller: _controllers['accessCards'],
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _buildKeyCard(
            icon: Icons.directions_car_rounded,
            label: 'Télécommandes parking',
            controller: _controllers['parkingRemotes'],
            color: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2196F3).withOpacity(0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pièces du logement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_inventory?.roomEntries.length ?? 0} pièce(s) à documenter',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _inventory!.roomEntries.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune pièce enregistrée',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _inventory!.roomEntries.length,
            itemBuilder: (context, index) {
              final entry = _inventory!.roomEntries[index];
              final hasPhotos = entry.photos != null && entry.photos!.isNotEmpty;
              final hasDescription = entry.description != null && entry.description!.isNotEmpty;
              final isComplete = hasPhotos && hasDescription;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isComplete
                                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isComplete ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.sectionName ?? 'Pièce',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (hasDescription)
                                  Text(
                                    entry.description!.length > 40
                                        ? '${entry.description!.substring(0, 40)}...'
                                        : entry.description!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF718096),
                                    ),
                                  )
                                else
                                  const Text(
                                    'Aucune description',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFA0AEC0),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (hasPhotos) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.photo_camera_rounded,
                                          size: 14,
                                          color: Color(0xFF2196F3),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${entry.photos!.length} photo(s)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2196F3),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMeterCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
      ),
    );
  }

  Widget _buildKeyCard({
    required IconData icon,
    required String label,
    required TextEditingController? controller,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(

        title: Text(
          'État des Lieux',
          style: AppTheme.titleStyle.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryDark,
              ],
            ),
          ),
        ),
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      );
    }


    if (_inventory == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('État des Lieux'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'État des lieux introuvable',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final bool allSigned = _inventory!.ownerSignedAt != null && _inventory!.tenantSignedAt != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _inventory!.type == 'ENTRY' ? 'État des lieux d\'entrée' : 'État des lieux de sortie',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              allSigned ? 'Signé ✓' : 'En attente de signature',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: allSigned ? const Color(0xFF38A169) : const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _saveInventory,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          if (_inventory!.status == 'SIGNED' && _inventory!.pdfUrl == null)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _generatePdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: const Color(0xFF718096),
              indicatorColor: const Color(0xFF2196F3),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Compteurs', icon: Icon(Icons.electric_meter_rounded, size: 20)),
                Tab(text: 'Clés', icon: Icon(Icons.vpn_key_rounded, size: 20)),
                Tab(text: 'Pièces', icon: Icon(Icons.meeting_room_rounded, size: 20)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMetersTab(),
                _buildKeysTab(),
                _buildRoomsTab(),
              ],
            ),
          ),
          if (!allSigned)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSignatureButton(
                      label: 'Propriétaire',
                      isSigned: _inventory!.ownerSignedAt != null,
                      onPressed: () => _showSignatureDialog(true),
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSignatureButton(
                      label: 'Locataire',
                      isSigned: _inventory!.tenantSignedAt != null,
                      onPressed: () => _showSignatureDialog(false),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignatureButton({
    required String label,
    required bool isSigned,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSigned
            ? LinearGradient(
          colors: [const Color(0xFF38A169), const Color(0xFF2F855A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isSigned ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSigned ? null : Border.all(color: color, width: 2),
        boxShadow: isSigned
            ? [
          BoxShadow(
            color: const Color(0xFF38A169).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSigned || _isSigning ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSigned ? Icons.verified_rounded : Icons.edit_rounded,
                  color: isSigned ? Colors.white : color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSigned ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSigned ? 'Signé' : 'Signer',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSigned ? Colors.white.withOpacity(0.9) : color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}