-- Paradise AG Church Management System — Supabase Schema
-- Run this in Supabase SQL Editor after creating your project.
-- This creates all tables needed for offline-first cloud sync.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Churches (multi-tenant root) ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS churches (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  description TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Users ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT,
  role TEXT NOT NULL DEFAULT 'member',
  phone TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Members ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS members (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT,
  address TEXT,
  occupation TEXT,
  join_date DATE,
  is_baptized BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Branches ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS branches (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location TEXT,
  leader TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Departments ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS departments (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  head TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Events ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Sermons ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sermons (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  speaker TEXT,
  date TIMESTAMPTZ,
  description TEXT,
  video_url TEXT,
  audio_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Transactions (Finance) ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  description TEXT,
  date TIMESTAMPTZ,
  category TEXT,
  member_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Attendance Records ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance_records (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  member_id TEXT,
  event_id TEXT,
  date TIMESTAMPTZ,
  status TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Welfare Cases ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS welfare_cases (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  member_id TEXT,
  type TEXT,
  description TEXT,
  status TEXT,
  amount_requested NUMERIC(12,2),
  amount_approved NUMERIC(12,2),
  date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Welfare Finance ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS welfare_finance (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  description TEXT,
  date TIMESTAMPTZ,
  welfare_case_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Ministries ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ministries (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  leader TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Ministry Finance ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ministry_finance (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  ministry_id TEXT,
  type TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  description TEXT,
  date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Contributions ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contributions (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  member_id TEXT,
  type TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  date TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Budgets ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS budgets (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  allocated NUMERIC(12,2),
  spent NUMERIC(12,2),
  period TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Finance Approvals ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS finance_approvals (
  id TEXT PRIMARY KEY,
  church_id TEXT NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  transaction_id TEXT,
  requested_by TEXT,
  approved_by TEXT,
  status TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Sync Log (track sync operations) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sync_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  church_id TEXT,
  device_id TEXT,
  pushed_count INTEGER DEFAULT 0,
  pulled_count INTEGER DEFAULT 0,
  failed_count INTEGER DEFAULT 0,
  status TEXT,
  synced_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_users_church ON users(church_id);
CREATE INDEX IF NOT EXISTS idx_members_church ON members(church_id);
CREATE INDEX IF NOT EXISTS idx_branches_church ON branches(church_id);
CREATE INDEX IF NOT EXISTS idx_departments_church ON departments(church_id);
CREATE INDEX IF NOT EXISTS idx_events_church ON events(church_id);
CREATE INDEX IF NOT EXISTS idx_sermons_church ON sermons(church_id);
CREATE INDEX IF NOT EXISTS idx_transactions_church ON transactions(church_id);
CREATE INDEX IF NOT EXISTS idx_attendance_church ON attendance_records(church_id);
CREATE INDEX IF NOT EXISTS idx_welfare_church ON welfare_cases(church_id);
CREATE INDEX IF NOT EXISTS idx_welfare_fin_church ON welfare_finance(church_id);
CREATE INDEX IF NOT EXISTS idx_ministries_church ON ministries(church_id);
CREATE INDEX IF NOT EXISTS idx_ministry_fin_church ON ministry_finance(church_id);
CREATE INDEX IF NOT EXISTS idx_contributions_church ON contributions(church_id);
CREATE INDEX IF NOT EXISTS idx_budgets_church ON budgets(church_id);
CREATE INDEX IF NOT EXISTS idx_finance_approvals_church ON finance_approvals(church_id);

-- ── Row Level Security (RLS) ────────────────────────────────────────────────
-- Enable RLS on all church-scoped tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE sermons ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE welfare_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE welfare_finance ENABLE ROW LEVEL SECURITY;
ALTER TABLE ministries ENABLE ROW LEVEL SECURITY;
ALTER TABLE ministry_finance ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance_approvals ENABLE ROW LEVEL SECURITY;

-- Allow all operations for authenticated users (simplify for offline-first)
-- You can tighten these policies later based on user roles
CREATE POLICY "authenticated_all_users" ON users FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_members" ON members FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_branches" ON branches FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_departments" ON departments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_events" ON events FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_sermons" ON sermons FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_transactions" ON transactions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_attendance" ON attendance_records FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_welfare" ON welfare_cases FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_welfare_fin" ON welfare_finance FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_ministries" ON ministries FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_ministry_fin" ON ministry_finance FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_contributions" ON contributions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_budgets" ON budgets FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all_finance_approvals" ON finance_approvals FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Churches: allow authenticated users to read all, insert/update if authenticated
ALTER TABLE churches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_all_churches" ON churches FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── Updated_at trigger function ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to all tables with updated_at
DO $$
DECLARE t TEXT;
BEGIN
  FOR t IN
    SELECT table_name FROM information_schema.columns
    WHERE column_name = 'updated_at' AND table_schema = 'public'
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at ON %I', t);
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at()', t);
  END LOOP;
END;
$$;
