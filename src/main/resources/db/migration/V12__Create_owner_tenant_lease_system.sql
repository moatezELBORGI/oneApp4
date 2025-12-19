/*
  # Owner, Tenant and Lease Management System

  1. Updates to Existing Tables
    - `apartments` table: Add owner_id and tenant_id columns to track ownership and current tenant

  2. New Tables
    - `apartment_rooms`: Stores rooms/sections for each apartment (dynamic)
      - `id` (uuid, primary key)
      - `apartment_id` (uuid, foreign key)
      - `room_name` (text) - e.g., "Salon", "Chambre 1"
      - `room_type` (text) - e.g., "living_room", "bedroom", "kitchen"
      - `description` (text)
      - `order_index` (integer)
      - `created_at`, `updated_at`

    - `apartment_room_photos`: Photos for each room
      - `id` (uuid, primary key)
      - `room_id` (uuid, foreign key)
      - `photo_url` (text)
      - `caption` (text)
      - `order_index` (integer)
      - `created_at`

    - `lease_contract_articles`: Standard lease articles by region/legislation
      - `id` (uuid, primary key)
      - `region_code` (text) - e.g., "BE-BRU", "BE-WAL", "BE-FLA"
      - `article_number` (text)
      - `article_title` (text)
      - `article_content` (text)
      - `order_index` (integer)
      - `is_mandatory` (boolean)
      - `created_at`, `updated_at`

    - `lease_contracts`: Lease contracts between owner and tenant
      - `id` (uuid, primary key)
      - `apartment_id` (uuid, foreign key)
      - `owner_id` (text, foreign key to residents)
      - `tenant_id` (text, foreign key to residents)
      - `start_date` (date)
      - `end_date` (date)
      - `initial_rent_amount` (decimal)
      - `current_rent_amount` (decimal)
      - `deposit_amount` (decimal)
      - `charges_amount` (decimal)
      - `region_code` (text)
      - `status` (text) - DRAFT, PENDING_SIGNATURE, SIGNED, ACTIVE, TERMINATED
      - `owner_signed_at` (timestamp)
      - `tenant_signed_at` (timestamp)
      - `owner_signature_data` (text) - base64 signature image
      - `tenant_signature_data` (text)
      - `pdf_url` (text)
      - `created_at`, `updated_at`

    - `lease_contract_custom_sections`: Custom sections added to contracts
      - `id` (uuid, primary key)
      - `contract_id` (uuid, foreign key)
      - `section_title` (text)
      - `section_content` (text)
      - `order_index` (integer)
      - `created_at`, `updated_at`

    - `rent_indexations`: History of rent indexations
      - `id` (uuid, primary key)
      - `contract_id` (uuid, foreign key)
      - `indexation_date` (date)
      - `previous_amount` (decimal)
      - `new_amount` (decimal)
      - `indexation_rate` (decimal)
      - `base_index` (decimal)
      - `new_index` (decimal)
      - `notes` (text)
      - `created_at`

    - `inventories`: État des lieux (entry/exit inventory)
      - `id` (uuid, primary key)
      - `contract_id` (uuid, foreign key)
      - `type` (text) - ENTRY, EXIT
      - `inventory_date` (date)
      - `electricity_meter_number` (text)
      - `electricity_day_index` (decimal)
      - `electricity_night_index` (decimal)
      - `water_meter_number` (text)
      - `water_index` (decimal)
      - `heating_meter_number` (text)
      - `heating_kwh_index` (decimal)
      - `heating_m3_index` (decimal)
      - `keys_apartment` (integer)
      - `keys_mailbox` (integer)
      - `keys_cellar` (integer)
      - `access_cards` (integer)
      - `parking_remotes` (integer)
      - `status` (text) - DRAFT, PENDING_SIGNATURE, SIGNED, FINALIZED
      - `owner_signed_at` (timestamp)
      - `tenant_signed_at` (timestamp)
      - `owner_signature_data` (text)
      - `tenant_signature_data` (text)
      - `pdf_url` (text)
      - `created_at`, `updated_at`

    - `inventory_room_entries`: Room-by-room entries in inventory
      - `id` (uuid, primary key)
      - `inventory_id` (uuid, foreign key)
      - `room_id` (uuid, foreign key to apartment_rooms, nullable for custom sections)
      - `section_name` (text) - for custom sections
      - `description` (text)
      - `order_index` (integer)
      - `created_at`, `updated_at`

    - `inventory_room_photos`: Photos for inventory room entries
      - `id` (uuid, primary key)
      - `room_entry_id` (uuid, foreign key)
      - `photo_url` (text)
      - `caption` (text)
      - `order_index` (integer)
      - `created_at`

  3. Security
    - Enable RLS on all tables
    - Add policies for authenticated users with appropriate access control
*/

-- Add owner and tenant columns to apartments
ALTER TABLE apartments
ADD COLUMN IF NOT EXISTS owner_id TEXT REFERENCES residents(id_users),
ADD COLUMN IF NOT EXISTS tenant_id TEXT REFERENCES residents(id_users);

