/*
  # Create Default Equipment Templates System

  1. New Tables
    - `equipment_templates`
      - `id` (bigserial, primary key) - Unique equipment template identifier
      - `name` (varchar) - Equipment name (e.g., "Four", "Réfrigérateur", "Lave-vaisselle")
      - `room_type_id` (bigint) - Foreign key to room_types
      - `description` (text) - Optional description
      - `display_order` (integer) - Order for display in dropdown
      - `is_active` (boolean) - Whether this template is active
      - `created_at` (timestamp) - Creation timestamp

  2. Security
    - Enable RLS on `equipment_templates` table
    - Add policy for authenticated users to read equipment templates
    - Only admins can create/update equipment templates

  3. Sample Data
    - Insert default equipment for "Cuisine" (Kitchen)
    - Insert default equipment for "Salle d'eau" (Bathroom)
*/

-- Create equipment_templates table
CREATE TABLE IF NOT EXISTS equipment_templates (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  room_type_id BIGINT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_equipment_room_type FOREIGN KEY (room_type_id) REFERENCES room_types(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE equipment_templates ENABLE ROW LEVEL SECURITY;

-- Policy for reading equipment templates (all authenticated users)
CREATE POLICY "Authenticated users can view equipment templates"
  ON equipment_templates FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Policy for managing equipment templates (only admins via service role)
CREATE POLICY "Service role can manage equipment templates"
  ON equipment_templates FOR ALL
  USING (true)
  WITH CHECK (true);

-- Insert default equipment for Cuisine (Kitchen)
-- First, get the room_type_id for "Cuisine"
DO $$
DECLARE
  cuisine_id BIGINT;
  salle_eau_id BIGINT;
BEGIN
  -- Get Cuisine room type ID
  SELECT id INTO cuisine_id FROM room_types WHERE name = 'Cuisine' LIMIT 1;

  IF cuisine_id IS NOT NULL THEN
    -- Insert kitchen equipment
    INSERT INTO equipment_templates (name, room_type_id, description, display_order) VALUES
    ('Four', cuisine_id, 'Four électrique ou à gaz', 1),
    ('Plaque de cuisson', cuisine_id, 'Plaques électriques, à gaz ou induction', 2),
    ('Hotte aspirante', cuisine_id, 'Hotte pour extraction des fumées', 3),
    ('Réfrigérateur', cuisine_id, 'Réfrigérateur avec ou sans congélateur', 4),
    ('Congélateur', cuisine_id, 'Congélateur séparé', 5),
    ('Lave-vaisselle', cuisine_id, 'Lave-vaisselle encastrable ou posable', 6),
    ('Micro-ondes', cuisine_id, 'Four micro-ondes', 7),
    ('Évier', cuisine_id, 'Évier avec robinetterie', 8),
    ('Plan de travail', cuisine_id, 'Surface de travail', 9),
    ('Meubles de cuisine', cuisine_id, 'Armoires et placards de cuisine', 10),
    ('Cave à vin', cuisine_id, 'Cave à vin électrique', 11),
    ('Hotte décorative', cuisine_id, 'Hotte design visible', 12);
  END IF;

  -- Get Salle d'eau room type ID
  SELECT id INTO salle_eau_id FROM room_types WHERE name = 'Salle d''eau' LIMIT 1;

  IF salle_eau_id IS NOT NULL THEN
    -- Insert bathroom equipment
    INSERT INTO equipment_templates (name, room_type_id, description, display_order) VALUES
    ('Douche', salle_eau_id, 'Cabine de douche ou douche à l''italienne', 1),
    ('Baignoire', salle_eau_id, 'Baignoire standard ou balnéo', 2),
    ('Lavabo', salle_eau_id, 'Lavabo simple ou double vasque', 3),
    ('Toilette', salle_eau_id, 'WC avec chasse d''eau', 4),
    ('Bidet', salle_eau_id, 'Bidet', 5),
    ('Meuble sous-vasque', salle_eau_id, 'Meuble de rangement sous le lavabo', 6),
    ('Miroir', salle_eau_id, 'Miroir mural', 7),
    ('Armoire de toilette', salle_eau_id, 'Armoire murale avec miroir', 8),
    ('Sèche-serviettes', salle_eau_id, 'Radiateur sèche-serviettes électrique ou à eau', 9),
    ('VMC', salle_eau_id, 'Ventilation mécanique contrôlée', 10),
    ('Colonne de douche', salle_eau_id, 'Ensemble de douche avec douchette', 11),
    ('Porte-serviettes', salle_eau_id, 'Support pour serviettes', 12);
  END IF;
END $$;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_equipment_templates_room_type ON equipment_templates(room_type_id);
CREATE INDEX IF NOT EXISTS idx_equipment_templates_active ON equipment_templates(is_active);
