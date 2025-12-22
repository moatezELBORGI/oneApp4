/*
  # Dynamic Apartment Management System

  1. New Tables
    - `room_types` - Types de pièces configurables (cuisine, chambre, salon, salle d'eau, etc.)
      - `id` (bigserial, primary key)
      - `name` (varchar, nom du type de pièce)
      - `building_id` (bigint, nullable - null pour types système)
      - `created_at` (timestamp)

    - `room_type_field_definitions` - Définitions des champs pour chaque type de pièce
      - `id` (bigserial, primary key)
      - `room_type_id` (bigint, foreign key)
      - `field_name` (varchar, nom du champ)
      - `field_type` (varchar, type: TEXT, NUMBER, BOOLEAN, IMAGE_LIST)
      - `is_required` (boolean)
      - `display_order` (int)
      - `created_at` (timestamp)

    - `apartment_rooms` - Pièces d'un appartement
      - `id` (bigserial, primary key)
      - `apartment_id` (bigint, foreign key)
      - `room_type_id` (bigint, foreign key)
      - `room_name` (varchar, optional custom name)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

    - `room_field_values` - Valeurs des champs pour chaque pièce
      - `id` (bigserial, primary key)
      - `apartment_room_id` (bigint, foreign key)
      - `field_definition_id` (bigint, foreign key)
      - `text_value` (text, nullable)
      - `number_value` (decimal, nullable)
      - `boolean_value` (boolean, nullable)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

    - `room_equipments` - Équipements d'une pièce
      - `id` (bigserial, primary key)
      - `apartment_room_id` (bigint, foreign key)
      - `name` (varchar)
      - `description` (text, nullable)
      - `created_at` (timestamp)

    - `room_images` - Images des pièces et équipements
      - `id` (bigserial, primary key)
      - `apartment_room_id` (bigint, nullable, foreign key)
      - `equipment_id` (bigint, nullable, foreign key)
      - `image_url` (varchar)
      - `display_order` (int)
      - `created_at` (timestamp)

    - `apartment_custom_fields` - Champs personnalisés pour un appartement
      - `id` (bigserial, primary key)
      - `apartment_id` (bigint, foreign key)
      - `field_label` (varchar)
      - `field_value` (text)
      - `display_order` (int)
      - `is_system_field` (boolean, pour les champs par défaut)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Updates to existing tables
    - Add `property_name` to apartments table
    - Add `max_floors` to buildings table if not exists

  3. Security
    - Enable RLS on all new tables
    - Add appropriate policies for admin_building and property owners
*/

-- Add property_name to apartments if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'apartments' AND column_name = 'property_name'
  ) THEN
    ALTER TABLE apartments ADD COLUMN property_name VARCHAR(255);
  END IF;
END $$;

-- Add max_floors to buildings if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'buildings' AND column_name = 'max_floors'
  ) THEN
    ALTER TABLE buildings ADD COLUMN max_floors INT DEFAULT 10;
  END IF;
END $$;

-- Create room_types table
CREATE TABLE IF NOT EXISTS room_types (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  building_id BIGINT REFERENCES buildings(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(name, building_id)
);

-- Create room_type_field_definitions table
CREATE TABLE IF NOT EXISTS room_type_field_definitions (
  id BIGSERIAL PRIMARY KEY,
  room_type_id BIGINT NOT NULL REFERENCES room_types(id) ON DELETE CASCADE,
  field_name VARCHAR(100) NOT NULL,
  field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('TEXT', 'NUMBER', 'BOOLEAN', 'IMAGE_LIST', 'EQUIPMENT_LIST')),
  is_required BOOLEAN DEFAULT false,
  display_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(room_type_id, field_name)
);

