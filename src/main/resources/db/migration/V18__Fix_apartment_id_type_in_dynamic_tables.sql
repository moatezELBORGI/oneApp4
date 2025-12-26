/*
  # Fix apartment_id Type in Dynamic Apartment Management Tables

  1. Problem
    - The `apartment_rooms` and `apartment_custom_fields` tables have `apartment_id` defined as BIGINT
    - But the `apartments` table uses VARCHAR/TEXT for `id` (e.g., "BEL-2025-IT-IMMEUBLE-20251")
    - This causes NumberFormatException when trying to save or update records

  2. Changes
    - Modify `apartment_rooms.apartment_id` from BIGINT to VARCHAR
    - Modify `apartment_custom_fields.apartment_id` from BIGINT to VARCHAR
    - Recreate foreign key constraints

  3. Impact
    - Fixes the ability to edit apartments created with the dynamic management system
    - Allows proper relationships between apartments and their rooms/custom fields
*/

-- Step 1: Drop foreign key constraints
ALTER TABLE apartment_rooms DROP CONSTRAINT IF EXISTS apartment_rooms_apartment_id_fkey;
ALTER TABLE apartment_custom_fields DROP CONSTRAINT IF EXISTS apartment_custom_fields_apartment_id_fkey;

-- Step 2: Change apartment_id column type to VARCHAR in apartment_rooms
ALTER TABLE apartment_rooms ALTER COLUMN apartment_id TYPE VARCHAR(255);

-- Step 3: Change apartment_id column type to VARCHAR in apartment_custom_fields
ALTER TABLE apartment_custom_fields ALTER COLUMN apartment_id TYPE VARCHAR(255);

-- Step 4: Recreate foreign key constraints
-- Note: apartments table uses 'id_apartment' as its primary key column
ALTER TABLE apartment_rooms
  ADD CONSTRAINT apartment_rooms_apartment_id_fkey
  FOREIGN KEY (apartment_id) REFERENCES apartments(id_apartment) ON DELETE CASCADE;

ALTER TABLE apartment_custom_fields
  ADD CONSTRAINT apartment_custom_fields_apartment_id_fkey
  FOREIGN KEY (apartment_id) REFERENCES apartments(id_apartment) ON DELETE CASCADE;
