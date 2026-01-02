import 'package:flutter/material.dart';
import '../../models/lease_contract_model.dart';
import '../../services/lease_contract_service.dart';
import 'lease_contract_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class LeaseContractsScreen extends StatefulWidget {
  const LeaseContractsScreen({Key? key}) : super(key: key);

  @override
  State<LeaseContractsScreen> createState() => _LeaseContractsScreenState();
}

class _LeaseContractsScreenState extends State<LeaseContractsScreen> {
  final LeaseContractService _leaseService = LeaseContractService();
  List<LeaseContractModel>? _contracts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await _leaseService.getMyContracts();
      setState(() {
        _contracts = contracts;
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

  String _getStatusText(String status) {
    switch (status) {
      case 'DRAFT':
        return 'Brouillon';
      case 'PENDING_SIGNATURE':
        return 'En attente de signature';
      case 'SIGNED':
        return 'Signé';
      case 'ACTIVE':
        return 'Actif';
      case 'TERMINATED':
        return 'Terminé';
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
      case 'ACTIVE':
        return Colors.blue;
      case 'TERMINATED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Contrats de Bail',
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
                  onRefresh: _loadContracts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contracts!.length,
                    itemBuilder: (context, index) {
                      final contract = _contracts![index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeaseContractDetailScreen(
                                  contractId: contract.id,
                                ),
                              ),
                            ).then((_) => _loadContracts());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Appartement ${contract.apartmentId.split('-').last}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(contract.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(contract.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Propriétaire: ${contract.ownerName}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Locataire: ${contract.tenantName}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Loyer actuel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${contract.currentRentAmount.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Début',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${contract.startDate.day}/${contract.startDate.month}/${contract.startDate.year}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
