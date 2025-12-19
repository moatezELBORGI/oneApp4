import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../models/lease_contract_model.dart';
import '../../services/inventory_service.dart';
import '../../services/lease_contract_service.dart';
import 'inventory_detail_screen.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _getTypeText(String type) {
    return type == 'ENTRY' ? 'État des lieux d\'entrée' : 'État des lieux de sortie';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'DRAFT':
        return 'Brouillon';
      case 'PENDING_SIGNATURE':
        return 'En attente de signature';
      case 'SIGNED':
        return 'Signé';
      case 'FINALIZED':
        return 'Finalisé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'PENDING_SIGNATURE':
        return Colors.orange;
      case 'SIGNED':
        return Colors.green;
      case 'FINALIZED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _createInventory(String contractId) async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type d\'état des lieux'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('État des lieux d\'entrée'),
              leading: const Icon(Icons.login),
              onTap: () => Navigator.pop(context, 'ENTRY'),
            ),
            ListTile(
              title: const Text('État des lieux de sortie'),
              leading: const Icon(Icons.logout),
              onTap: () => Navigator.pop(context, 'EXIT'),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('État des lieux créé avec succès')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryDetailScreen(inventoryId: inventory.id),
            ),
          ).then((_) => _loadData());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('États des Lieux'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts == null || _contracts!.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun contrat de bail',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contracts!.length,
                    itemBuilder: (context, index) {
                      final contract = _contracts![index];
                      final inventories = _inventoriesByContract[contract.id] ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            'Contrat ${contract.apartmentId.split('-').last}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(contract.ownerName),
                          children: [
                            if (inventories.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text('Aucun état des lieux'),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _createInventory(contract.id),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Créer un état des lieux'),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...inventories.map((inventory) {
                                return ListTile(
                                  leading: Icon(
                                    inventory.type == 'ENTRY' ? Icons.login : Icons.logout,
                                    color: inventory.type == 'ENTRY' ? Colors.green : Colors.red,
                                  ),
                                  title: Text(_getTypeText(inventory.type)),
                                  subtitle: Text(
                                    '${inventory.inventoryDate.day}/${inventory.inventoryDate.month}/${inventory.inventoryDate.year}',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(inventory.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(inventory.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InventoryDetailScreen(
                                          inventoryId: inventory.id,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                );
                              }).toList(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextButton.icon(
                                onPressed: () => _createInventory(contract.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvel état des lieux'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
