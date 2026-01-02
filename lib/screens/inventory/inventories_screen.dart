import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../models/lease_contract_model.dart';
import '../../services/inventory_service.dart';
import '../../services/lease_contract_service.dart';
import 'inventory_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class InventoriesScreen extends StatefulWidget {
  const InventoriesScreen({Key? key}) : super(key: key);

  @override
  State<InventoriesScreen> createState() => _InventoriesScreenState();
}

class _InventoriesScreenState extends State<InventoriesScreen> {
  final LeaseContractService _leaseService = LeaseContractService();
  final InventoryService _inventoryService = InventoryService();
  List<LeaseContractModel>? _contracts;
  Map<String, List<InventoryModel>> _inventoriesByContract = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await _leaseService.getMyContracts();
      Map<String, List<InventoryModel>> inventories = {};

      for (var contract in contracts) {
        final contractInventories = await _inventoryService.getInventoriesByContract(contract.id);
        inventories[contract.id] = contractInventories;
      }

      setState(() {
        _contracts = contracts;
        _inventoriesByContract = inventories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Erreur de chargement', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getTypeText(String type) {
    return type == 'ENTRY' ? 'Entrée' : 'Sortie';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'DRAFT': return 'Brouillon';
      case 'PENDING_SIGNATURE': return 'En attente';
      case 'SIGNED': return 'Signé';
      case 'FINALIZED': return 'Finalisé';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT': return Colors.grey;
      case 'PENDING_SIGNATURE': return Colors.orange;
      case 'SIGNED': return Colors.green;
      case 'FINALIZED': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Future<void> _createInventory(String contractId) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nouvel état des lieux',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _TypeButton(
              icon: Icons.home,
              label: 'État d\'entrée',
              color: Colors.green,
              onTap: () => Navigator.pop(context, 'ENTRY'),
            ),
            const SizedBox(height: 12),
            _TypeButton(
              icon: Icons.exit_to_app,
              label: 'État de sortie',
              color: Colors.orange,
              onTap: () => Navigator.pop(context, 'EXIT'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );

    if (type != null) {
      try {
        final inventory = await _inventoryService.createInventory(
          contractId: contractId,
          type: type,
          inventoryDate: DateTime.now(),
        );

        if (mounted) {
          _showSnackBar('État des lieux créé');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryDetailScreen(inventoryId: inventory.id),
            ),
          ).then((_) => _loadData());
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erreur lors de la création', isError: true);
        }
      }
    }
  }

  int _getTotalInventories() {
    return _inventoriesByContract.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomAppBar(
        title: 'États des lieux',
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts == null || _contracts!.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_getTotalInventories() > 0) ...[
              _buildSummaryCard(),
              const SizedBox(height: 16),
            ],
            ..._contracts!.map((contract) {
              final inventories = _inventoriesByContract[contract.id] ?? [];
              return _buildContractCard(contract, inventories);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getTotalInventories()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getTotalInventories() > 1 ? 'états des lieux' : 'état des lieux',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            '${_contracts!.length} ${_contracts!.length > 1 ? "contrats" : "contrat"}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(LeaseContractModel contract, List<InventoryModel> inventories) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.apartment, color: Colors.blue.shade700, size: 22),
            ),
            title: Text(
              'Contrat ${contract.apartmentId.split('-').last}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(contract.ownerName, style: const TextStyle(fontSize: 13)),
            trailing: inventories.isNotEmpty
                ? CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              radius: 16,
              child: Text(
                '${inventories.length}',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : null,
          ),
          if (inventories.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: inventories
                    .map((inv) => _buildInventoryItem(inv))
                    .toList(),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _createInventory(contract.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(InventoryModel inventory) {
    final isEntry = inventory.type == 'ENTRY';
    final color = isEntry ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryDetailScreen(inventoryId: inventory.id),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEntry ? Icons.home : Icons.exit_to_app,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeText(inventory.type),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inventory.inventoryDate.day}/${inventory.inventoryDate.month}/${inventory.inventoryDate.year}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(inventory.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(inventory.status),
                  style: TextStyle(
                    color: _getStatusColor(inventory.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}