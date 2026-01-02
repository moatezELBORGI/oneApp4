import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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

class _ContractHistoryScreenState extends State<ContractHistoryScreen>
    with SingleTickerProviderStateMixin {
  final LeaseContractEnhancedService _service = LeaseContractEnhancedService();
  List<Map<String, dynamic>>? _contracts;
  List<Map<String, dynamic>>? _filteredContracts;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late final DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _loadContracts();
    _searchController.addListener(_filterContracts);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('fr_FR', null);
    _dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
        _showErrorSnackBar('Erreur lors du chargement: $e');
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildStatsCard(),
              ],
            ),
          ),
          _buildContractsList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
       floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Historique des contrats',
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyStyle,
        decoration: InputDecoration(
          hintText: 'Rechercher un contrat...',
          hintStyle: AppTheme.bodyStyle.copyWith(color: AppTheme.textLight),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary, size: 24),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: AppTheme.textSecondary),
            onPressed: () {
              _searchController.clear();
              _filterContracts();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_contracts == null) return const SizedBox.shrink();

    final totalContracts = _contracts!.length;
    final activeContracts = _contracts!.where((c) => c['status'] == 'SIGNED').length;
    final draftContracts = _contracts!.where((c) => c['status'] == 'DRAFT').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.description,
            label: 'Total',
            value: totalContracts.toString(),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Actifs',
            value: activeContracts.toString(),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            icon: Icons.drafts,
            label: 'Brouillons',
            value: draftContracts.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: AppTheme.captionStyle.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildContractsList() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_filteredContracts == null || _filteredContracts!.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.1 * (index + 1)),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index + 1) * 0.1).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                )),
                child: _buildContractCard(_filteredContracts![index], index),
              ),
            );
          },
          childCount: _filteredContracts!.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun contrat trouvé',
            style: AppTheme.titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer votre premier contrat',
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/create-contract',
                arguments: widget.apartmentId,
              ).then((_) => _loadContracts());
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer un contrat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract, int index) {
    final tenant = contract['tenant'];
    final status = contract['status'] ?? '';
    final hasEntryInventory = contract['hasEntryInventory'] ?? false;
    final isSigned = status == 'SIGNED';
    final startDate = contract['startDate'] ?? '';
    final endDate = contract['endDate'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaseContractDetailScreen(
                  contractId: contract['id'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(tenant),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tenant?['fname'] ?? ''} ${tenant?['lname'] ?? ''}',
                            style: AppTheme.subtitleStyle,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatDateRange(startDate, endDate),
                                  style: AppTheme.captionStyle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(isSigned),
                  ],
                ),
                if (isSigned && !hasEntryInventory) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'État des lieux d\'entrée requis',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
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
                      child: _buildActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'Détails',
                        color: AppTheme.primaryColor,
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.fact_check_outlined,
                        label: 'États',
                        color: AppTheme.accentColor,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoriesScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isSigned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSigned
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSigned ? AppTheme.successColor : AppTheme.warningColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isSigned ? 'Signé' : 'Brouillon',
            style: AppTheme.captionStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: isSigned ? AppTheme.successColor : AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/create-contract',
            arguments: widget.apartmentId,
          ).then((_) => _loadContracts());
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nouveau contrat',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(Map<String, dynamic>? tenant) {
    if (tenant == null) return '??';
    final fname = tenant['fname'] ?? '';
    final lname = tenant['lname'] ?? '';
    final firstInitial = fname.isNotEmpty ? fname[0].toUpperCase() : '';
    final lastInitial = lname.isNotEmpty ? lname[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  String _formatDateRange(String startDate, String? endDate) {
    try {
      final start = DateTime.parse(startDate);
      final startFormatted = _dateFormat.format(start);

      if (endDate != null && endDate.isNotEmpty) {
        final end = DateTime.parse(endDate);
        final endFormatted = _dateFormat.format(end);
        return '$startFormatted → $endFormatted';
      }
      return 'Depuis le $startFormatted';
    } catch (e) {
      return startDate;
    }
  }
}