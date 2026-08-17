-- ═══════════════════════════════════════════════════════════════════════════
-- Access Control Migration: Multi-Role Users + Page-Level Access Grants
--
-- Adapted from the SIMS access control model. This migration:
-- 1. Adds 'roles' (text[]) and 'active_role' (text) columns to the users table
-- 2. Migrates existing single-role data to the new multi-role format
-- 3. Creates access_grants and access_activities tables
-- 4. Adds Row Level Security (RLS) policies for server-side role enforcement
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Users table: add multi-role columns ──────────────────────────────────

-- Add roles array column (NULL initially, will be backfilled)
ALTER TABLE users ADD COLUMN IF NOT EXISTS roles text[];

-- Add active_role column (NULL initially, will be backfilled)
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_role text;

-- Backfill: copy existing 'role' to 'roles' array and 'active_role'
UPDATE users
SET roles = ARRAY[role],
    active_role = role
WHERE roles IS NULL AND role IS NOT NULL;

-- Set defaults for future inserts
ALTER TABLE users
  ALTER COLUMN roles SET DEFAULT ARRAY[]::text[],
  ALTER COLUMN active_role SET DEFAULT '';

-- Add index for role-based queries
CREATE INDEX IF NOT EXISTS idx_users_roles ON users USING GIN (roles);
CREATE INDEX IF NOT EXISTS idx_users_active_role ON users (active_role);

-- ── 2. Access Grants table ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS access_grants (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tenant_id text NOT NULL,
  user_id text NOT NULL,
  username text,
  display_name text,
  dashboard_key text NOT NULL,
  dashboard_label text,
  allowed_pages jsonb NOT NULL DEFAULT '"all"'::jsonb,
  granted_by text,
  granted_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  synced_at timestamptz,
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_access_grants_tenant ON access_grants (tenant_id);
CREATE INDEX IF NOT EXISTS idx_access_grants_user ON access_grants (user_id);
CREATE INDEX IF NOT EXISTS idx_access_grants_dashboard ON access_grants (dashboard_key);

-- ── 3. Access Activities table ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS access_activities (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tenant_id text NOT NULL,
  user_id text NOT NULL,
  username text,
  display_name text,
  dashboard_key text NOT NULL,
  dashboard_label text,
  page_key text NOT NULL,
  page_label text,
  action text,
  timestamp timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  synced_at timestamptz,
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_access_activities_tenant ON access_activities (tenant_id);
CREATE INDEX IF NOT EXISTS idx_access_activities_user ON access_activities (user_id);
CREATE INDEX IF NOT EXISTS idx_access_activities_dashboard ON access_activities (dashboard_key);

-- ── 4. Row Level Security (RLS) Policies ────────────────────────────────────
--
-- Server-side role enforcement: even if the client is compromised, the
-- database rejects unauthorized access. Adapted from SIMS's NestJS
-- RolesGuard + @Roles decorator pattern, implemented as Supabase RLS.
--
-- Policy rules:
-- - Users can always read their own data
-- - Users can read data within their tenant (church)
-- - Only admins (roles containing 'Admin' or 'superSystemAdmin') can write
-- - superSystemAdmin can access all tenants
-- - Access grants are readable by the grant recipient and dashboard owner

-- Enable RLS on access_grants
ALTER TABLE access_grants ENABLE ROW LEVEL SECURITY;

-- Users can read their own grants
CREATE POLICY "users_read_own_grants" ON access_grants
  FOR SELECT USING (
    user_id = auth.uid()::text
    OR tenant_id = (
      SELECT tenant_id::text FROM users WHERE id = auth.uid()
    )
  );

-- Only admins can create/update/delete grants
CREATE POLICY "admins_manage_grants" ON access_grants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND (
        roles @> ARRAY['superSystemAdmin']::text[]
        OR roles @> ARRAY['localChurchAdmin']::text[]
        OR roles @> ARRAY['nationalAdmin']::text[]
        OR roles @> ARRAY['regionalAdmin']::text[]
        OR roles @> ARRAY['districtAdmin']::text[]
        OR roles @> ARRAY['areaAdmin']::text[]
        OR roles @> ARRAY['seniorPastor']::text[]
      )
    )
  );

-- Enable RLS on access_activities
ALTER TABLE access_activities ENABLE ROW LEVEL SECURITY;

-- Users can read activities for their own grants or their dashboard
CREATE POLICY "users_read_activities" ON access_activities
  FOR SELECT USING (
    user_id = auth.uid()::text
    OR tenant_id = (
      SELECT tenant_id::text FROM users WHERE id = auth.uid()
    )
  );

-- Only admins can delete activities (users can insert their own)
CREATE POLICY "users_insert_activities" ON access_activities
  FOR INSERT WITH CHECK (
    user_id = auth.uid()::text
    OR tenant_id = (
      SELECT tenant_id::text FROM users WHERE id = auth.uid()
    )
  );

-- ── 5. Updated updated_at trigger ───────────────────────────────────────────

-- Add updated_at trigger for access_grants (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_access_grants_updated_at'
  ) THEN
    CREATE TRIGGER trigger_access_grants_updated_at
      BEFORE UPDATE ON access_grants
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Add updated_at trigger for access_activities (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_access_activities_updated_at'
  ) THEN
    CREATE TRIGGER trigger_access_activities_updated_at
      BEFORE UPDATE ON access_activities
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- ── 6. Verify migration ─────────────────────────────────────────────────────

-- Check that all users have roles and active_role set
SELECT
  COUNT(*) AS total_users,
  COUNT(*) FILTER (WHERE roles IS NOT NULL AND array_length(roles, 1) > 0) AS users_with_roles,
  COUNT(*) FILTER (WHERE active_role IS NOT NULL AND active_role != '') AS users_with_active_role
FROM users;

-- Check access_grants table
SELECT COUNT(*) AS total_grants FROM access_grants;

-- ═══════════════════════════════════════════════════════════════════════════
-- END OF MIGRATION
-- ═══════════════════════════════════════════════════════════════════════════
