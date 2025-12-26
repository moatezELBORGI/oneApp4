/*
  # Add Entry Inventory Reference to Lease Contracts

  1. Changes
    - Add `entry_inventory_id` column to `lease_contracts` table
    - This links a lease contract to its mandatory entry inventory
    - Entry inventory must be signed before the contract can be signed

  2. Notes
    - Column is nullable to allow existing contracts without this requirement
    - New contracts will require an entry inventory to be signed first
*/

-- Add entry_inventory_id to lease_contracts
ALTER TABLE lease_contracts
ADD COLUMN IF NOT EXISTS entry_inventory_id UUID;

-- Add foreign key constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_lease_contracts_entry_inventory'
    ) THEN
        ALTER TABLE lease_contracts
        ADD CONSTRAINT fk_lease_contracts_entry_inventory
        FOREIGN KEY (entry_inventory_id) REFERENCES inventories(id)
        ON DELETE SET NULL;
    END IF;
END $$;
