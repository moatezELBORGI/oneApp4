import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'add_resident_screen.dart';

class Building3DViewScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;
  final List<Map<String, dynamic>> apartments;

  const Building3DViewScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
    required this.apartments,
  });

  @override
  State<Building3DViewScreen> createState() => _Building3DViewScreenState();
}

class _Building3DViewScreenState extends State<Building3DViewScreen>
    with SingleTickerProviderStateMixin {
  Map<int, List<Map<String, dynamic>>> _apartmentsByFloor = {};
  int _maxFloor = 0;
  int? _selectedFloor;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _organizeApartmentsByFloor();
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _organizeApartmentsByFloor() {
    _apartmentsByFloor.clear();
    _maxFloor = 0;

    for (var apartment in widget.apartments) {
      final floor = apartment['apartmentFloor'] as int? ?? 0;
      if (floor > _maxFloor) _maxFloor = floor;

      if (!_apartmentsByFloor.containsKey(floor)) {
        _apartmentsByFloor[floor] = [];
      }
      _apartmentsByFloor[floor]!.add(apartment);
    }
  }

  Color _getApartmentColor(Map<String, dynamic> apartment) {
    return apartment['resident'] != null ? Colors.green : Colors.red;
  }

  String _getApartmentStatus(Map<String, dynamic> apartment) {
    return apartment['resident'] != null ? 'Occupé' : 'Vide';
  }

  int _getOccupiedCount(int floor) {
    final apartments = _apartmentsByFloor[floor] ?? [];
    return apartments.where((apt) => apt['resident'] != null).length;
  }

  Future<void> _showApartmentDetails(Map<String, dynamic> apartment) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getApartmentColor(apartment).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.apartment,
                        color: _getApartmentColor(apartment),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apartment['apartmentLabel'] ?? 'N/A',
                            style: AppTheme.titleStyle.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getApartmentStatus(apartment),
                            style: TextStyle(
                              color: _getApartmentColor(apartment),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Numéro', apartment['apartmentNumber'] ?? 'N/A'),
                _buildDetailRow('Étage', '${apartment['apartmentFloor'] ?? 0}'),
                if (apartment['livingAreaSurface'] != null)
                  _buildDetailRow(
                    'Surface',
                    '${apartment['livingAreaSurface']} m²',
                  ),
                if (apartment['numberOfRooms'] != null)
                  _buildDetailRow(
                    'Pièces',
                    '${apartment['numberOfRooms']}',
                  ),
                if (apartment['numberOfBedrooms'] != null)
                  _buildDetailRow(
                    'Chambres',
                    '${apartment['numberOfBedrooms']}',
                  ),
                _buildDetailRow(
                  'Balcon/Terrasse',
                  apartment['haveBalconyOrTerrace'] == true ? 'Oui' : 'Non',
                ),
                _buildDetailRow(
                  'Meublé',
                  apartment['isFurnished'] == true ? 'Oui' : 'Non',
                ),
                if (apartment['resident'] != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Résident',
                    style: AppTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Nom',
                    '${apartment['resident']['fname'] ?? ''} ${apartment['resident']['lname'] ?? ''}'
                        .trim(),
                  ),
                  if (apartment['resident']['email'] != null)
                    _buildDetailRow('Email', apartment['resident']['email']),
                  if (apartment['resident']['phoneNumber'] != null)
                    _buildDetailRow(
                        'Téléphone', apartment['resident']['phoneNumber']),
                ] else ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Ajouter un résident',
                    onPressed: () async {
                      Navigator.pop(context);
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddResidentScreen(
                            apartmentId: apartment['idApartment'].toString(),
                            apartmentNumber:
                            apartment['apartmentNumber'] ?? 'N/A',
                          ),
                        ),
                      );
                      if (added == true) {
                        Navigator.pop(context, true);
                      }
                    },
                    backgroundColor: Colors.green,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue
      appBar: AppBar(
        title: Text('Vue 3D - ${widget.buildingName}'),
        elevation: 0,
        actions: [
          if (_selectedFloor != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedFloor = null;
                });
              },
            ),
        ],
      ),
      body: widget.apartments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun appartement',
              style: AppTheme.titleStyle.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : _selectedFloor == null
          ? _build3DBuilding()
          : _buildFloorApartments(_selectedFloor!),
    );
  }

  Widget _build3DBuilding() {
    final floors = _apartmentsByFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(Colors.green, 'Occupé'),
                  _buildLegendItem(Colors.red, 'Vide'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Touchez un étage pour voir les appartements',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: Building3DPainter(
                  floors: floors,
                  apartmentsByFloor: _apartmentsByFloor,
                  rotation: _rotationAnimation.value,
                  onFloorTap: (floor) {
                    setState(() {
                      _selectedFloor = floor;
                    });
                  },
                ),
                child: GestureDetector(
                  onTapDown: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final localPosition = details.localPosition;
                    final size = box.size;

                    _handleTap(localPosition, size, floors);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleTap(Offset position, Size size, List<int> floors) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final buildingHeight = size.height * 0.65;
    final floorHeight = buildingHeight / (_maxFloor + 2);

    for (int i = 0; i < floors.length; i++) {
      final floor = floors[i];
      final floorY = centerY + buildingHeight / 2 - (floor + 1) * floorHeight;

      if (position.dy >= floorY && position.dy <= floorY + floorHeight) {
        if (position.dx >= centerX - 140 && position.dx <= centerX + 140) {
          setState(() {
            _selectedFloor = floor;
          });
          break;
        }
      }
    }
  }

  Widget _buildFloorApartments(int floor) {
    final apartments = _apartmentsByFloor[floor] ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.layers,
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
                          'Étage $floor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${apartments.length} appartements',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_getOccupiedCount(floor)}/${apartments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: apartments.length,
            itemBuilder: (context, index) {
              return _buildApartmentCard(apartments[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildApartmentCard(Map<String, dynamic> apartment) {
    final color = _getApartmentColor(apartment);

    return InkWell(
      onTap: () => _showApartmentDetails(apartment),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  apartment['resident'] != null
                      ? Icons.home
                      : Icons.home_outlined,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                apartment['apartmentNumber']?.toString() ?? 'N/A',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getApartmentStatus(apartment),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (apartment['numberOfRooms'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${apartment['numberOfRooms']} pièces',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Building3DPainter extends CustomPainter {
  final List<int> floors;
  final Map<int, List<Map<String, dynamic>>> apartmentsByFloor;
  final double rotation;
  final Function(int) onFloorTap;

  Building3DPainter({
    required this.floors,
    required this.apartmentsByFloor,
    required this.rotation,
    required this.onFloorTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final buildingWidth = 280.0;
    final buildingDepth = 200.0;
    final buildingHeight = size.height * 0.65;
    final maxFloor = floors.isNotEmpty ? floors.reduce(math.max) : 0;
    final floorHeight = buildingHeight / (maxFloor + 2);

    // Dessiner le ciel avec gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF87CEEB),
          const Color(0xFFB0D4E8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Dessiner quelques nuages
    _drawClouds(canvas, size);

    // Sol avec texture
    final groundY = centerY + buildingHeight / 2 + 20;
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B9467),
          const Color(0xFF6B7447),
        ],
      ).createShader(Rect.fromLTWH(0, groundY, size.width, size.height - groundY));

    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      groundPaint,
    );

    // Ombre portée du bâtiment
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 20, groundY + 10),
        width: buildingWidth + 100,
        height: 80,
      ),
      shadowPaint,
    );

    // Dessiner l'immeuble étage par étage
    for (int i = 0; i <= maxFloor; i++) {
      final floor = i;
      final apartments = apartmentsByFloor[floor] ?? [];
      final occupiedCount =
          apartments.where((apt) => apt['resident'] != null).length;
      final occupancyRate =
      apartments.isEmpty ? 0.0 : occupiedCount / apartments.length;

      final floorY = centerY + buildingHeight / 2 - (floor + 1) * floorHeight;

      _drawFloor(
        canvas,
        centerX,
        floorY,
        buildingWidth,
        buildingDepth,
        floorHeight,
        floor,
        occupancyRate,
        rotation,
      );
    }

    // Toit moderne
    _drawRoof(
      canvas,
      centerX,
      centerY - buildingHeight / 2 + floorHeight / 2,
      buildingWidth,
      buildingDepth,
      floorHeight * 0.6,
      rotation,
    );

    // Antenne sur le toit
    _drawAntenna(
      canvas,
      centerX,
      centerY - buildingHeight / 2 + floorHeight / 2 - floorHeight * 0.6,
      rotation,
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Nuage 1
    _drawCloud(canvas, size.width * 0.2, 60, 80, cloudPaint);
    // Nuage 2
    _drawCloud(canvas, size.width * 0.7, 100, 100, cloudPaint);
    // Nuage 3
    _drawCloud(canvas, size.width * 0.5, 40, 60, cloudPaint);
  }

  void _drawCloud(Canvas canvas, double x, double y, double size, Paint paint) {
    canvas.drawCircle(Offset(x, y), size * 0.4, paint);
    canvas.drawCircle(Offset(x + size * 0.3, y), size * 0.3, paint);
    canvas.drawCircle(Offset(x - size * 0.3, y), size * 0.35, paint);
    canvas.drawCircle(Offset(x, y - size * 0.2), size * 0.35, paint);
  }

  void _drawFloor(
      Canvas canvas,
      double centerX,
      double floorY,
      double width,
      double depth,
      double height,
      int floorNumber,
      double occupancyRate,
      double rotation,
      ) {
    final angle = rotation * 0.2;

    // Couleur du bâtiment moderne
    final baseColor = const Color(0xFFE8E8E8);
    final accentColor = Color.lerp(
      const Color(0xFFFF6B6B),
      const Color(0xFF51CF66),
      occupancyRate,
    )!;

    // Face avant avec texture moderne
    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor,
          baseColor.withOpacity(0.95),
        ],
      ).createShader(Rect.fromLTWH(
        centerX - width / 2,
        floorY,
        width,
        height,
      ))
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(centerX - width / 2, floorY)
      ..lineTo(centerX + width / 2, floorY)
      ..lineTo(centerX + width / 2, floorY + height)
      ..lineTo(centerX - width / 2, floorY + height)
      ..close();

    canvas.drawPath(frontPath, frontPaint);

    // Face côté (droite) plus sombre
    final depthOffset = depth * math.cos(angle) / 2;
    final heightOffset = depth * math.sin(angle) / 2;

    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withOpacity(0.7),
          baseColor.withOpacity(0.6),
        ],
      ).createShader(Rect.fromLTWH(
        centerX + width / 2,
        floorY - heightOffset,
        depthOffset,
        height,
      ));

    final sidePath = Path()
      ..moveTo(centerX + width / 2, floorY)
      ..lineTo(centerX + width / 2 + depthOffset, floorY - heightOffset)
      ..lineTo(centerX + width / 2 + depthOffset, floorY + height - heightOffset)
      ..lineTo(centerX + width / 2, floorY + height)
      ..close();

    canvas.drawPath(sidePath, sidePaint);

    // Face dessus
    final topPaint = Paint()
      ..color = baseColor.withOpacity(0.85);

    final topPath = Path()
      ..moveTo(centerX - width / 2, floorY)
      ..lineTo(centerX + width / 2, floorY)
      ..lineTo(centerX + width / 2 + depthOffset, floorY - heightOffset)
      ..lineTo(centerX - width / 2 + depthOffset, floorY - heightOffset)
      ..close();

    canvas.drawPath(topPath, topPaint);

    // Bande colorée d'occupation sur le côté
    final accentBandPaint = Paint()
      ..color = accentColor.withOpacity(0.8);

    final bandWidth = 15.0;
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - width / 2,
        floorY,
        bandWidth,
        height,
      ),
      accentBandPaint,
    );

    // Bordures nettes
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(frontPath, borderPaint);
    canvas.drawPath(sidePath, borderPaint);
    canvas.drawPath(topPath, borderPaint);

    // Fenêtres modernes avec style architectural
    _drawModernWindows(canvas, centerX, floorY, width, height, occupancyRate);

    // Balcons
    if (floorNumber > 0) {
      _drawBalconies(canvas, centerX, floorY, width, height);
    }

    // Numéro de l'étage avec meilleur design
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$floorNumber',
        style: TextStyle(
          color: accentColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(0, 0),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Badge circulaire pour le numéro
    final badgeRadius = 20.0;
    final badgeCenter = Offset(
      centerX - width / 2 + bandWidth / 2,
      floorY + height / 2,
    );

    final badgePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    final badgeBorderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(badgeCenter, badgeRadius, badgeBorderPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawModernWindows(
      Canvas canvas,
      double centerX,
      double floorY,
      double width,
      double height,
      double occupancyRate,
      ) {
    final windowPaint = Paint()..style = PaintingStyle.fill;

    final windowWidth = 35.0;
    final windowHeight = height * 0.6;
    final spacing = 50.0;
    final margin = 50.0;

    final numWindows = ((width - 2 * margin) / spacing).floor();
    final startX = centerX - (numWindows * spacing) / 2;

    for (int i = 0; i < numWindows; i++) {
      final x = startX + i * spacing;
      final y = floorY + height / 2 - windowHeight / 2;

      // Fenêtre avec effet de verre moderne
      final isLit = (i / numWindows) < occupancyRate;

      // Fond de la fenêtre
      windowPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLit
            ? [
          const Color(0xFFFFF4A3),
          const Color(0xFFFFE066),
        ]
            : [
          const Color(0xFF1A2332).withOpacity(0.8),
          const Color(0xFF0D1117).withOpacity(0.9),
        ],
      ).createShader(Rect.fromLTWH(x, y, windowWidth, windowHeight));

      final windowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, windowWidth, windowHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(windowRect, windowPaint);

      // Reflet sur la vitre
      if (isLit) {
        final reflectionPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(x, y, windowWidth / 2, windowHeight / 2));

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, windowWidth / 2, windowHeight / 2),
            const Radius.circular(4),
          ),
          reflectionPaint,
        );
      }

      // Cadre de fenêtre noir
      final framePaint = Paint()
        ..color = const Color(0xFF2C2C2C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawRRect(windowRect, framePaint);

      // Séparateurs horizontaux
      final dividerPaint = Paint()
        ..color = const Color(0xFF2C2C2C)
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(x, y + windowHeight / 2),
        Offset(x + windowWidth, y + windowHeight / 2),
        dividerPaint,
      );

      // Séparateur vertical
      canvas.drawLine(
        Offset(x + windowWidth / 2, y),
        Offset(x + windowWidth / 2, y + windowHeight),
        dividerPaint,
      );
    }
  }

  void _drawBalconies(
      Canvas canvas,
      double centerX,
      double floorY,
      double width,
      double height,
      ) {
    final balconyPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.fill;

    final balconyHeight = 8.0;
    final balconyDepth = 12.0;

    // Balcons sur les côtés
    final balconyPositions = [
      centerX - width / 2 + 60,
      centerX + width / 2 - 60,
    ];

    for (final balconyX in balconyPositions) {
      final balconyY = floorY + height - balconyHeight;

      // Plateforme du balcon
      final platformPath = Path()
        ..moveTo(balconyX - 25, balconyY)
        ..lineTo(balconyX + 25, balconyY)
        ..lineTo(balconyX + 25 + balconyDepth, balconyY - 5)
        ..lineTo(balconyX - 25 + balconyDepth, balconyY - 5)
        ..close();

      canvas.drawPath(platformPath, balconyPaint);

      // Garde-corps
      final railingPaint = Paint()
        ..color = const Color(0xFF8D8D8D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < 5; i++) {
        final railX = balconyX - 20 + i * 10;
        canvas.drawLine(
          Offset(railX, balconyY - 15),
          Offset(railX + balconyDepth * 0.8, balconyY - 20),
          railingPaint,
        );
      }

      // Barre horizontale du garde-corps
      canvas.drawLine(
        Offset(balconyX - 20, balconyY - 15),
        Offset(balconyX - 20 + balconyDepth * 0.8 + 40, balconyY - 20),
        railingPaint..strokeWidth = 2.5,
      );
    }
  }

  void _drawRoof(
      Canvas canvas,
      double centerX,
      double roofY,
      double width,
      double depth,
      double height,
      double rotation,
      ) {
    final angle = rotation * 0.2;
    final depthOffset = depth * math.cos(angle) / 2;
    final heightOffset = depth * math.sin(angle) / 2;

    // Toit plat moderne avec rebord
    final roofPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF424242),
          const Color(0xFF303030),
        ],
      ).createShader(Rect.fromLTWH(
        centerX - width / 2,
        roofY - height,
        width,
        height,
      ));

    // Face avant du toit
    final roofPath = Path()
      ..moveTo(centerX - width / 2 - 10, roofY)
      ..lineTo(centerX + width / 2 + 10, roofY)
      ..lineTo(centerX + width / 2 + 10, roofY - height)
      ..lineTo(centerX - width / 2 - 10, roofY - height)
      ..close();

    canvas.drawPath(roofPath, roofPaint);

    // Face côté du toit
    final roofSidePaint = Paint()
      ..color = const Color(0xFF2A2A2A);

    final roofSidePath = Path()
      ..moveTo(centerX + width / 2 + 10, roofY)
      ..lineTo(centerX + width / 2 + 10 + depthOffset, roofY - heightOffset)
      ..lineTo(centerX + width / 2 + 10 + depthOffset, roofY - height - heightOffset)
      ..lineTo(centerX + width / 2 + 10, roofY - height)
      ..close();

    canvas.drawPath(roofSidePath, roofSidePaint);

    // Face dessus du toit (terrasse)
    final roofTopPaint = Paint()
      ..color = const Color(0xFF505050);

    final roofTopPath = Path()
      ..moveTo(centerX - width / 2 - 10, roofY - height)
      ..lineTo(centerX + width / 2 + 10, roofY - height)
      ..lineTo(centerX + width / 2 + 10 + depthOffset, roofY - height - heightOffset)
      ..lineTo(centerX - width / 2 - 10 + depthOffset, roofY - height - heightOffset)
      ..close();

    canvas.drawPath(roofTopPath, roofTopPaint);

    // Bordure du toit
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(roofPath, borderPaint);
    canvas.drawPath(roofSidePath, borderPaint);
    canvas.drawPath(roofTopPath, borderPaint);

    // Structure sur le toit (climatisation)
    _drawRoofStructures(canvas, centerX, roofY - height, depthOffset, heightOffset);
  }

  void _drawRoofStructures(
      Canvas canvas,
      double centerX,
      double roofY,
      double depthOffset,
      double heightOffset,
      ) {
    final structurePaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;

    // Unité de climatisation 1
    final acUnit1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 40, roofY - 20, 30, 15),
      const Radius.circular(2),
    );
    canvas.drawRRect(acUnit1, structurePaint);

    // Unité de climatisation 2
    final acUnit2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + 10, roofY - 20, 30, 15),
      const Radius.circular(2),
    );
    canvas.drawRRect(acUnit2, structurePaint);

    // Grilles de ventilation
    final ventPaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(centerX - 35 + i * 7, roofY - 17),
        Offset(centerX - 35 + i * 7, roofY - 8),
        ventPaint,
      );
      canvas.drawLine(
        Offset(centerX + 15 + i * 7, roofY - 17),
        Offset(centerX + 15 + i * 7, roofY - 8),
        ventPaint,
      );
    }
  }

  void _drawAntenna(
      Canvas canvas,
      double centerX,
      double antennaY,
      double rotation,
      ) {
    final antennaPaint = Paint()
      ..color = const Color(0xFF616161)
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;

    // Mât principal
    canvas.drawLine(
      Offset(centerX, antennaY),
      Offset(centerX, antennaY - 60),
      antennaPaint..strokeWidth = 4,
    );

    // Sections transversales
    final crossPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(centerX - 15, antennaY - 40),
      Offset(centerX + 15, antennaY - 40),
      crossPaint,
    );

    canvas.drawLine(
      Offset(centerX - 10, antennaY - 50),
      Offset(centerX + 10, antennaY - 50),
      crossPaint,
    );

    // Parabole en haut
    final dishPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.fill;

    final dishPath = Path()
      ..moveTo(centerX - 8, antennaY - 60)
      ..quadraticBezierTo(
        centerX,
        antennaY - 65,
        centerX + 8,
        antennaY - 60,
      )
      ..lineTo(centerX + 8, antennaY - 58)
      ..quadraticBezierTo(
        centerX,
        antennaY - 61,
        centerX - 8,
        antennaY - 58,
      )
      ..close();

    canvas.drawPath(dishPath, dishPaint);

    // Bordure de la parabole
    final dishBorderPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(dishPath, dishBorderPaint);

    // Lumière clignotante rouge en haut
    final lightPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(
      Offset(centerX, antennaY - 68),
      3,
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(Building3DPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}