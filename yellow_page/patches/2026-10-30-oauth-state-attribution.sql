-- OAuth signups leave the browser before the account exists, so the extra
-- campaign fields are parked on the state row. Replay-safe.
ALTER TABLE oauth_state ADD COLUMN IF NOT EXISTS attribution varchar(2048) DEFAULT NULL;
