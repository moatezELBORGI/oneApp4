-- Script de correction pour les equipment templates
-- Ce script retire la sécurité RLS qui bloque l'accès depuis Spring Boot

-- Désactiver RLS sur la table equipment_templates
ALTER TABLE equipment_templates DISABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes policies si elles existent
DROP POLICY IF EXISTS "Authenticated users can view equipment templates" ON equipment_templates;
DROP POLICY IF EXISTS "Service role can manage equipment templates" ON equipment_templates;

-- Vérifier que les données existent
SELECT COUNT(*) as total_templates FROM equipment_templates;
SELECT rt.name as room_type, COUNT(*) as equipment_count
FROM equipment_templates et
JOIN room_types rt ON et.room_type_id = rt.id
GROUP BY rt.name;
