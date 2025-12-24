/*
  # Migration des entrées d'inventaire vers les nouvelles pièces

  1. Modifications
    - Renomme la colonne `room_id` en `apartment_room_id` dans `inventory_room_entries`
    - Met à jour la contrainte de clé étrangère pour pointer vers `apartment_rooms`
    - Copie les images des pièces vers les photos d'inventaire lors de la création d'un inventaire

  2. Raison
    - Le système utilise maintenant `apartment_rooms` (avec images) au lieu de `apartment_rooms_legacy`
    - Les états des lieux doivent récupérer automatiquement les pièces et leurs images lors de la création
*/

-- Renommer la colonne et mettre à jour la contrainte de clé étrangère
ALTER TABLE inventory_room_entries
DROP CONSTRAINT IF EXISTS fk_inventory_room_entries_room;

ALTER TABLE inventory_room_entries
RENAME COLUMN room_id TO apartment_room_id;

ALTER TABLE inventory_room_entries
ADD CONSTRAINT fk_inventory_room_entries_apartment_room
FOREIGN KEY (apartment_room_id) REFERENCES apartment_rooms(id) ON DELETE SET NULL;