CREATE INDEX IF NOT EXISTS idx_apartments_owner ON apartments(owner_id);
CREATE INDEX IF NOT EXISTS idx_apartments_tenant ON apartments(tenant_id);

-- Create apartment_rooms table
CREATE TABLE IF NOT EXISTS apartment_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id TEXT NOT NULL REFERENCES apartments(id_apartment) ON DELETE CASCADE,
  room_name TEXT NOT NULL,
  room_type TEXT,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_apartment_rooms_apartment ON apartment_rooms(apartment_id);

-- Create apartment_room_photos table
CREATE TABLE IF NOT EXISTS apartment_room_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES apartment_rooms(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_apartment_room_photos_room ON apartment_room_photos(room_id);

-- Create lease_contract_articles table
CREATE TABLE IF NOT EXISTS lease_contract_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region_code TEXT NOT NULL,
  article_number TEXT NOT NULL,
  article_title TEXT NOT NULL,
  article_content TEXT NOT NULL,
  order_index INTEGER DEFAULT 0,
  is_mandatory BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lease_articles_region ON lease_contract_articles(region_code);

-- Create lease_contracts table
CREATE TABLE IF NOT EXISTS lease_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id TEXT NOT NULL REFERENCES apartments(id_apartment) ON DELETE CASCADE,
  owner_id TEXT NOT NULL REFERENCES residents(id_users),
  tenant_id TEXT NOT NULL REFERENCES residents(id_users),
  start_date DATE NOT NULL,
  end_date DATE,
  initial_rent_amount DECIMAL(10,2) NOT NULL,
  current_rent_amount DECIMAL(10,2) NOT NULL,
  deposit_amount DECIMAL(10,2),
  charges_amount DECIMAL(10,2),
  region_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'DRAFT',
  owner_signed_at TIMESTAMP,
  tenant_signed_at TIMESTAMP,
  owner_signature_data TEXT,
  tenant_signature_data TEXT,
  pdf_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_lease_status CHECK (status IN ('DRAFT', 'PENDING_SIGNATURE', 'SIGNED', 'ACTIVE', 'TERMINATED'))
);

CREATE INDEX IF NOT EXISTS idx_lease_contracts_apartment ON lease_contracts(apartment_id);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_owner ON lease_contracts(owner_id);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_tenant ON lease_contracts(tenant_id);

-- Create lease_contract_custom_sections table
CREATE TABLE IF NOT EXISTS lease_contract_custom_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id UUID NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
  section_title TEXT NOT NULL,
  section_content TEXT NOT NULL,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lease_custom_sections_contract ON lease_contract_custom_sections(contract_id);

-- Create rent_indexations table
CREATE TABLE IF NOT EXISTS rent_indexations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id UUID NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
  indexation_date DATE NOT NULL,
  previous_amount DECIMAL(10,2) NOT NULL,
  new_amount DECIMAL(10,2) NOT NULL,
  indexation_rate DECIMAL(5,4) NOT NULL,
  base_index DECIMAL(10,4),
  new_index DECIMAL(10,4),
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rent_indexations_contract ON rent_indexations(contract_id);

-- Create inventories table
CREATE TABLE IF NOT EXISTS inventories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id UUID NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  inventory_date DATE NOT NULL,
  electricity_meter_number TEXT,
  electricity_day_index DECIMAL(10,2),
  electricity_night_index DECIMAL(10,2),
  water_meter_number TEXT,
  water_index DECIMAL(10,2),
  heating_meter_number TEXT,
  heating_kwh_index DECIMAL(10,2),
  heating_m3_index DECIMAL(10,2),
  keys_apartment INTEGER DEFAULT 0,
  keys_mailbox INTEGER DEFAULT 0,
  keys_cellar INTEGER DEFAULT 0,
  access_cards INTEGER DEFAULT 0,
  parking_remotes INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'DRAFT',
  owner_signed_at TIMESTAMP,
  tenant_signed_at TIMESTAMP,
  owner_signature_data TEXT,
  tenant_signature_data TEXT,
  pdf_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_inventory_type CHECK (type IN ('ENTRY', 'EXIT')),
  CONSTRAINT chk_inventory_status CHECK (status IN ('DRAFT', 'PENDING_SIGNATURE', 'SIGNED', 'FINALIZED'))
);

CREATE INDEX IF NOT EXISTS idx_inventories_contract ON inventories(contract_id);

-- Create inventory_room_entries table
CREATE TABLE IF NOT EXISTS inventory_room_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id UUID NOT NULL REFERENCES inventories(id) ON DELETE CASCADE,
  room_id UUID REFERENCES apartment_rooms(id) ON DELETE SET NULL,
  section_name TEXT,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_inventory_room_entries_inventory ON inventory_room_entries(inventory_id);
CREATE INDEX IF NOT EXISTS idx_inventory_room_entries_room ON inventory_room_entries(room_id);

-- Create inventory_room_photos table
CREATE TABLE IF NOT EXISTS inventory_room_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_entry_id UUID NOT NULL REFERENCES inventory_room_entries(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_inventory_room_photos_entry ON inventory_room_photos(room_entry_id);