-- Create apartment_rooms table
CREATE TABLE IF NOT EXISTS apartment_rooms (
  id BIGSERIAL PRIMARY KEY,
  apartment_id BIGINT NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  room_type_id BIGINT NOT NULL REFERENCES room_types(id) ON DELETE RESTRICT,
  room_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create room_field_values table
CREATE TABLE IF NOT EXISTS room_field_values (
  id BIGSERIAL PRIMARY KEY,
  apartment_room_id BIGINT NOT NULL REFERENCES apartment_rooms(id) ON DELETE CASCADE,
  field_definition_id BIGINT NOT NULL REFERENCES room_type_field_definitions(id) ON DELETE CASCADE,
  text_value TEXT,
  number_value DECIMAL(10, 2),
  boolean_value BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(apartment_room_id, field_definition_id)
);

-- Create room_equipments table
CREATE TABLE IF NOT EXISTS room_equipments (
  id BIGSERIAL PRIMARY KEY,
  apartment_room_id BIGINT NOT NULL REFERENCES apartment_rooms(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create room_images table
CREATE TABLE IF NOT EXISTS room_images (
  id BIGSERIAL PRIMARY KEY,
  apartment_room_id BIGINT REFERENCES apartment_rooms(id) ON DELETE CASCADE,
  equipment_id BIGINT REFERENCES room_equipments(id) ON DELETE CASCADE,
  image_url VARCHAR(500) NOT NULL,
  display_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (
    (apartment_room_id IS NOT NULL AND equipment_id IS NULL) OR
    (apartment_room_id IS NULL AND equipment_id IS NOT NULL)
  )
);

-- Create apartment_custom_fields table
CREATE TABLE IF NOT EXISTS apartment_custom_fields (
  id BIGSERIAL PRIMARY KEY,
  apartment_id BIGINT NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  field_label VARCHAR(255) NOT NULL,
  field_value TEXT,
  display_order INT DEFAULT 0,
  is_system_field BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE room_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_type_field_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE apartment_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_field_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_equipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE apartment_custom_fields ENABLE ROW LEVEL SECURITY;

-- RLS Policies for room_types
CREATE POLICY "Building members can view room types"
  ON room_types FOR SELECT
  TO authenticated
  USING (
    building_id IS NULL OR
    EXISTS (
      SELECT 1 FROM resident_buildings rb
      WHERE rb.building_id = room_types.building_id
      AND rb.resident_id = auth.uid()::text
    )
  );

CREATE POLICY "Building admins can insert room types"
  ON room_types FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM resident_buildings rb
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE rb.building_id = room_types.building_id
      AND rb.resident_id = auth.uid()::text
      AND r.role = 'ADMIN_BUILDING'
    )
  );

CREATE POLICY "Building admins can update room types"
  ON room_types FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM resident_buildings rb
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE rb.building_id = room_types.building_id
      AND rb.resident_id = auth.uid()::text
      AND r.role = 'ADMIN_BUILDING'
    )
  );

CREATE POLICY "Building admins can delete room types"
  ON room_types FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM resident_buildings rb
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE rb.building_id = room_types.building_id
      AND rb.resident_id = auth.uid()::text
      AND r.role = 'ADMIN_BUILDING'
    )
  );

-- RLS Policies for room_type_field_definitions
CREATE POLICY "Building members can view field definitions"
  ON room_type_field_definitions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM room_types rt
      LEFT JOIN resident_buildings rb ON rb.building_id = rt.building_id
      WHERE rt.id = room_type_field_definitions.room_type_id
      AND (rt.building_id IS NULL OR rb.resident_id = auth.uid()::text)
    )
  );

CREATE POLICY "Building admins can manage field definitions"
  ON room_type_field_definitions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM room_types rt
      INNER JOIN resident_buildings rb ON rb.building_id = rt.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE rt.id = room_type_field_definitions.room_type_id
      AND rb.resident_id = auth.uid()::text
      AND r.role = 'ADMIN_BUILDING'
    )
  );

-- RLS Policies for apartment_rooms
CREATE POLICY "Building members can view apartment rooms"
  ON apartment_rooms FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartments a
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      WHERE a.id = apartment_rooms.apartment_id
      AND rb.resident_id = auth.uid()::text
    )
  );

CREATE POLICY "Building admins and owners can manage apartment rooms"
  ON apartment_rooms FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartments a
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE a.id = apartment_rooms.apartment_id
      AND rb.resident_id = auth.uid()::text
      AND (r.role = 'ADMIN_BUILDING' OR a.owner_id = auth.uid()::text)
    )
  );

-- RLS Policies for room_field_values
CREATE POLICY "Building members can view room field values"
  ON room_field_values FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartment_rooms ar
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      WHERE ar.id = room_field_values.apartment_room_id
      AND rb.resident_id = auth.uid()::text
    )
  );

CREATE POLICY "Building admins and owners can manage room field values"
  ON room_field_values FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartment_rooms ar
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE ar.id = room_field_values.apartment_room_id
      AND rb.resident_id = auth.uid()::text
      AND (r.role = 'ADMIN_BUILDING' OR a.owner_id = auth.uid()::text)
    )
  );

-- RLS Policies for room_equipments
CREATE POLICY "Building members can view room equipments"
  ON room_equipments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartment_rooms ar
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      WHERE ar.id = room_equipments.apartment_room_id
      AND rb.resident_id = auth.uid()::text
    )
  );

CREATE POLICY "Building admins and owners can manage room equipments"
  ON room_equipments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartment_rooms ar
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE ar.id = room_equipments.apartment_room_id
      AND rb.resident_id = auth.uid()::text
      AND (r.role = 'ADMIN_BUILDING' OR a.owner_id = auth.uid()::text)
    )
  );

