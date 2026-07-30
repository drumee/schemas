-- =========================================================
-- Add granted_by / granted_at to admin_access_request
-- =========================================================
ALTER TABLE `admin_access_request`
  ADD COLUMN IF NOT EXISTS `granted_by` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL AFTER `dismissed_at`,
  ADD COLUMN IF NOT EXISTS `granted_at` int(11) DEFAULT NULL AFTER `granted_by`;
