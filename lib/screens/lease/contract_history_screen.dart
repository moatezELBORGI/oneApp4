import 'package:flutter/material.dart';
import '../../services/lease_contract_enhanced_service.dart';
import '../../utils/app_theme.dart';
import 'lease_contract_detail_screen.dart';
import '../inventory/inventories_screen.dart';

class ContractHistoryScreen extends StatefulWidget {
  final String apartmentId;

  const ContractHistoryScreen({
    Key? key,
    required this.apartmentId,
  }) : super(key: key);

  @override
  State<ContractHistoryScreen> createState() => _ContractHistoryScreenState();
}

class _ContractHistoryScreenState extends State<ContractHistoryScreen> {
  final LeaseContractEnhancedService _service = LeaseContractEnhancedService();
  List<Map<String, dynamic>>? _contracts;
  List<Map<String, dynamic>>? _filteredContracts;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContracts();
    _searchController.addListener(_filterContracts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await _service.getContractsByApartmentWithInventoryStatus(widget.apartmentId);
      contracts.sort((a, b) {
        final dateA = DateTime.parse(a['createdAt'] ?? '');
        final dateB = DateTime.parse(b['createdAt'] ?? '');
        return dateB.compareTo(dateA);
      });
      setState(() {
        _contracts = contracts;
        _filteredContracts = contracts;
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

  void _filterContracts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContracts = _contracts?.where((contract) {
        final tenant = contract['tenant'];
        if (tenant == null) return false;
        final tenantName = '${tenant['fname']} ${tenant['lname']}'.toLowerCase();
        final startDate = contract['startDate'] ?? '';
        return tenantName.contains(query) || startDate.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Historique des contrats'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/create-contract',
                arguments: widget.apartmentId,
              ).then((_) => _loadContracts());
            },
            tooltip: 'Nouveau contrat',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou date...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContracts == null || _filteredContracts!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun contrat trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadContracts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredContracts!.length,
                          itemBuilder: (context, index) {
                            final contract = _filteredContracts![index];
                            return _buildContractCard(contract);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final tenant = contract['tenant'];
    final owner = contract['owner'];
    final status = contract['status'] ?? '';
    final hasEntryInventory = contract['hasEntryInventory'] ?? false;
    final hasExitInventory = contract['hasExitInventory'] ?? false;
    final isSigned = status == 'SIGNED';
    final startDate = contract['startDate'] ?? '';
    final endDate = contract['endDate'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tenant?['fname'] ?? ''} ${tenant?['lname'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Du $startDate ${endDate != null ? "au $endDate" : ""}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSigned ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSigned ? 'Signé' : 'Brouillon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSigned ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            if (isSigned && !hasEntryInventory) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'État des lieux d\'entrée non effectué',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaseContractDetailScreen(
                            contractId: contract['id'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Voir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InventoriesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('États'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
