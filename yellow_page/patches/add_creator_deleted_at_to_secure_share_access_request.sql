-- The trash button for a pending access request in the share creator's
-- notification panel. Until now it was client-only (no column to record it),
-- so the request came back on every reload until it was approved or denied.
-- Written by secure_share_delete_request, read by secure_share_list_requests.
-- The request itself stays pending: the requester is not told anything and the
-- creator can still answer it from the email link.
ALTER TABLE `secure_share_access_request`
  ADD COLUMN IF NOT EXISTS `creator_deleted_at` int(11) DEFAULT NULL AFTER `responded_at`;
