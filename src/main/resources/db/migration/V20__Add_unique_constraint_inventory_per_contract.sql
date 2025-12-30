/*
  # Add unique constraint for one inventory per type per contract

  1. Changes
    - Add unique constraint on inventories table for (contract_id, type)
    - This ensures only one entry inventory and one exit inventory per lease contract

  2. Security
    - This constraint prevents data integrity issues
    - Ensures business rule: one entry inventory and one exit inventory maximum per contract
*/

-- Add unique constraint to prevent multiple inventories of the same type per contract
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'unique_inventory_per_contract_type'
  ) THEN
    ALTER TABLE inventories
    ADD CONSTRAINT unique_inventory_per_contract_type
    UNIQUE (contract_id, type);
  END IF;
END $$;
