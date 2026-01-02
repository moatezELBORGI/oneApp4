import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/claim_model.dart';
import '../../providers/claim_provider.dart';
import '../../services/apartment_details_service.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateClaimScreen extends StatefulWidget {
  const CreateClaimScreen({Key? key}) : super(key: key);

  @override
  State<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends State<CreateClaimScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _causeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();
  final PageController _pageController = PageController();

  final BuildingContextService _contextService = BuildingContextService();
  final ApartmentDetailsService _apartmentService = ApartmentDetailsService();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _selectedClaimTypes = [];
  List<String> _selectedAffectedApartments = [];
  List<File> _selectedPhotos = [];
  List<SimpleApartment> _buildingApartments = [];
  bool _isLoadingApartments = true;
  String? _userApartmentId;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadUserApartmentAndBuildings();

    // Add listeners to text controllers to update UI when text changes
    _causeController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  Future<void> _loadUserApartmentAndBuildings() async {
    try {
      final buildingId = await _contextService.getCurrentBuildingId();
      print('🏢 Current building ID: $buildingId');

      if (buildingId != null) {
        final apartments = await _apartmentService.getApartmentsByBuilding(buildingId);
        final userApartment = await _apartmentService.getCurrentUserApartment(buildingId);

        print('📋 Total apartments loaded: ${apartments.length}');
        print('👤 User apartment ID: ${userApartment?.id}');

        setState(() {
          _buildingApartments = apartments;
          _userApartmentId = userApartment?.id;
          _isLoadingApartments = false;
        });
      }
    } catch (e) {
      print('❌ Error in _loadUserApartmentAndBuildings: $e');
      setState(() {
        _isLoadingApartments = false;
      });
    }
  }

  @override
  void dispose() {
    _causeController.dispose();
    _descriptionController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(images.map((xFile) => File(xFile.path)));
        });
        _showSnackBar('${images.length} photo(s) ajoutée(s)', Icons.check_circle, Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection des images', Icons.error, Colors.red);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    _showSnackBar('Photo supprimée', Icons.delete, Colors.orange);
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _canGoToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedClaimTypes.isNotEmpty;
      case 1:
        return _causeController.text.trim().isNotEmpty;
      case 2:
        return _descriptionController.text.trim().isNotEmpty;
      case 3:
        return true; // Photos and apartments are optional
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (_canGoToNextStep()) {
      if (_currentStep < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentStep++;
        });
      } else {
        _submitClaim();
      }
    } else {
      _showSnackBar('Veuillez compléter cette étape', Icons.warning, Colors.orange);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez remplir tous les champs obligatoires', Icons.warning, Colors.orange);
      return;
    }

    if (_selectedClaimTypes.isEmpty) {
      _showSnackBar('Veuillez sélectionner au moins un type de sinistre', Icons.warning, Colors.orange);
      setState(() {
        _currentStep = 0;
        _pageController.jumpToPage(0);
      });
      return;
    }

    if (_userApartmentId == null) {
      _showSnackBar('Impossible de déterminer votre appartement', Icons.error, Colors.red);
      return;
    }

    final claimProvider = Provider.of<ClaimProvider>(context, listen: false);

    final success = await claimProvider.createClaim(
      apartmentId: _userApartmentId!,
      claimTypes: _selectedClaimTypes,
      cause: _causeController.text.trim(),
      description: _descriptionController.text.trim(),
      insuranceCompany: _insuranceCompanyController.text.trim().isEmpty
          ? null
          : _insuranceCompanyController.text.trim(),
      insurancePolicyNumber: _insurancePolicyController.text.trim().isEmpty
          ? null
          : _insurancePolicyController.text.trim(),
      affectedApartmentIds: _selectedAffectedApartments,
      photos: _selectedPhotos,
    );

    if (success) {
      Navigator.pop(context, true);
      _showSnackBar('Sinistre déclaré avec succès', Icons.check_circle, Colors.green);
    } else {
      _showSnackBar(claimProvider.errorMessage ?? 'Erreur inconnue', Icons.error, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimProvider = Provider.of<ClaimProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Déclarer un sinistre',  style: TextStyle(color: Colors.white)),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoadingApartments
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Chargement des informations...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1ClaimTypes(),
                  _buildStep2Cause(),
                  _buildStep3Description(),
                  _buildStep4Additional(),
                ],
              ),
            ),
          ),
          _buildNavigationButtons(claimProvider),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Type', 'Cause', 'Description', 'Finalisation'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Colors.green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1ClaimTypes() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildCard(
          icon: Icons.report_problem,
          iconColor: Colors.orange,
          title: 'Quel type de sinistre ?',
          isRequired: true,
          subtitle: 'Sélectionnez tous les types concernés',
          child: Column(
            children: ClaimType.values.map((type) {
              final isSelected = _selectedClaimTypes.contains(type.value);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    type.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : Colors.black87,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedClaimTypes.add(type.value);
                      } else {
                        _selectedClaimTypes.remove(type.value);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Cause() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: _buildCard(
        icon: Icons.lightbulb_outline,
        iconColor: Colors.blue,
        title: 'Quelle est la cause ?',
        isRequired: true,
        subtitle: 'Expliquez brièvement l\'origine du sinistre',
        child: CustomTextField(
          controller: _causeController,
          hint: 'Ex: Fuite d\'eau provenant du tuyau sous l\'évier...',
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez indiquer la cause';
            }
            return null;
          },
          label: '',
        ),
      ),
    );
  }

  Widget _buildStep3Description() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.description,
            iconColor: Colors.purple,
            title: 'Description détaillée',
            isRequired: true,
            subtitle: 'Décrivez les dégâts observés',
            child: CustomTextField(
              controller: _descriptionController,
              hint: 'Ex: L\'eau a endommagé le parquet du salon sur environ 2m². Le mur adjacent présente des traces d\'humidité...',
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez décrire les dégâts';
                }
                return null;
              },
              label: '',
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.shield,
            iconColor: Colors.green,
            title: 'Assurance RC familiale',
            isRequired: false,
            subtitle: 'Optionnel - Si vous avez une assurance',
            child: Column(
              children: [
                CustomTextField(
                  controller: _insuranceCompanyController,
                  hint: 'Nom de la compagnie d\'assurance',
                  label: '',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _insurancePolicyController,
                  hint: 'Numéro de police d\'assurance',
                  label: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Additional() {
    final otherApartments = _buildingApartments
        .where((apt) => apt.id != _userApartmentId)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.apartment,
            iconColor: Colors.teal,
            title: 'Appartements touchés',
            isRequired: false,
            subtitle: 'Optionnel - D\'autres appartements sont-ils affectés ?',
            child: otherApartments.isEmpty
                ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun autre appartement dans le bâtiment',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: otherApartments.map((apartment) {
                final isSelected = _selectedAffectedApartments.contains(apartment.id);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      'Appartement ${apartment.apartmentNumber}',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                      ),
                    ),
                    subtitle: apartment.floor != null
                        ? Text('Étage ${apartment.floor}')
                        : null,
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedAffectedApartments.add(apartment.id);
                        } else {
                          _selectedAffectedApartments.remove(apartment.id);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.photo_camera,
            iconColor: Colors.pink,
            title: 'Photos',
            isRequired: false,
            subtitle: 'Optionnel - Documentez les dégâts avec des photos',
            child: Column(
              children: [
                if (_selectedPhotos.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: FileImage(_selectedPhotos[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
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
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.primaryColor.withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          _selectedPhotos.isEmpty ? 'Ajouter des photos' : 'Ajouter plus de photos',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isRequired,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Requis',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ClaimProvider claimProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: claimProvider.isLoading ? null : _goToPreviousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: claimProvider.isLoading || !_canGoToNextStep()
                      ? [Colors.grey, Colors.grey]
                      : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: claimProvider.isLoading || !_canGoToNextStep() ? null : _goToNextStep,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: claimProvider.isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 3 ? 'Déclarer le sinistre' : 'Continuer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 3 ? Icons.send : Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}