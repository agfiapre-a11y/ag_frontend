-- ═══════════════════════════════════════════════════════════════════════════
-- Attendance Enhancement Migration: Event linking + expiry
--
-- Adds eventId, eventTitle, and expiresAt columns to attendance_records
-- to support event-linked attendance and time-based self-check-in expiry.
-- ═══════════════════════════════════════════════════════════════════════════

-- Add event_id column (nullable — attendance can be standalone or event-linked)
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS event_id uuid;

-- Add event_title column (denormalized for display without a join)
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS event_title varchar(255);

-- Add expires_at column (when the self-check-in window closes)
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS expires_at timestamptz;

-- Add index for event-based attendance queries
CREATE INDEX IF NOT EXISTS idx_attendance_event_id ON attendance_records (event_id)
  WHERE event_id IS NOT NULL;

-- Add index for expiry-based queries
CREATE INDEX IF NOT EXISTS idx_attendance_expires_at ON attendance_records (expires_at)
  WHERE expires_at IS NOT NULL;

-- Verify migration
SELECT
  COUNT(*) AS total_records,
  COUNT(*) FILTER (WHERE event_id IS NOT NULL) AS event_linked,
  COUNT(*) FILTER (WHERE expires_at IS NOT NULL) AS has_expiry
FROM attendance_records;

-- ═══════════════════════════════════════════════════════════════════════════
-- END OF MIGRATION
-- ═══════════════════════════════════════════════════════════════════════════
