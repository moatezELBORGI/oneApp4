import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lease_contract_model.dart';
import '../../services/lease_contract_service.dart';
import '../../utils/app_theme.dart';
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
        _showSnackBar('Erreur: $e', isError: true);
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
        _showSnackBar('Contrat signé avec succès', isError: false);
      }
      _loadContract();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la signature: $e', isError: true);
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
        _showSnackBar('PDF généré avec succès', isError: false);

        final Uri url = Uri.parse(pdfUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            _showSnackBar('Impossible d\'ouvrir le PDF', isError: true);
          }
        }
      }

      _loadContract();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la génération du PDF: $e', isError: true);
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    if (_contract == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Détails du Contrat'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text('Contrat introuvable', style: AppTheme.subtitleStyle),
            ],
          ),
        ),
      );
    }

    final bool isFullySigned = _contract!.ownerSignedAt != null && _contract!.tenantSignedAt != null;

    return Scaffold(
      appBar: AppBar(
        title:  Text('Contrat de Bail',   style: AppTheme.titleStyle.copyWith(
          color: Colors.white,
          fontSize: 16,
        ),),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_contract!.pdfUrl != null && _contract!.pdfUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppTheme.errorColor),
              onPressed: () async {
                try {
                  final Uri url = Uri.parse(_contract!.pdfUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Erreur: $e', isError: true);
                  }
                }
              },
              tooltip: 'Voir le PDF',
            ),
        ],
      ),
      floatingActionButton: isFullySigned
          ? FloatingActionButton.extended(
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
        backgroundColor: _isGeneratingPdf ? AppTheme.textSecondary : AppTheme.errorColor,
        elevation: 4,
      )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            if (isFullySigned)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: AppTheme.successColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contrat Actif',
                            style: AppTheme.subtitleStyle.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Toutes les signatures sont complètes',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: AppTheme.warningColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'En attente de signature',
                            style: AppTheme.subtitleStyle.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Le contrat nécessite des signatures',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Informations générales
            _buildSectionCard(
              title: 'Informations générales',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow(
                  icon: Icons.apartment,
                  label: 'Appartement',
                  value: _contract!.apartmentId.split('-').last,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Propriétaire',
                  value: _contract!.ownerName,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Locataire',
                  value: _contract!.tenantName,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date de début',
                  value: _formatDate(_contract!.startDate),
                ),
                if (_contract!.endDate != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.event,
                    label: 'Date de fin',
                    value: _formatDate(_contract!.endDate!),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Informations financières
            _buildSectionCard(
              title: 'Informations financières',
              icon: Icons.euro,
              children: [
                _buildFinancialRow(
                  label: 'Loyer initial',
                  value: _contract!.initialRentAmount,
                  icon: Icons.attach_money,
                ),
                const Divider(height: 24),
                _buildFinancialRow(
                  label: 'Loyer actuel',
                  value: _contract!.currentRentAmount,
                  icon: Icons.payments,
                  isHighlighted: true,
                ),
                if (_contract!.depositAmount != null) ...[
                  const Divider(height: 24),
                  _buildFinancialRow(
                    label: 'Caution',
                    value: _contract!.depositAmount!,
                    icon: Icons.security,
                  ),
                ],
                if (_contract!.chargesAmount != null) ...[
                  const Divider(height: 24),
                  _buildFinancialRow(
                    label: 'Charges',
                    value: _contract!.chargesAmount!,
                    icon: Icons.receipt_long,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Signatures
            _buildSectionCard(
              title: 'Signatures',
              icon: Icons.draw,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSignatureCard(
                        title: 'Propriétaire',
                        name: _contract!.ownerName,
                        signedAt: _contract!.ownerSignedAt,
                        onSign: () => _showSignatureDialog(true),
                        isSigning: _isSigning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSignatureCard(
                        title: 'Locataire',
                        name: _contract!.tenantName,
                        signedAt: _contract!.tenantSignedAt,
                        onSign: () => _showSignatureDialog(false),
                        isSigning: _isSigning,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (_contract!.indexations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Historique des indexations',
                icon: Icons.trending_up,
                children: _contract!.indexations.map((indexation) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.show_chart,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(indexation.indexationDate),
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Taux: ${(indexation.indexationRate * 100).toStringAsFixed(2)}%',
                                  style: AppTheme.captionStyle,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${indexation.newAmount.toStringAsFixed(2)} €',
                                style: AppTheme.subtitleStyle.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Avant: ${indexation.previousAmount.toStringAsFixed(2)} €',
                                style: AppTheme.captionStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTheme.titleStyle),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.captionStyle),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow({
    required String label,
    required double value,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppTheme.primaryColor.withOpacity(0.1)
                : AppTheme.textSecondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isHighlighted ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} €',
          style: AppTheme.subtitleStyle.copyWith(
            color: isHighlighted ? AppTheme.primaryColor : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isHighlighted ? 20 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureCard({
    required String title,
    required String name,
    required DateTime? signedAt,
    required VoidCallback onSign,
    required bool isSigning,
  }) {
    final bool isSigned = signedAt != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSigned
            ? AppTheme.successColor.withOpacity(0.05)
            : AppTheme.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSigned
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isSigned ? Icons.check_circle : Icons.pending,
            color: isSigned ? AppTheme.successColor : AppTheme.warningColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: isSigned ? AppTheme.successColor : AppTheme.warningColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (isSigned)
            Text(
              'Signé le\n${_formatDate(signedAt)}',
              style: AppTheme.captionStyle.copyWith(
                color: AppTheme.successColor,
              ),
              textAlign: TextAlign.center,
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSigning ? null : onSign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Signer',
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}