-- RLS Policies for room_images
CREATE POLICY "Building members can view room images"
  ON room_images FOR SELECT
  TO authenticated
  USING (
    (apartment_room_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM apartment_rooms ar
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      WHERE ar.id = room_images.apartment_room_id
      AND rb.resident_id = auth.uid()::text
    )) OR
    (equipment_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM room_equipments re
      INNER JOIN apartment_rooms ar ON ar.id = re.apartment_room_id
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      WHERE re.id = room_images.equipment_id
      AND rb.resident_id = auth.uid()::text
    ))
  );

CREATE POLICY "Building admins and owners can manage room images"
  ON room_images FOR ALL
  TO authenticated
  USING (
    (apartment_room_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM apartment_rooms ar
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE ar.id = room_images.apartment_room_id
      AND rb.resident_id = auth.uid()::text
      AND (r.role = 'ADMIN_BUILDING' OR a.owner_id = auth.uid()::text)
    )) OR
    (equipment_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM room_equipments re
      INNER JOIN apartment_rooms ar ON ar.id = re.apartment_room_id
      INNER JOIN apartments a ON a.id = ar.apartment_id
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE re.id = room_images.equipment_id
      AND rb.resident_id = auth.uid()::text
      AND (r.role = 'ADMIN_BUILDING' OR a.owner_id = auth.uid()::text)
    ))
  );

-- RLS Policies for apartment_custom_fields
CREATE POLICY "Building members can view apartment custom fields"
  ON apartment_custom_fields FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartments a
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      WHERE a.id = apartment_custom_fields.apartment_id
      AND rb.resident_id = auth.uid()::text
    )
  );

CREATE POLICY "Building admins and owners can manage apartment custom fields"
  ON apartment_custom_fields FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apartments a
      INNER JOIN resident_buildings rb ON rb.building_id = a.building_id
      INNER JOIN residents r ON r.id = rb.resident_id
      WHERE a.id = apartment_custom_fields.apartment_id
      AND rb.resident_id = auth.uid()::text
      AND (r.role = 'ADMIN_BUILDING' OR a.owner_id = auth.uid()::text)
    )
  );

-- Insert default room types (system-wide, no building_id)
INSERT INTO room_types (name, building_id) VALUES
  ('Chambre', NULL),
  ('Cuisine', NULL),
  ('Salle d''eau', NULL),
  ('Salon', NULL)
ON CONFLICT DO NOTHING;

-- Insert default field definitions for Chambre
INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Surface', 'NUMBER', true, 1
FROM room_types rt WHERE rt.name = 'Chambre' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Avec terrasse', 'BOOLEAN', false, 2
FROM room_types rt WHERE rt.name = 'Chambre' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Images', 'IMAGE_LIST', false, 3
FROM room_types rt WHERE rt.name = 'Chambre' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

-- Insert default field definitions for Cuisine
INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Équipements', 'EQUIPMENT_LIST', false, 1
FROM room_types rt WHERE rt.name = 'Cuisine' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

-- Insert default field definitions for Salle d'eau
INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Équipements', 'EQUIPMENT_LIST', false, 1
FROM room_types rt WHERE rt.name = 'Salle d''eau' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Images', 'IMAGE_LIST', false, 2
FROM room_types rt WHERE rt.name = 'Salle d''eau' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

-- Insert default field definitions for Salon
INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Surface', 'NUMBER', true, 1
FROM room_types rt WHERE rt.name = 'Salon' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO room_type_field_definitions (room_type_id, field_name, field_type, is_required, display_order)
SELECT rt.id, 'Avec terrasse', 'BOOLEAN', false, 2
FROM room_types rt WHERE rt.name = 'Salon' AND rt.building_id IS NULL
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_apartment_rooms_apartment_id ON apartment_rooms(apartment_id);
CREATE INDEX IF NOT EXISTS idx_apartment_rooms_room_type_id ON apartment_rooms(room_type_id);
CREATE INDEX IF NOT EXISTS idx_room_field_values_apartment_room_id ON room_field_values(apartment_room_id);
CREATE INDEX IF NOT EXISTS idx_room_equipments_apartment_room_id ON room_equipments(apartment_room_id);
CREATE INDEX IF NOT EXISTS idx_room_images_apartment_room_id ON room_images(apartment_room_id);
CREATE INDEX IF NOT EXISTS idx_room_images_equipment_id ON room_images(equipment_id);
CREATE INDEX IF NOT EXISTS idx_apartment_custom_fields_apartment_id ON apartment_custom_fields(apartment_id);
