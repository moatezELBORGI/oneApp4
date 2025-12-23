/*
  # Fix apartment_rooms apartment_id type

  1. Changes
    - Change apartment_id from BIGINT to VARCHAR to match the String type in Java
    - Update foreign key constraint to reference apartments.id_apartment instead of apartments.id

  2. Security
    - No changes to RLS policies needed

  IMPORTANT NOTES:
  - This migration fixes the data type mismatch between SQL (BIGINT) and Java (String)
  - apartment_id should reference apartments.id_apartment (VARCHAR) not apartments.id (BIGINT)
  - Existing data needs to be preserved during the migration
*/

-- Drop existing foreign key constraint
ALTER TABLE apartment_rooms DROP CONSTRAINT IF EXISTS apartment_rooms_apartment_id_fkey;

-- Change apartment_id type from BIGINT to VARCHAR
ALTER TABLE apartment_rooms ALTER COLUMN apartment_id TYPE VARCHAR(255);

-- Add new foreign key constraint referencing apartments.id_apartment
ALTER TABLE apartment_rooms
  ADD CONSTRAINT apartment_rooms_apartment_id_fkey
  FOREIGN KEY (apartment_id)
  REFERENCES apartments(id_apartment)
  ON DELETE CASCADE;

-- Update the index for better performance
DROP INDEX IF EXISTS idx_apartment_rooms_apartment_id;
CREATE INDEX idx_apartment_rooms_apartment_id ON apartment_rooms(apartment_id);
