import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lease_contract_model.dart';
import '../../services/lease_contract_service.dart';
import '../../widgets/signature_pad_widget.dart';

class LeaseContractDetailScreen extends StatefulWidget {
  final String contractId;

  const LeaseContractDetailScreen({Key? key, required this.contractId}) : super(key: key);

  @override
  State<LeaseContractDetailScreen> createState() => _LeaseContractDetailScreenState();
}

class _LeaseContractDetailScreenState extends State<LeaseContractDetailScreen> {
  final LeaseContractService _leaseService = LeaseContractService();
  LeaseContractModel? _contract;
  bool _isLoading = true;
  bool _isSigning = false;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    setState(() => _isLoading = true);
    try {
      final contract = await _leaseService.getContractById(widget.contractId);
      setState(() {
        _contract = contract;
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

  Future<void> _signContract(String signatureData, bool isOwner) async {
    setState(() => _isSigning = true);
    try {
      if (isOwner) {
        await _leaseService.signContractByOwner(widget.contractId, signatureData);
      } else {
        await _leaseService.signContractByTenant(widget.contractId, signatureData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrat signé avec succès')),
        );
      }
      _loadContract();
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

  void _showSignatureDialog(bool isOwner) {
    showDialog(
      context: context,
      builder: (context) => SignaturePadWidget(
        title: isOwner ? 'Signature du Propriétaire' : 'Signature du Locataire',
        onSignatureSaved: (signatureData) {
          _signContract(signatureData, isOwner);
        },
      ),
    );
  }

  Future<void> _generateAndOpenPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfUrl = await _leaseService.generateContractPdf(widget.contractId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF généré avec succès')),
        );

        final Uri url = Uri.parse(pdfUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Impossible d\'ouvrir le PDF: $pdfUrl')),
            );
          }
        }
      }

      _loadContract();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du Contrat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_contract == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du Contrat')),
        body: const Center(child: Text('Contrat introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrat de Bail'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGeneratingPdf ? null : _generateAndOpenPdf,
        icon: _isGeneratingPdf
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_isGeneratingPdf ? 'Génération...' : 'Générer PDF'),
        backgroundColor: _isGeneratingPdf ? Colors.grey : Colors.red,
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
                      'Informations générales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Appartement', _contract!.apartmentId.split('-').last),
                    _buildInfoRow('Propriétaire', _contract!.ownerName),
                    _buildInfoRow('Locataire', _contract!.tenantName),
                    _buildInfoRow('Date de début', '${_contract!.startDate.day}/${_contract!.startDate.month}/${_contract!.startDate.year}'),
                    if (_contract!.endDate != null)
                      _buildInfoRow('Date de fin', '${_contract!.endDate!.day}/${_contract!.endDate!.month}/${_contract!.endDate!.year}'),
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
                      'Informations financières',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Loyer initial', '${_contract!.initialRentAmount.toStringAsFixed(2)} €'),
                    _buildInfoRow('Loyer actuel', '${_contract!.currentRentAmount.toStringAsFixed(2)} €', highlight: true),
                    if (_contract!.depositAmount != null)
                      _buildInfoRow('Caution', '${_contract!.depositAmount!.toStringAsFixed(2)} €'),
                    if (_contract!.chargesAmount != null)
                      _buildInfoRow('Charges', '${_contract!.chargesAmount!.toStringAsFixed(2)} €'),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                _contract!.ownerSignedAt != null
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: _contract!.ownerSignedAt != null
                                    ? Colors.green
                                    : Colors.orange,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Propriétaire',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _contract!.ownerSignedAt != null
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              if (_contract!.ownerSignedAt != null)
                                Text(
                                  'Signé le ${_contract!.ownerSignedAt!.day}/${_contract!.ownerSignedAt!.month}/${_contract!.ownerSignedAt!.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (_contract!.ownerSignedAt == null)
                                const SizedBox(height: 8),
                              if (_contract!.ownerSignedAt == null)
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
                                _contract!.tenantSignedAt != null
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: _contract!.tenantSignedAt != null
                                    ? Colors.green
                                    : Colors.orange,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Locataire',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _contract!.tenantSignedAt != null
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              if (_contract!.tenantSignedAt != null)
                                Text(
                                  'Signé le ${_contract!.tenantSignedAt!.day}/${_contract!.tenantSignedAt!.month}/${_contract!.tenantSignedAt!.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (_contract!.tenantSignedAt == null)
                                const SizedBox(height: 8),
                              if (_contract!.tenantSignedAt == null)
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
            if (_contract!.pdfUrl != null && _contract!.pdfUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: InkWell(
                  onTap: () async {
                    try {
                      final Uri url = Uri.parse(_contract!.pdfUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PDF du Contrat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cliquez pour ouvrir le PDF',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (_contract!.indexations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historique des indexations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._contract!.indexations.map((indexation) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${indexation.indexationDate.day}/${indexation.indexationDate.month}/${indexation.indexationDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Taux: ${(indexation.indexationRate * 100).toStringAsFixed(2)}%',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${indexation.newAmount.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    'Avant: ${indexation.previousAmount.toStringAsFixed(2)} €',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue : Colors.black,
              fontSize: highlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
