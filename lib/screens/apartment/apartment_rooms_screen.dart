import 'package:flutter/material.dart';
import '../../models/apartment_room_model.dart';
import '../../services/apartment_room_service.dart';

class ApartmentRoomsScreen extends StatefulWidget {
  final String apartmentId;

  const ApartmentRoomsScreen({Key? key, required this.apartmentId}) : super(key: key);

  @override
  State<ApartmentRoomsScreen> createState() => _ApartmentRoomsScreenState();
}

class _ApartmentRoomsScreenState extends State<ApartmentRoomsScreen> {
  final ApartmentRoomService _roomService = ApartmentRoomService();
  List<ApartmentRoomModel>? _rooms;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _roomService.getRoomsByApartment(widget.apartmentId);
      setState(() {
        _rooms = rooms;
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

  Future<void> _showAddRoomDialog() async {
    final roomNameController = TextEditingController();
    final roomTypeController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une pièce'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNameController,
                decoration: const InputDecoration(labelText: 'Nom de la pièce *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: roomTypeController,
                decoration: const InputDecoration(labelText: 'Type (ex: bedroom, living_room)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (roomNameController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _roomService.createRoom(
          apartmentId: widget.apartmentId,
          roomName: roomNameController.text,
          roomType: roomTypeController.text.isNotEmpty ? roomTypeController.text : null,
          description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
          orderIndex: _rooms?.length ?? 0,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pièce ajoutée avec succès')),
          );
        }
        _loadRooms();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette pièce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _roomService.deleteRoom(roomId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pièce supprimée')),
          );
        }
        _loadRooms();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  String _getRoomIcon(String? roomType) {
    if (roomType == null) return '🏠';
    switch (roomType.toLowerCase()) {
      case 'living_room':
      case 'salon':
        return '🛋️';
      case 'bedroom':
      case 'chambre':
        return '🛏️';
      case 'kitchen':
      case 'cuisine':
        return '🍳';
      case 'bathroom':
      case 'salle_de_bain':
        return '🚿';
      case 'toilet':
      case 'wc':
        return '🚽';
      case 'office':
      case 'bureau':
        return '💼';
      default:
        return '🏠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pièces de l\'Appartement'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms == null || _rooms!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Aucune pièce enregistrée',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddRoomDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une pièce'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rooms!.length,
                    itemBuilder: (context, index) {
                      final room = _rooms![index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              _getRoomIcon(room.roomType),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Text(
                            room.roomName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (room.roomType != null) Text('Type: ${room.roomType}'),
                              if (room.description != null) Text(room.description!),
                              if (room.photos.isNotEmpty)
                                Text(
                                  '${room.photos.length} photo(s)',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRoom(room.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
